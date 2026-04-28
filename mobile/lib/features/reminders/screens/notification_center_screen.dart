import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../routes/app_routes.dart';
import '../models/reminder_model.dart';
import '../providers/notification_center_provider.dart';

enum _NotificationInboxTab { recent, missed, cleared }

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  _NotificationInboxTab _tab = _NotificationInboxTab.recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationCenterProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationCenterProvider);
    final items = switch (_tab) {
      _NotificationInboxTab.recent => state.recent,
      _NotificationInboxTab.missed => state.missed,
      _NotificationInboxTab.cleared => state.cleared,
    };
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notificationCenter,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () =>
                ref.read(notificationCenterProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: l10n.clearOld,
            onPressed: state.clearableOld.isEmpty || state.isClearing
                ? null
                : () =>
                      ref.read(notificationCenterProvider.notifier).clearOld(),
            icon: const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      body: state.isLoading && state.reminders.isEmpty
          ? const AppLoadingState(message: 'Loading notifications...')
          : state.error != null && state.reminders.isEmpty
          ? AppErrorState(
              title: 'Notification center could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(notificationCenterProvider.notifier).load(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(notificationCenterProvider.notifier).load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _InboxSummary(state: state),
                  const SizedBox(height: 16),
                  SegmentedButton<_NotificationInboxTab>(
                    segments: [
                      ButtonSegment(
                        value: _NotificationInboxTab.recent,
                        label: Text(l10n.recent),
                        icon: Icon(Icons.notifications_outlined),
                      ),
                      ButtonSegment(
                        value: _NotificationInboxTab.missed,
                        label: Text(l10n.missed),
                        icon: Icon(Icons.notification_important_outlined),
                      ),
                      ButtonSegment(
                        value: _NotificationInboxTab.cleared,
                        label: Text(l10n.cleared),
                        icon: Icon(Icons.done_all_outlined),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        setState(() => _tab = selection.first),
                  ),
                  if (state.isClearing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: AppColors.primary),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    _EmptyInbox(tab: _tab)
                  else
                    ...items.map(
                      (reminder) => _ReminderInboxTile(
                        reminder: reminder,
                        onClear: () => ref
                            .read(notificationCenterProvider.notifier)
                            .clearReminder(reminder.id),
                        onOpenTarget: () => _openTarget(reminder),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _openTarget(ReminderModel reminder) {
    if (reminder.targetType == 'task' && reminder.targetId != null) {
      context.push(
        AppRoutes.taskDetails.replaceFirst(':taskId', reminder.targetId!),
      );
    } else if (reminder.targetType == 'note') {
      context.push(AppRoutes.notes);
    } else if (reminder.targetType == 'habit') {
      context.push(AppRoutes.habits);
    } else if (reminder.targetType == 'prayer' ||
        reminder.targetType == 'ramadan' ||
        reminder.targetType == 'quran_goal') {
      context.push(AppRoutes.prayer);
    }
  }
}

class _InboxSummary extends StatelessWidget {
  final NotificationCenterState state;

  const _InboxSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _SummaryMetric(
            label: l10n.recent,
            value: state.recent.length,
            color: AppColors.primary,
          ),
          _SummaryMetric(
            label: l10n.missed,
            value: state.missed.length,
            color: AppColors.warning,
          ),
          _SummaryMetric(
            label: l10n.cleared,
            value: state.cleared.length,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ReminderInboxTile extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onClear;
  final VoidCallback onOpenTarget;

  const _ReminderInboxTile({
    required this.reminder,
    required this.onClear,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(reminder);
    final cleared = _isCleared(reminder);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_targetIcon(reminder.targetType), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(reminder),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _subtitle(reminder),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(reminder: reminder, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenTarget,
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: Text(l10n.open),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: cleared ? null : onClear,
                  icon: const Icon(Icons.done_all_outlined, size: 18),
                  label: Text(l10n.clear),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReminderModel reminder;
  final Color color;

  const _StatusChip({required this.reminder, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(_statusIcon(reminder), size: 15, color: color),
      label: Text(_statusLabel(reminder)),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  final _NotificationInboxTab tab;

  const _EmptyInbox({required this.tab});

  @override
  Widget build(BuildContext context) {
    final title = switch (tab) {
      _NotificationInboxTab.recent => 'No recent notifications',
      _NotificationInboxTab.missed => 'No missed reminders',
      _NotificationInboxTab.cleared => 'No cleared notifications',
    };
    final message = switch (tab) {
      _NotificationInboxTab.recent =>
        'New task, note, habit, prayer, and focus reminders will appear here.',
      _NotificationInboxTab.missed =>
        'Reminders that pass their scheduled time without being cleared will appear here.',
      _NotificationInboxTab.cleared =>
        'Cleared notifications and dismissed stale reminders will appear here.',
    };
    return AppEmptyState(
      icon: Icons.notifications_none_outlined,
      title: title,
      message: message,
    );
  }
}

bool _isCleared(ReminderModel reminder) {
  return reminder.status == 'cancelled' ||
      reminder.status == 'dismissed' ||
      reminder.cancelledAt != null ||
      reminder.dismissedAt != null;
}

String _title(ReminderModel reminder) {
  final target = _targetLabel(reminder.targetType);
  final kind = reminder.reminderType.replaceAll('_', ' ');
  return '$target reminder - $kind';
}

String _subtitle(ReminderModel reminder) {
  final scheduled = _formatDateTime(reminder.scheduledAt);
  final channel = reminder.channel.replaceAll('_', '-');
  final repeat = reminder.isPersistent ? ' - constant' : '';
  return '$scheduled - $channel - ${reminder.priority}$repeat';
}

String _targetLabel(String targetType) {
  return switch (targetType) {
    'quran_goal' => 'Quran goal',
    'ramadan' => 'Ramadan',
    'ai_suggestion' => 'AI suggestion',
    _ =>
      targetType.isEmpty
          ? 'Reminder'
          : '${targetType[0].toUpperCase()}${targetType.substring(1)}',
  };
}

String _statusLabel(ReminderModel reminder) {
  if (_isCleared(reminder)) return 'Cleared';
  final scheduledAt = DateTime.tryParse(reminder.scheduledAt)?.toLocal();
  if (scheduledAt != null && scheduledAt.isBefore(DateTime.now())) {
    return 'Missed';
  }
  if (reminder.status == 'snoozed') return 'Snoozed';
  return 'Scheduled';
}

IconData _statusIcon(ReminderModel reminder) {
  final label = _statusLabel(reminder);
  return switch (label) {
    'Missed' => Icons.notification_important_outlined,
    'Cleared' => Icons.done_all_outlined,
    'Snoozed' => Icons.snooze_outlined,
    _ => Icons.schedule_outlined,
  };
}

Color _statusColor(ReminderModel reminder) {
  final label = _statusLabel(reminder);
  return switch (label) {
    'Missed' => AppColors.warning,
    'Cleared' => AppColors.success,
    'Snoozed' => AppColors.primary,
    _ => AppColors.primary,
  };
}

IconData _targetIcon(String targetType) {
  return switch (targetType) {
    'task' => Icons.task_alt,
    'note' => Icons.sticky_note_2_outlined,
    'habit' => Icons.track_changes_outlined,
    'prayer' => Icons.mosque_outlined,
    'ramadan' => Icons.nights_stay_outlined,
    'quran_goal' => Icons.menu_book_outlined,
    'focus' => Icons.timer_outlined,
    _ => Icons.notifications_outlined,
  };
}

String _formatDateTime(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return value;
  final date =
      '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  final time =
      '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

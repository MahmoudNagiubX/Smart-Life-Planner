import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.notificationCenter, style: AppTextStyles.h2Light),
            Text(
              'Recent reminders and alerts.',
              style: AppTextStyles.caption(AppColors.textHint),
            ),
          ],
        ),
        actions: [
          _HeaderAction(
            tooltip: l10n.refresh,
            icon: Icons.refresh,
            onPressed: () =>
                ref.read(notificationCenterProvider.notifier).load(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s12),
            child: _HeaderAction(
              tooltip: l10n.clearOld,
              icon: Icons.cleaning_services_outlined,
              onPressed: state.clearableOld.isEmpty || state.isClearing
                  ? null
                  : () => ref
                        .read(notificationCenterProvider.notifier)
                        .clearOld(),
            ),
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
              color: AppColors.brandPrimary,
              onRefresh: () =>
                  ref.read(notificationCenterProvider.notifier).load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.s16,
                  AppSpacing.screenH,
                  138,
                ),
                children: [
                  _InboxSummary(state: state),
                  const SizedBox(height: AppSpacing.s16),
                  _InboxTabs(
                    selected: _tab,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  if (state.isClearing) ...[
                    const SizedBox(height: AppSpacing.s16),
                    ClipRRect(
                      borderRadius: AppRadius.pillBr,
                      child: const LinearProgressIndicator(
                        color: AppColors.brandPrimary,
                        backgroundColor: AppColors.bgSurfaceLavender,
                      ),
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: AppRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.errorColor),
                      ),
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall(AppColors.errorColor),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),
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
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        gradient: AppGradients.ai,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _SummaryMetric(
            label: l10n.recent,
            value: state.recent.length,
            color: AppColors.brandPrimary,
            icon: Icons.notifications_outlined,
          ),
          _SummaryMetric(
            label: l10n.missed,
            value: state.missed.length,
            color: AppColors.warningColor,
            icon: Icons.notification_important_outlined,
          ),
          _SummaryMetric(
            label: l10n.cleared,
            value: state.cleared.length,
            color: AppColors.successColor,
            icon: Icons.done_all_outlined,
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
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: AppIconSize.cardHeader),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('$value', style: AppTextStyles.h3(color)),
          const SizedBox(height: AppSpacing.s2),
          Text(label, style: AppTextStyles.captionLight),
        ],
      ),
    );
  }
}

class _InboxTabs extends StatelessWidget {
  final _NotificationInboxTab selected;
  final ValueChanged<_NotificationInboxTab> onChanged;

  const _InboxTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _InboxTabChip(
            label: l10n.recent,
            icon: Icons.notifications_outlined,
            selected: selected == _NotificationInboxTab.recent,
            onTap: () => onChanged(_NotificationInboxTab.recent),
          ),
          const SizedBox(width: AppSpacing.s8),
          _InboxTabChip(
            label: l10n.missed,
            icon: Icons.notification_important_outlined,
            selected: selected == _NotificationInboxTab.missed,
            onTap: () => onChanged(_NotificationInboxTab.missed),
          ),
          const SizedBox(width: AppSpacing.s8),
          _InboxTabChip(
            label: l10n.cleared,
            icon: Icons.done_all_outlined,
            selected: selected == _NotificationInboxTab.cleared,
            onTap: () => onChanged(_NotificationInboxTab.cleared),
          ),
        ],
      ),
    );
  }
}

class _InboxTabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _InboxTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.pillBr,
      onTap: onTap,
      child: Container(
        height: AppButtonHeight.small,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.action : null,
          color: selected ? null : AppColors.bgSurface,
          borderRadius: AppRadius.pillBr,
          border: Border.all(
            color: selected
                ? AppColors.bgSurfaceLavender
                : AppColors.borderSoft,
          ),
          boxShadow: selected ? AppShadows.glowPurple : AppShadows.soft,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.bgSurface : AppColors.brandPrimary,
            ),
            const SizedBox(width: AppSpacing.s6),
            Text(
              label,
              style: AppTextStyles.label(
                selected ? AppColors.bgSurface : AppColors.textBody,
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: cleared ? AppColors.bgSurfaceSoft : AppColors.bgSurface,
        borderRadius: AppRadius.circular(AppRadius.xl),
        border: Border.all(
          color: cleared ? AppColors.borderSoft : color.withValues(alpha: 0.24),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.avatar,
                height: AppIconSize.avatar,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: cleared ? 0.08 : 0.14),
                  borderRadius: AppRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _targetIcon(reminder.targetType),
                  color: color,
                  size: AppIconSize.cardHeader,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(reminder),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4(AppColors.textHeading),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      _subtitle(reminder),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLight,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              _StatusChip(reminder: reminder, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenTarget,
                  icon: const Icon(Icons.open_in_new_outlined, size: 18),
                  label: Text(l10n.open),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(reminder), size: 14, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(_statusLabel(reminder), style: AppTextStyles.caption(color)),
        ],
      ),
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
      accentColor: AppColors.brandPrimary,
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: AppRadius.circular(AppRadius.md),
        onTap: onPressed,
        child: Container(
          width: AppButtonHeight.icon,
          height: AppButtonHeight.icon,
          margin: const EdgeInsets.only(left: AppSpacing.s6),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: enabled ? AppShadows.soft : null,
          ),
          child: Icon(
            icon,
            color: enabled ? AppColors.brandPrimary : AppColors.textHint,
          ),
        ),
      ),
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
    'Missed' => AppColors.warningColor,
    'Cleared' => AppColors.successColor,
    'Snoozed' => AppColors.brandPrimary,
    _ => AppColors.brandPrimary,
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

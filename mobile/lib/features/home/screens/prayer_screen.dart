import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../prayer/models/prayer_model.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerProvider.notifier).loadTodayPrayers();
    });
  }

  String _prayerDisplayName(String name) {
    const names = {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
    };
    return names[name] ?? name;
  }

  String _prayerEmoji(String name) {
    const emojis = {
      'fajr': '🌙',
      'dhuhr': '☀️',
      'asr': '🌤️',
      'maghrib': '🌅',
      'isha': '🌙',
    };
    return emojis[name] ?? '🕌';
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '--:--';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerProvider);
    final data = state.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🕌 Prayer Times',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading prayer times...')
          : state.error != null
          ? AppErrorState(
              title: 'Prayer times could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(prayerProvider.notifier).loadTodayPrayers(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(prayerProvider.notifier).loadTodayPrayers(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress card
                    if (data != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.prayerGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.prayerGold.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🕌', style: TextStyle(fontSize: 40)),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data.completedCount} / ${data.totalCount} Prayers',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.prayerGold,
                                      ),
                                ),
                                Text(
                                  data.completedCount == 5
                                      ? 'All prayers completed today 🎉'
                                      : 'Keep going, you\'re doing great!',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: data.completedCount / data.totalCount,
                          minHeight: 8,
                          backgroundColor: AppColors.prayerGold.withOpacity(
                            0.2,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.prayerGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Prayer list
                      Text(
                        "Today's Prayers",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      ...data.prayers.map(
                        (prayer) => _PrayerCard(
                          prayer: prayer,
                          displayName: _prayerDisplayName(prayer.prayerName),
                          emoji: _prayerEmoji(prayer.prayerName),
                          formattedTime: _formatTime(prayer.scheduledAt),
                          onToggle: () => ref
                              .read(prayerProvider.notifier)
                              .togglePrayer(
                                prayer.prayerName,
                                prayer.completed,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final PrayerTime prayer;
  final String displayName;
  final String emoji;
  final String formattedTime;
  final VoidCallback onToggle;

  const _PrayerCard({
    required this.prayer,
    required this.displayName,
    required this.emoji,
    required this.formattedTime,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = prayer.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.prayerGold.withOpacity(0.12)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.prayerGold.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.prayerGold : null,
                  ),
                ),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.prayerGold : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.prayerGold
                      : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class SpiritualUpgradesScreen extends StatelessWidget {
  const SpiritualUpgradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spiritual Upgrades',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _UpgradeCard(
            icon: Icons.event_available_outlined,
            title: 'Missed Prayer Tracking',
            description:
                'Track prayer status from Prayer and review history privately.',
            status: 'Available',
          ),
          _UpgradeCard(
            icon: Icons.notifications_active_outlined,
            title: 'Dhikr Reminders',
            description:
                'Create gentle reminder slots for morning, evening, and custom dhikr routines.',
            status: 'Open',
            onTap: () => context.push(AppRoutes.dhikrReminders),
          ),
          const _UpgradeCard(
            icon: Icons.calendar_month_outlined,
            title: 'Fasting Tracker',
            description:
                'Future fasting history for Ramadan, voluntary fasts, and makeup days.',
          ),
          const _UpgradeCard(
            icon: Icons.nights_stay_outlined,
            title: 'Taraweeh Planning',
            description:
                'Future Ramadan planning support for Taraweeh goals and nightly reflection.',
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final VoidCallback? onTap;

  const _UpgradeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.status = 'Planned',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.prayerGold.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.prayerGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.prayerGold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.prayerGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

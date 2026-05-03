import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../routes/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../profile_photo/providers/profile_photo_provider.dart';

const _kNavClearance = 138.0;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _loadedPhotoUserId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final provider = user?['auth_provider'] as String? ?? 'email';
    final isVerified = user?['is_verified'] == true;
    final isActive = user?['is_active'] != false;
    final fullName = user?['full_name'] as String? ?? '';
    final email = user?['email'] as String? ?? '';
    final isSocialProvider = provider == 'google' || provider == 'apple';
    final userId = user?['id'] as String?;
    final photoState = ref.watch(profilePhotoProvider);

    if (userId != null && _loadedPhotoUserId != userId) {
      _loadedPhotoUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(profilePhotoProvider.notifier).loadPhoto(userId);
        }
      });
    }

    Future<void> chooseProfilePhoto() async {
      if (userId == null) return;
      final ok =
          await ref.read(profilePhotoProvider.notifier).pickPhoto(userId);
      if (!context.mounted || !ok) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    }

    Future<void> removeProfilePhoto() async {
      if (userId == null) return;
      final ok =
          await ref.read(profilePhotoProvider.notifier).removePhoto(userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Profile photo removed.'
              : ref.read(profilePhotoProvider).error ??
                  'Could not remove profile photo.'),
        ),
      );
    }

    Future<void> showDeleteDialog() async {
      final controller = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your data will be erased after 30 days.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text(
                'To confirm, ${isSocialProvider ? 'type DELETE.' : 'enter your current password.'}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: isSocialProvider
                      ? 'Type DELETE'
                      : 'Current password',
                  border: OutlineInputBorder(),
                ),
                obscureText: !isSocialProvider,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );

      if (result == true && context.mounted) {
        final input = controller.text.trim();
        if (input.isEmpty) return;

        final success = await ref
            .read(authProvider.notifier)
            .deleteAccount(
              password: isSocialProvider ? null : input,
              confirmation: isSocialProvider ? input : null,
            );

        if (success && context.mounted) {
          context.go(AppRoutes.welcome);
        } else if (context.mounted) {
          final error = ref.read(authProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> showEditNameDialog() async {
      final controller = TextEditingController(text: fullName);
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Display Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Your display name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (result == null) return;
      final cleaned = result.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name cannot be empty.')),
        );
        return;
      }
      final ok = await ref
          .read(authProvider.notifier)
          .updateProfileName(cleaned);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Display name updated.'
                : ref.read(authProvider).error ?? 'Could not update name.',
          ),
          backgroundColor: ok ? AppColors.brandPrimary : AppColors.errorColor,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                56,
                AppSpacing.screenH,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile', style: AppTextStyles.h1Light),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your account and preferences.',
                    style: AppTextStyles.bodySmallLight,
                  ),
                ],
              ),
            ),
          ),

          // Profile hero card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s20,
                AppSpacing.screenH,
                0,
              ),
              child: _ProfileHeroCard(
                fullName: fullName,
                email: email,
                provider: provider,
                isVerified: isVerified,
                isActive: isActive,
                photoPath: photoState.photoPath,
                isPhotoLoading: photoState.isLoading,
                onChangePhoto: userId == null ? null : chooseProfilePhoto,
                onRemovePhoto: photoState.photoPath == null
                    ? null
                    : removeProfilePhoto,
              ),
            ),
          ),

          // Account section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s24,
                AppSpacing.screenH,
                0,
              ),
              child: _SettingsSection(
                label: 'Account',
                rows: [
                  _SettingsRow(
                    icon: Icons.photo_camera_outlined,
                    iconColor: AppColors.brandPink,
                    iconBg: AppColors.bgSurfaceLavender,
                    label: 'Profile Photo',
                    value: photoState.photoPath == null ? 'Add' : 'Change',
                    onTap: userId == null ? () {} : chooseProfilePhoto,
                  ),
                  if (photoState.photoPath != null)
                    _SettingsRow(
                      icon: Icons.delete_outline,
                      iconColor: AppColors.errorColor,
                      iconBg: AppColors.errorSoft,
                      label: 'Remove Photo',
                      onTap: removeProfilePhoto,
                    ),
                  _SettingsRow(
                    icon: Icons.badge_outlined,
                    iconColor: AppColors.brandPrimary,
                    iconBg: AppColors.bgSurfaceLavender,
                    label: 'Display Name',
                    value: fullName.isEmpty ? 'User' : fullName,
                    onTap: showEditNameDialog,
                  ),
                  _SettingsRow(
                    icon: Icons.lock_outlined,
                    iconColor: AppColors.textBody,
                    iconBg: AppColors.bgSurfaceLavender,
                    label: 'Change Password',
                    onTap: () => context.push(AppRoutes.changePassword),
                  ),
                  _SettingsRow(
                    icon: Icons.settings_outlined,
                    iconColor: AppColors.textBody,
                    iconBg: AppColors.bgSurfaceLavender,
                    label: 'App Settings',
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  _SettingsRow(
                    icon: Icons.language,
                    iconColor: AppColors.featJournal,
                    iconBg: AppColors.featJournalSoft,
                    label: 'Language',
                    value: 'English',
                    onTap: () => context.push(AppRoutes.languageSettings),
                  ),
                ],
              ),
            ),
          ),

          // Productivity section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s20,
                AppSpacing.screenH,
                0,
              ),
              child: _SettingsSection(
                label: 'Productivity',
                rows: [
                  _SettingsRow(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.brandPrimary,
                    iconBg: AppColors.featTasksSoft,
                    label: 'AI Daily Plan',
                    onTap: () => context.push(AppRoutes.dailyPlan),
                  ),
                  _SettingsRow(
                    icon: Icons.analytics_outlined,
                    iconColor: AppColors.featAnalytics,
                    iconBg: AppColors.featAnalyticsSoft,
                    label: 'Analytics & Insights',
                    onTap: () => context.push(AppRoutes.analytics),
                  ),
                  _SettingsRow(
                    icon: Icons.task_alt,
                    iconColor: AppColors.featTasks,
                    iconBg: AppColors.featTasksSoft,
                    label: 'My Tasks',
                    onTap: () => context.go(AppRoutes.tasks),
                  ),
                  _SettingsRow(
                    icon: Icons.track_changes_outlined,
                    iconColor: AppColors.featHabits,
                    iconBg: AppColors.featHabitsSoft,
                    label: 'My Habits',
                    onTap: () => context.go(AppRoutes.habits),
                  ),
                  _SettingsRow(
                    icon: Icons.notes_outlined,
                    iconColor: AppColors.featNotes,
                    iconBg: AppColors.featNotesSoft,
                    label: 'My Notes',
                    onTap: () => context.push(AppRoutes.notes),
                  ),
                ],
              ),
            ),
          ),

          // Notifications section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s20,
                AppSpacing.screenH,
                0,
              ),
              child: _SettingsSection(
                label: 'Notifications',
                rows: [
                  _SettingsRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: AppColors.brandPrimary,
                    iconBg: AppColors.featTasksSoft,
                    label: 'Notification Center',
                    onTap: () => context.push(AppRoutes.notificationCenter),
                  ),
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.warningColor,
                    iconBg: AppColors.featNotesSoft,
                    label: 'Notification Settings',
                    onTap: () => context.push(AppRoutes.notificationSettings),
                  ),
                ],
              ),
            ),
          ),

          // Spiritual section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s20,
                AppSpacing.screenH,
                0,
              ),
              child: _SettingsSection(
                label: 'Spiritual',
                rows: [
                  _SettingsRow(
                    icon: Icons.mosque_outlined,
                    iconColor: AppColors.brandViolet,
                    iconBg: AppColors.featPrayerSoft,
                    label: 'Prayer Settings',
                    onTap: () => context.push(AppRoutes.prayerSettings),
                  ),
                  _SettingsRow(
                    icon: Icons.menu_book_outlined,
                    iconColor: AppColors.brandViolet,
                    iconBg: AppColors.bgSurfaceLavender,
                    label: 'Quran Goal',
                    onTap: () => context.push(AppRoutes.quranGoal),
                  ),
                  _SettingsRow(
                    icon: Icons.explore_outlined,
                    iconColor: AppColors.warningColor,
                    iconBg: AppColors.featNotesSoft,
                    label: 'Qibla',
                    onTap: () => context.push(AppRoutes.qibla),
                  ),
                ],
              ),
            ),
          ),

          // Support section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s20,
                AppSpacing.screenH,
                0,
              ),
              child: _SettingsSection(
                label: 'Support',
                rows: [
                  _SettingsRow(
                    icon: Icons.support_agent_outlined,
                    iconColor: AppColors.infoColor,
                    iconBg: AppColors.infoSoft,
                    label: 'Help & Support',
                    onTap: () => context.push(AppRoutes.support),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline,
                    iconColor: AppColors.textBody,
                    iconBg: AppColors.bgSurfaceLavender,
                    label: 'About',
                    onTap: () => context.push(AppRoutes.about),
                  ),
                ],
              ),
            ),
          ),

          // Sign out
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s32,
                AppSpacing.screenH,
                0,
              ),
              child: _OutlineActionButton(
                icon: Icons.logout,
                label: 'Sign Out',
                onTap: () async {
                  final confirmed = await confirmDestructiveAction(
                    context: context,
                    title: 'Sign Out',
                    message: 'Sign out of Smart Life Planner on this device?',
                    confirmLabel: 'Sign Out',
                  );
                  if (!confirmed) return;
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ),
          ),

          // Danger zone
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s20,
                AppSpacing.screenH,
                0,
              ),
              child: _DangerZone(onDeleteAccount: showDeleteDialog),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: _kNavClearance)),
        ],
      ),
    );
  }
}

// ── Provider label helper ─────────────────────────────────────────────────────

String _providerLabel(String provider) {
  return switch (provider) {
    'google' => 'Google',
    'apple' => 'Apple',
    _ => 'Email',
  };
}

// ── Profile Hero Card ─────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String provider;
  final bool isVerified;
  final bool isActive;
  final String? photoPath;
  final bool isPhotoLoading;
  final VoidCallback? onChangePhoto;
  final VoidCallback? onRemovePhoto;

  const _ProfileHeroCard({
    required this.fullName,
    required this.email,
    required this.provider,
    required this.isVerified,
    required this.isActive,
    this.photoPath,
    this.isPhotoLoading = false,
    this.onChangePhoto,
    this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fullName.isNotEmpty ? fullName.trim()[0].toUpperCase() : '';
    final photoFile = photoPath == null ? null : File(photoPath!);
    final hasPhoto = photoFile != null && photoFile.existsSync();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onChangePhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.bgSurfaceLavender,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isPhotoLoading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        )
                      : hasPhoto
                          ? Image.file(
                              photoFile,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _InitialAvatar(initial: initial),
                            )
                          : _InitialAvatar(initial: initial),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: AppGradients.action,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgSurface, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : 'User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h4Light,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLight,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatusBadge(
                      icon: Icons.login_outlined,
                      label: _providerLabel(provider),
                      color: AppColors.brandPrimary,
                    ),
                    _StatusBadge(
                      icon: isVerified
                          ? Icons.verified_outlined
                          : Icons.mark_email_unread_outlined,
                      label: isVerified ? 'Verified' : 'Unverified',
                      color: isVerified
                          ? AppColors.successColor
                          : AppColors.warningColor,
                    ),
                    if (!isActive)
                      _StatusBadge(
                        icon: Icons.block_outlined,
                        label: 'Inactive',
                        color: AppColors.errorColor,
                      ),
                    if (hasPhoto)
                      _StatusBadge(
                        icon: Icons.image_outlined,
                        label: 'Photo set',
                        color: AppColors.brandPink,
                      ),
                  ],
                ),
                if (onRemovePhoto != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  GestureDetector(
                    onTap: onRemovePhoto,
                    child: Text(
                      'Remove photo',
                      style: AppTextStyles.caption(AppColors.errorColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;

  const _InitialAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: initial.isNotEmpty
          ? Text(
              initial,
              style: AppTextStyles.h2(AppColors.brandPrimary),
            )
          : const Icon(
              Icons.person,
              color: AppColors.brandPrimary,
              size: 28,
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Section ──────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String label;
  final List<_SettingsRow> rows;

  const _SettingsSection({required this.label, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.cardBr,
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardBr,
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i < rows.length - 1)
                    Divider(
                      height: 1,
                      color: AppColors.dividerColor,
                      indent: 62,
                      endIndent: 0,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(AppColors.textHeading),
              ),
            ),
            if (value != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(AppColors.textHint),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign Out Button ───────────────────────────────────────────────────────────

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppButtonHeight.primary,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.errorColor.withValues(alpha: 0.4),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.errorColor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.button(AppColors.errorColor)),
          ],
        ),
      ),
    );
  }
}

// ── Danger Zone ───────────────────────────────────────────────────────────────

class _DangerZone extends StatelessWidget {
  final VoidCallback onDeleteAccount;

  const _DangerZone({required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DANGER ZONE',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.errorColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        GestureDetector(
          onTap: onDeleteAccount,
          child: Container(
            height: AppButtonHeight.secondary,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.errorColor.withValues(alpha: 0.4),
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_forever,
                  color: AppColors.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: AppTextStyles.button(AppColors.errorColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

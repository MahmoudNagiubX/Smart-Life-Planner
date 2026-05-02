import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../routes/app_routes.dart';
import '../widgets/auth_gradient_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero card ─────────────────────────────────────────
                  _HeroCard(),
                  const SizedBox(height: AppSpacing.s24),

                  // ── Headline ──────────────────────────────────────────
                  Text(
                    'Organize your life with\ncalm intelligence',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeading,
                      height: 1.22,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // ── Subtitle ──────────────────────────────────────────
                  Text(
                    'Tasks, habits, focus, prayer, notes, and AI planning in one beautiful system.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textBody,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),

                  // ── Feature bullets ───────────────────────────────────
                  _FeatureBullet(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.brandPrimary,
                    label: 'Capture everything quickly',
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _FeatureBullet(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: AppColors.brandPink,
                    label: 'Plan your day with AI support',
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _FeatureBullet(
                    icon: Icons.nightlight_round,
                    iconColor: AppColors.brandViolet,
                    label: 'Balance productivity with spiritual routines',
                  ),
                  const SizedBox(height: AppSpacing.s28),

                  // ── Primary CTA ───────────────────────────────────────
                  AuthGradientButton(
                    label: 'Get Started',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onTap: () => context.go(AppRoutes.signUp),
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // ── Secondary CTA ─────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go(AppRoutes.signIn),
                      child: Text(
                        'I already have an account',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F6FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top-left chip: Tasks
          Positioned(
            top: 30,
            left: 30,
            child: _FeatureChip(
              icon: Icons.task_alt_rounded,
              iconColor: AppColors.brandPrimary,
              label: 'Tasks',
            ),
          ),
          // Top-right chip: Prayer
          Positioned(
            top: 50,
            right: 30,
            child: _FeatureChip(
              icon: Icons.nightlight_round,
              iconColor: AppColors.brandViolet,
              label: 'Prayer',
            ),
          ),
          // Bottom-left chip: Focus
          Positioned(
            bottom: 60,
            left: 40,
            child: _FeatureChip(
              icon: Icons.timer_rounded,
              iconColor: AppColors.brandPink,
              label: 'Focus',
            ),
          ),
          // Bottom-right chip: AI
          Positioned(
            bottom: 40,
            right: 30,
            child: _FeatureChip(
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.brandGold,
              label: 'AI',
            ),
          ),
          // Center logo
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.35),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: AppGradients.action,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature chip (floating in hero card) ─────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _FeatureChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature bullet row ────────────────────────────────────────────────────────

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _FeatureBullet({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bgSurfaceLavender,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
        ),
      ],
    );
  }
}

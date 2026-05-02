import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../routes/app_routes.dart';
import '../utils/auth_error_messages.dart';
import '../widgets/auth_gradient_button.dart';
import '../widgets/auth_text_field.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String initialEmail;

  const VerifyEmailScreen({super.key, this.initialEmail = ''});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyEmail(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified. You can sign in now.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.signIn);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthError(error, 'Could not verify email.')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isResending = true);
    try {
      final message = await ref
          .read(authServiceProvider)
          .resendVerification(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthError(error, 'Could not resend code.')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSubmitting || _isResending;

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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back button ───────────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.signIn),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // ── Logo ──────────────────────────────────────────────
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandPrimary.withValues(alpha: 0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppGradients.action,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),

                    // ── Heading ───────────────────────────────────────────
                    Text(
                      'Verify your email',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'Enter the verification code sent to your inbox.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textBody,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s28),

                    // ── Email field ───────────────────────────────────────
                    AuthTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: !isBusy,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'you@example.com',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required';
                        if (!email.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    // ── Code field ────────────────────────────────────────
                    AuthTextField(
                      label: 'Verification Code',
                      controller: _codeController,
                      enabled: !isBusy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      hintText: '6-digit code',
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => isBusy ? null : _verify(),
                      prefixIcon: const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      validator: (value) {
                        final code = value?.trim() ?? '';
                        if (code.length != 6 || int.tryParse(code) == null) {
                          return 'Enter the 6-digit code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s28),

                    // ── Primary CTA ───────────────────────────────────────
                    AuthGradientButton(
                      label: 'Verify Email',
                      isLoading: _isSubmitting,
                      onTap: isBusy ? null : _verify,
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    // ── Resend code ───────────────────────────────────────
                    GestureDetector(
                      onTap: isBusy ? null : _resend,
                      child: Container(
                        height: AppButtonHeight.secondary,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Center(
                          child: _isResending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.brandPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Resend Code',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isBusy
                                        ? AppColors.textHint
                                        : AppColors.brandPrimary,
                                  ),
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
      ),
    );
  }
}

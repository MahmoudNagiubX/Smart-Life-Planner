import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_animations.dart';
import '../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../widgets/auth_gradient_button.dart';
import '../widgets/auth_social_button.dart';
import '../widgets/auth_text_field.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _canShowAppleSignIn {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      final authState = ref.read(authProvider);
      if (authState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: AppColors.error,
            action: authState.error!.toLowerCase().contains('verify')
                ? SnackBarAction(
                    label: 'Verify',
                    onPressed: () => context.go(
                      Uri(
                        path: AppRoutes.verifyEmail,
                        queryParameters: {
                          'email': _emailController.text.trim(),
                        },
                      ).toString(),
                    ),
                  )
                : null,
          ),
        );
      } else if (authState.status == AuthStatus.authenticated) {
        _goAfterSuccessfulAuth(authState);
      }
      setState(() => _isLoading = false);
    }
  }

  void _goAfterSuccessfulAuth(AuthState authState) {
    final isOnboardingCompleted =
        authState.user?['onboarding_completed'] == true;
    context.go(isOnboardingCompleted ? AppRoutes.home : AppRoutes.onboarding);
  }

  Future<void> _googleLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    final authNotifier = ref.read(authProvider.notifier);
    setState(() => _isLoading = true);
    await authNotifier.googleLogin();
    if (mounted) {
      final err = ref.read(authProvider).error;
      if (err != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      } else {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.authenticated) {
          _goAfterSuccessfulAuth(authState);
        }
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _appleLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    final authNotifier = ref.read(authProvider.notifier);
    setState(() => _isLoading = true);
    await authNotifier.appleSignIn();
    if (mounted) {
      final err = ref.read(authProvider).error;
      if (err != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      } else {
        final authState = ref.read(authProvider);
        if (authState.status == AuthStatus.authenticated) {
          _goAfterSuccessfulAuth(authState);
        }
      }
      setState(() => _isLoading = false);
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back button ───────────────────────────────────────
                    AppPressable(
                      onTap: () => context.go(AppRoutes.welcome),
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
                            color: AppColors.brandPrimary.withValues(
                              alpha: 0.22,
                            ),
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
                          fit: BoxFit.cover,
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
                      'Welcome back',
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
                      'Sign in to continue your journey',
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
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'you@example.com',
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    // ── Password field ────────────────────────────────────
                    AuthTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      hintText: '••••••••',
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),

                    // ── Forgot password ───────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => context.go(AppRoutes.forgotPassword),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),

                    // ── Primary CTA ───────────────────────────────────────
                    AuthGradientButton(
                      label: 'Sign In',
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    // ── Divider ───────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppColors.borderSoft,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.borderSoft,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    // ── Social buttons ────────────────────────────────────
                    if (_canShowAppleSignIn)
                      Column(
                        children: [
                          AuthSocialButton(
                            icon: const GoogleGMark(),
                            label: 'Continue with Google',
                            isLoading: _isLoading,
                            onTap: _isLoading ? null : _googleLogin,
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          AuthSocialButton(
                            icon: const Icon(
                              Icons.apple_rounded,
                              size: 20,
                              color: AppColors.textHeading,
                            ),
                            label: 'Continue with Apple',
                            isLoading: _isLoading,
                            onTap: _isLoading ? null : _appleLogin,
                          ),
                        ],
                      )
                    else
                      AuthSocialButton(
                        icon: const GoogleGMark(),
                        label: 'Continue with Google',
                        isLoading: _isLoading,
                        onTap: _isLoading ? null : _googleLogin,
                      ),

                    const SizedBox(height: AppSpacing.s28),

                    // ── Footer link ───────────────────────────────────────
                    Center(
                      child: AppPressable(
                        onTap: () => context.go(AppRoutes.signUp),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textBody,
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign up',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ],
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

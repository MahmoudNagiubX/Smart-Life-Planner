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

enum _ResetStep { requestCode, verifyCode, setPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _ResetStep _step = _ResetStep.requestCode;
  String? _resetToken;
  String? _developmentCode;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

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
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      switch (_step) {
        case _ResetStep.requestCode:
          final message = await ref
              .read(authServiceProvider)
              .forgotPassword(email: _emailController.text.trim());
          if (!mounted) return;
          final code = _extractDevelopmentCode(message);
          setState(() {
            _step = _ResetStep.verifyCode;
            _developmentCode = code;
            if (code != null) _codeController.text = code;
          });
          _showSuccess(message);
          break;
        case _ResetStep.verifyCode:
          final token = await ref
              .read(authServiceProvider)
              .verifyResetCode(
                email: _emailController.text.trim(),
                code: _codeController.text.trim(),
              );
          if (!mounted) return;
          setState(() {
            _resetToken = token;
            _step = _ResetStep.setPassword;
          });
          _showSuccess('Code verified. Set your new password.');
          break;
        case _ResetStep.setPassword:
          final token = _resetToken;
          if (token == null) return;
          await ref
              .read(authServiceProvider)
              .setNewPassword(
                resetToken: token,
                newPassword: _passwordController.text,
              );
          if (!mounted) return;
          _showSuccess('Password updated. You can sign in now.');
          context.go(AppRoutes.signIn);
          break;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthError(error, 'Password reset failed.')),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.successColor),
    );
  }

  String? _extractDevelopmentCode(String message) {
    final match = RegExp(r'Code:\s*(\d{6})').firstMatch(message);
    return match?.group(1);
  }

  String get _buttonText {
    switch (_step) {
      case _ResetStep.requestCode:
        return 'Send Reset Code';
      case _ResetStep.verifyCode:
        return 'Verify Code';
      case _ResetStep.setPassword:
        return 'Set New Password';
    }
  }

  String get _heading {
    switch (_step) {
      case _ResetStep.requestCode:
        return 'Reset your password';
      case _ResetStep.verifyCode:
        return 'Check your email';
      case _ResetStep.setPassword:
        return 'Set new password';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _ResetStep.requestCode:
        return "Enter your email and we'll send you a recovery code.";
      case _ResetStep.verifyCode:
        return 'Enter the 6-digit reset code sent to your inbox.';
      case _ResetStep.setPassword:
        return 'Choose a strong password for your account.';
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

                    // ── Step indicator dots ───────────────────────────────
                    Row(
                      children: List.generate(3, (i) {
                        final active = i <= _step.index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.brandPrimary
                                  : AppColors.borderSoft,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    // ── Heading ───────────────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Align(
                        key: ValueKey(_step),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _heading,
                          style: GoogleFonts.manrope(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeading,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Align(
                        key: ValueKey('sub_${_step.index}'),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _subtitle,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBody,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s28),

                    // ── Email field (always visible, locked after step 0) ─
                    if (_developmentCode != null &&
                        _step != _ResetStep.requestCode) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.warningColor),
                        ),
                        child: Text(
                          'Development reset code: $_developmentCode',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warningColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                    ],
                    AuthTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: !_isLoading && _step == _ResetStep.requestCode,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'you@example.com',
                      textInputAction: _step == _ResetStep.requestCode
                          ? TextInputAction.done
                          : TextInputAction.next,
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

                    // ── Code field (step 1+) ──────────────────────────────
                    if (_step != _ResetStep.requestCode) ...[
                      const SizedBox(height: AppSpacing.s16),
                      AuthTextField(
                        label: 'Reset Code',
                        controller: _codeController,
                        enabled: !_isLoading && _step == _ResetStep.verifyCode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        hintText: '6-digit code',
                        textInputAction: _step == _ResetStep.verifyCode
                            ? TextInputAction.done
                            : TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.pin_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        validator: (value) {
                          if (_step == _ResetStep.requestCode) return null;
                          final code = value?.trim() ?? '';
                          if (code.length != 6 || int.tryParse(code) == null) {
                            return 'Enter the 6-digit code';
                          }
                          return null;
                        },
                      ),
                    ],

                    // ── New password fields (step 2) ──────────────────────
                    if (_step == _ResetStep.setPassword) ...[
                      const SizedBox(height: AppSpacing.s16),
                      AuthTextField(
                        label: 'New Password',
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        hintText: '••••••••',
                        textInputAction: TextInputAction.next,
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
                        validator: (value) {
                          if (_step != _ResetStep.setPassword) return null;
                          if ((value ?? '').length < 8) {
                            return 'Minimum 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      AuthTextField(
                        label: 'Confirm New Password',
                        controller: _confirmPasswordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        hintText: '••••••••',
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                        prefixIcon: const Icon(
                          Icons.lock_reset_outlined,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                        validator: (value) {
                          if (_step != _ResetStep.setPassword) return null;
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: AppSpacing.s28),

                    // ── Primary CTA ───────────────────────────────────────
                    AuthGradientButton(
                      label: _buttonText,
                      isLoading: _isLoading,
                      onTap: _isLoading ? null : _submit,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../utils/auth_error_messages.dart';

enum _ResetStep { requestCode, verifyCode, setPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _ResetStep _step = _ResetStep.requestCode;
  String? _resetToken;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
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
          await ref
              .read(authServiceProvider)
              .forgotPassword(email: _emailController.text.trim());
          if (!mounted) return;
          setState(() => _step = _ResetStep.verifyCode);
          _showSuccess('If that email exists, a reset code was sent.');
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
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Reset your password with the code sent to your email.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading && _step == _ResetStep.requestCode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Email is required';
                    if (!email.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                if (_step != _ResetStep.requestCode) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    enabled: !_isLoading && _step == _ResetStep.verifyCode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Reset Code',
                      prefixIcon: Icon(Icons.pin_outlined),
                      counterText: '',
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
                if (_step == _ResetStep.setPassword) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (_step != _ResetStep.setPassword) return null;
                      final password = value ?? '';
                      if (password.length < 8) {
                        return 'Minimum 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
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
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_buttonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

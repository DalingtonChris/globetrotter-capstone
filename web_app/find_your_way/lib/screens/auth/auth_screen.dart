import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/api_client.dart';
import '../../state/auth_controller.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';

enum _AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isLogin => _mode == _AuthMode.login;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();

    try {
      if (_isLogin) {
        await auth.login(email: _emailController.text.trim(), password: _passwordController.text);
      } else {
        await auth.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.explore_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Find Your Way',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? 'Welcome back, ready for your next trip?' : 'Create an account to start planning',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    _ModeToggle(mode: _mode, onChanged: _switchMode),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLogin) ...[
                            AppTextField(
                              key: const ValueKey('auth-field-name'),
                              label: 'Full name',
                              hint: 'dalington',
                              icon: Icons.person_outline_rounded,
                              controller: _nameController,
                              autofillHints: const [AutofillHints.name],
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          AppTextField(
                            key: const ValueKey('auth-field-email'),
                            label: 'Email',
                            hint: 'you@example.com',
                            icon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter your email';
                              final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
                              return valid ? null : 'Enter a valid email address';
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            key: const ValueKey('auth-field-password'),
                            label: 'Password',
                            hint: 'At least 6 characters',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscure: true,
                            autofillHints: [_isLogin ? AutofillHints.password : AutofillHints.newPassword],
                            validator: (v) =>
                                (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              key: const ValueKey('auth-field-confirm-password'),
                              label: 'Confirm password',
                              hint: 'Re-enter your password',
                              icon: Icons.lock_outline_rounded,
                              controller: _confirmPasswordController,
                              obscure: true,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please confirm your password';
                                return v == _passwordController.text ? null : 'Passwords do not match';
                              },
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            ErrorBanner(message: _errorMessage!),
                          ],
                          const SizedBox(height: 22),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                  )
                                : Text(_isLogin ? 'Log in' : 'Create account'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'Log in',
            selected: mode == _AuthMode.login,
            onTap: () => onChanged(_AuthMode.login),
          ),
          _ToggleButton(
            label: 'Sign up',
            selected: mode == _AuthMode.signup,
            onTap: () => onChanged(_AuthMode.signup),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

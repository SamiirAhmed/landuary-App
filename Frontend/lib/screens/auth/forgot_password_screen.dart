import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _resetToken;
  Map<String, dynamic>? _verifiedUser;

  bool get _isVerified => _resetToken != null;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_loginController.text.trim().isEmpty) {
      _showError('Phone or email is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response =
          await context.read<AppState>().apiService.verifyForgotPassword(
                _loginController.text.trim(),
              );

      if (!mounted) return;
      setState(() {
        _resetToken = response['reset_token'] as String?;
        _verifiedUser = response['user'] as Map<String, dynamic>?;
      });
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('New password and confirm password are required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AppState>().apiService.resetForgotPassword(
            resetToken: _resetToken!,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password reset successfully. Please login.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _resetToken = null;
      _verifiedUser = null;
      _loginController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1554B7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1554B7),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reset Password'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: FormCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            _isVerified ? Icons.lock_reset : Icons.lock_clock_outlined,
                            color: const Color(0xFF1554B7),
                            size: 68,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _isVerified ? 'Create New Password' : 'Verify Your Identity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF1554B7),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isVerified
                                ? 'Resetting password for ${_verifiedUser?['full_name'] ?? 'your account'}.'
                                : 'Enter the phone or email tied to your account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                          ),
                          const SizedBox(height: 28),
                          if (!_isVerified) ...[
                            CustomTextField(
                              controller: _loginController,
                              label: 'Phone or email',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 22),
                            CustomButton(
                              label: 'Verify',
                              icon: Icons.verified_user_outlined,
                              isLoading: _isLoading,
                              onPressed: _verify,
                            ),
                          ] else ...[
                            CustomTextField(
                              controller: _passwordController,
                              label: 'New Password',
                              icon: Icons.lock_outline,
                              obscureText: _hidePassword,
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _hidePassword = !_hidePassword),
                                icon: Icon(_hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              icon: Icons.lock_reset,
                              obscureText: _hideConfirmPassword,
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _hideConfirmPassword = !_hideConfirmPassword),
                                icon: Icon(_hideConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            const SizedBox(height: 22),
                            CustomButton(
                              label: 'Reset Password',
                              icon: Icons.done,
                              isLoading: _isLoading,
                              onPressed: _resetPassword,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

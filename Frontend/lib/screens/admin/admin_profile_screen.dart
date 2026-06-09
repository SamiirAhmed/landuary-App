import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _isPasswordLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      await context.read<AppState>().loadSession();
    }
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New password and confirm password are required',
          ),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('New password and confirm password do not match')),
      );
      return;
    }

    setState(() => _isPasswordLoading = true);

    try {
      final appState = context.read<AppState>();
      await appState.apiService.changePassword(
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user ?? {};
    final fullName = user['full_name']?.toString() ?? 'Admin';
    final role = user['role']?.toString() ?? 'Admin';
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone']?.toString() ?? '-';
    final initial = fullName.trim().isEmpty ? 'A' : fullName[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          children: [
            Center(
              child: CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xFF1554B7),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Row with person icon and first name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.badge_outlined, color: Color(0xFF1554B7)),
                const SizedBox(width: 8),
                Text(
                  fullName.split(' ')[0], // First name
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1554B7)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Info Section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: fullName),
                    const Divider(),
                    _InfoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Role',
                        value: role),
                    const Divider(),
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email),
                    const Divider(),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Change Password Section
            FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormSectionTitle(title: 'Change Password'),
                  const SizedBox(height: 16),

                  // New Password
                  CustomTextField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    icon: Icons.lock_reset_outlined,
                    obscureText: _hideNewPassword,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hideNewPassword = !_hideNewPassword),
                      icon: Icon(
                        _hideNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm New Password
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    icon: Icons.lock_clock_outlined,
                    obscureText: _hideConfirmPassword,
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _hideConfirmPassword = !_hideConfirmPassword,
                      ),
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    label: 'Update Password',
                    icon: Icons.save_outlined,
                    isLoading: _isPasswordLoading,
                    onPressed: _changePassword,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1554B7), size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';
import '../../widgets/sex_radio_group.dart';
import '../../widgets/success_dialog.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({super.key});

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();
  String? _sex;
  bool _sexError = false;
  String _role = 'Staff';
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _staff = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final Future<List<Map<String, dynamic>>> apiCall =
        context.read<AppState>().apiService.getStaffList();
    
    // Ensure minimum delay so RefreshIndicator doesn't get stuck
    final results = await Future.wait([
      apiCall,
      Future.delayed(const Duration(milliseconds: 600)),
    ]);
    
    if (!mounted) return;
    setState(() {
      _staff = results[0] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  Future<void> _registerStaff() async {
    // Trigger form validation
    final formValid = _formKey.currentState?.validate() ?? false;

    // Check sex separately
    if (_sex == null) {
      setState(() => _sexError = true);
    } else {
      setState(() => _sexError = false);
    }

    if (!formValid || _sex == null) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final selectedSex = _sex!;

    try {
      await context.read<AppState>().apiService.registerStaff({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'sex': selectedSex,
        'email': _emailController.text.trim(),
        'has_login': true,
        'password': password,
        'confirm_password': confirmPassword,
        'role': _role,
        'position': _positionController.text.trim(),
        'salary': double.tryParse(_salaryController.text.trim()) ?? 0,
        'hire_date': DateTime.now().toIso8601String().substring(0, 10),
      });
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _positionController.clear();
      _salaryController.clear();
      setState(() {
        _sex = null;
        _sexError = false;
      });
      if (mounted) {
        await showSuccessDialog(
          context,
          title: 'Staff Registered!',
          message: 'The staff member has been successfully registered and is now active in the system.',
          buttonText: 'Great!',
          onDone: _loadStaff,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _setStatus(Map<String, dynamic> staff, String status) async {
    await context.read<AppState>().apiService.updateStaffStatus({
      'staff_id': staff['staff_id'],
      'status': status,
    });
    _loadStaff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manage Staff',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadStaff,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStaff,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  FormCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const FormSectionTitle(title: 'Register Staff'),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Full name is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Phone number is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          // Sex with red error
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SexRadioGroup(
                                value: _sex,
                                onChanged: (value) => setState(() {
                                  _sex = value;
                                  _sexError = false;
                                }),
                              ),
                              if (_sexError)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 14, color: Color(0xFFE53935)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Please select a gender',
                                        style: const TextStyle(
                                          color: Color(0xFFE53935),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _role,
                            items: ['Staff', 'Delivery']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _role = value ?? 'Staff'),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _positionController,
                            label: 'Position',
                            icon: Icons.work_outline,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Position is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _salaryController,
                            label: 'Salary',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Salary is required';
                              if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _hidePassword,
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _hidePassword = !_hidePassword),
                              icon: Icon(_hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
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
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm your password';
                              if (v != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            label: 'Register Staff',
                            icon: Icons.person_add_alt,
                            onPressed: _registerStaff,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._staff.map(
                    (staff) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE8EFFE),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E68D9).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  (staff['full_name']?.toString() ?? '?')
                                      .split(' ')
                                      .where((w) => w.isNotEmpty)
                                      .take(2)
                                      .map((w) => w[0].toUpperCase())
                                      .join(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff['full_name']?.toString() ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _StaffChip(
                                        label: staff['role']?.toString() ?? '-',
                                        color: const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 6),
                                      _StaffChip(
                                        label: staff['status']?.toString() ?? '-',
                                        color: staff['status'] == 'Active'
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${staff['position'] ?? '-'} · ${staff['sex'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Menu
                            PopupMenuButton<String>(
                              onSelected: (status) => _setStatus(staff, status),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'Active', child: Text('Activate')),
                                PopupMenuItem(value: 'Inactive', child: Text('Inactivate')),
                              ],
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFF3B82F6),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StaffChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

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

  Future<void> _deleteStaff(Map<String, dynamic> staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Staff', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to delete "${staff['full_name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await context.read<AppState>().apiService.deleteStaff(
              int.parse(staff['staff_id'].toString()),
            );
        _loadStaff();
        if (mounted) {
          showSuccessDialog(
            context,
            title: 'Staff Deleted',
            message: 'Staff deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          showErrorDialog(
            context,
            title: 'Error',
            message: e.toString(),
          );
        }
      }
    }
  }

  void _showEditStaff(Map<String, dynamic> staff) {
    final nameCtrl    = TextEditingController(text: staff['full_name']?.toString() ?? '');
    final phoneCtrl   = TextEditingController(text: staff['phone']?.toString() ?? '');
    final emailCtrl   = TextEditingController(text: staff['email']?.toString() ?? '');
    final posCtrl     = TextEditingController(text: staff['position']?.toString() ?? '');
    final salaryCtrl  = TextEditingController(text: staff['salary']?.toString() ?? '');
    String sex        = staff['sex']?.toString() ?? 'Male';
    String role       = staff['role']?.toString() ?? 'Staff';
    final List<String> availableRoles = ['Staff', 'Delivery'];
    if (!availableRoles.contains(role)) {
      availableRoles.add(role);
    }
    final formKey     = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit Staff',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Name must be at least 2 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: phoneCtrl,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SexRadioGroup(
                      value: sex,
                      onChanged: (v) => setModalState(() => sex = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setModalState(() => role = v ?? role),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: posCtrl,
                      label: 'Position',
                      icon: Icons.work_outline,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: salaryCtrl,
                      label: 'Salary',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        try {
                          await context.read<AppState>().apiService.updateStaff({
                            'staff_id': staff['staff_id'],
                            'full_name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'sex': sex,
                            'role': role,
                            'position': posCtrl.text.trim(),
                            'salary': double.tryParse(salaryCtrl.text.trim()) ?? 0,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadStaff();
                          if (mounted) {
                            showSuccessDialog(
                              context,
                              title: 'Staff Updated',
                              message: 'Staff updated successfully',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            showErrorDialog(
                              context,
                              title: 'Error',
                              message: e.toString(),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStaffDetails(BuildContext context, Map<String, dynamic> staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
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
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff['full_name']?.toString() ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StaffChip(
                              label: staff['role']?.toString() ?? '-',
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 8),
                            _StaffChip(
                              label: staff['status']?.toString() ?? '-',
                              color: staff['status'] == 'Active'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Staff Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(icon: Icons.work_outline, label: 'Position', value: staff['position']?.toString() ?? '-'),
              _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: staff['phone']?.toString() ?? '-'),
              _DetailRow(icon: Icons.email_outlined, label: 'Email', value: staff['email']?.toString() ?? '-'),
              _DetailRow(icon: Icons.person_outline, label: 'Sex', value: staff['sex']?.toString() ?? '-'),
              _DetailRow(icon: Icons.attach_money, label: 'Salary', value: '\$${staff['salary']?.toString() ?? '0'}'),
              _DetailRow(icon: Icons.calendar_today_outlined, label: 'Hire Date', value: staff['hire_date']?.toString().split('T')[0] ?? '-'),
              const SizedBox(height: 16),
              // Edit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  label: const Text(
                    'Edit Staff Info',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditStaff(staff);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
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
                            initialValue: _role,
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
                    (staff) => GestureDetector(
                      onTap: () => _showStaffDetails(context, staff),
                      child: Container(
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'Active', child: Text('Activate')),
                                PopupMenuItem(value: 'Inactive', child: Text('Inactivate')),
                                PopupMenuItem(
                                  value: 'Delete',
                                  child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'Delete') {
                                  _deleteStaff(staff);
                                } else {
                                  _setStatus(staff, value);
                                }
                              },
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/city_model.dart';
import '../../models/district_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';
import '../../widgets/service_dropdown.dart';
import '../../widgets/sex_radio_group.dart';
import '../../widgets/success_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  String? _sex;
  bool _sexError = false;
  bool _cityError = false;
  bool _districtError = false;
  List<CityModel> _cities = [];
  List<DistrictModel> _districts = [];
  CityModel? _selectedCity;
  DistrictModel? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final Future<List<CityModel>> apiCall = 
          context.read<AppState>().apiService.getCities();
          
      // Ensure minimum delay so RefreshIndicator doesn't get stuck
      final results = await Future.wait([
        apiCall,
        Future.delayed(const Duration(milliseconds: 600)),
      ]);
      
      if (!mounted) return;
      setState(() => _cities = results[0] as List<CityModel>);
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _loadDistricts(CityModel city) async {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _districts = [];
      _cityError = false;
    });

    try {
      final districts =
          await context.read<AppState>().apiService.getDistricts(city.cityId);
      if (!mounted) return;
      setState(() => _districts = districts);
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _register() async {
    // Trigger form validation
    final formValid = _formKey.currentState?.validate() ?? false;

    // Check optional fields manually
    setState(() {
      _sexError = _sex == null;
      _cityError = _selectedCity == null;
      _districtError = _selectedDistrict == null;
    });

    if (!formValid || _sex == null || _selectedCity == null || _selectedDistrict == null) {
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final selectedSex = _sex!;

    setState(() => _isLoading = true);

    try {
      await context.read<AppState>().apiService.registerCustomer({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'sex': selectedSex,
        'email': _emailController.text.trim(),
        'city_id': _selectedCity!.cityId,
        'district_id': _selectedDistrict!.districtId,
        'password': password,
        'confirm_password': confirmPassword,
      });

      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'Account Created!',
        message: 'Your account has been successfully created. You can now log in and start using our laundry services.',
        buttonText: 'Go to Login',
        onDone: () {
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
      );
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

  Widget _errorText(String msg) => Padding(
        padding: const EdgeInsets.only(left: 12, top: 4),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 14, color: Color(0xFFE53935)),
            const SizedBox(width: 4),
            Text(
              msg,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Customer Registration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadCities,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E68D9), Color(0xFF09378B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return RefreshIndicator(
                onRefresh: _loadCities,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 26 * 2,
                    ),
                    child: Center(
                      child: FormCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1554B7).withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: Color(0xFF1554B7),
                                    size: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF1554B7),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign up to order high quality laundry services',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 28),
                              const FormSectionTitle(title: 'Personal Details'),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Full name is required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _phoneController,
                                label: 'Phone',
                                icon: Icons.phone_outlined,
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Phone number is required'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              // Sex with error
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
                                  if (_sexError) _errorText('Please select a gender'),
                                ],
                              ),
                              const SizedBox(height: 14),
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
                              const SizedBox(height: 28),
                              const FormSectionTitle(title: 'Address Details'),
                              const SizedBox(height: 20),
                              // City with error
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ServiceDropdown<CityModel>(
                                    label: 'City',
                                    value: _selectedCity,
                                    items: _cities,
                                    itemLabel: (city) => city.cityName,
                                    onChanged: (city) {
                                      if (city != null) _loadDistricts(city);
                                    },
                                  ),
                                  if (_cityError) _errorText('Please select a city'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // District with error
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ServiceDropdown<DistrictModel>(
                                    label: 'District',
                                    value: _selectedDistrict,
                                    items: _districts,
                                    itemLabel: (district) => district.districtName,
                                    onChanged: (district) => setState(() {
                                      _selectedDistrict = district;
                                      _districtError = false;
                                    }),
                                  ),
                                  if (_districtError) _errorText('Please select a district'),
                                ],
                              ),
                              const SizedBox(height: 28),
                              const FormSectionTitle(title: 'Security Details'),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _hidePassword,
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(
                                    _hidePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 6) return 'At least 6 characters required';
                                  return null;
                                },
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
                                  icon: Icon(
                                    _hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please confirm your password';
                                  if (v != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              CustomButton(
                                label: 'Submit Registration',
                                icon: Icons.person_add_alt,
                                isLoading: _isLoading,
                                onPressed: _register,
                              ),
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
        ),
      ),
    );
  }
}

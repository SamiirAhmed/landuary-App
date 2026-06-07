import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../core/storage/token_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = TokenStorage();
  final _picker = ImagePicker();
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final path = await _storage.getProfileImagePath();
    if (!mounted) return;
    setState(() => _profileImagePath = path);
  }

  Future<void> _handleRefresh() async {
    await _loadProfileImage();
    if (mounted) {
      await context.read<AppState>().loadSession();
    }
  }

  Future<void> _pickProfileImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image == null) return;

    await _storage.saveProfileImagePath(image.path);
    if (!mounted) return;
    setState(() => _profileImagePath = image.path);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFF1554B7),
                      backgroundImage: _profileImagePath == null
                          ? null
                          : FileImage(File(_profileImagePath!)),
                      child: _profileImagePath == null
                          ? const Icon(Icons.person,
                              size: 56, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1554B7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap photo to upload',
                style: TextStyle(
                    color: Color(0xFF1554B7), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'Full name',
                value: user['full_name']),
            _ProfileTile(
                icon: Icons.wc_outlined, label: 'Sex', value: user['sex']),
            _ProfileTile(
                icon: Icons.phone_outlined, label: 'Phone', value: user['phone']),
            _ProfileTile(
                icon: Icons.email_outlined, label: 'Email', value: user['email']),
            _ProfileTile(
              icon: Icons.location_city_outlined,
              label: 'City',
              value: user['city_name'] ?? user['city'] ?? user['city_id'],
            ),
            _ProfileTile(
              icon: Icons.map_outlined,
              label: 'District',
              value: user['district_name'] ??
                  user['district'] ??
                  user['district_id'],
            ),
            _ProfileTile(
                icon: Icons.verified_user_outlined,
                label: 'Role',
                value: user['role']),
            _ProfileTile(
              icon: Icons.confirmation_number_outlined,
              label: user['role'] == 'Staff' || user['role'] == 'Delivery'
                  ? 'Staff ID'
                  : 'Customer ID',
              value: user['staff_id'] ?? user['customer_id'] ?? user['user_id'],
            ),
            if (user['position'] != null)
              _ProfileTile(
                icon: Icons.work_outline,
                label: 'Position',
                value: user['position'],
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Object? value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1554B7).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF1554B7)),
        ),
        title: Text(label),
        subtitle: Text(
          value?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

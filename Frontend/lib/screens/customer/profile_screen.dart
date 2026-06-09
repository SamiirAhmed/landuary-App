import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _handleRefresh() async {
    if (mounted) {
      await context.read<AppState>().loadSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user ?? {};
    final name = user['full_name']?.toString().trim();
    final fallbackName = user['role']?.toString() ?? 'User';
    final avatarSource = (name == null || name.isEmpty) ? fallbackName : name;
    final initial = avatarSource.isEmpty ? 'U' : avatarSource[0].toUpperCase();

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
            const SizedBox(height: 20),
            _ProfileTile(
                icon: Icons.badge_outlined,
                label: 'Full name',
                value: user['full_name']),
            _ProfileTile(
                icon: Icons.wc_outlined, label: 'Sex', value: user['sex']),
            _ProfileTile(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user['phone']),
            _ProfileTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user['email']),
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

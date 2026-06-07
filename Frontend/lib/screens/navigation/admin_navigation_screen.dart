import 'package:flutter/material.dart';

import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_profile_screen.dart';
import '../admin/manage_services_screen.dart';
import '../admin/manage_staff_screen.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _currentIndex = 0;

  Widget _screenForIndex() {
    return switch (_currentIndex) {
      1 => const ManageStaffScreen(),
      2 => const AdminDashboardScreen(),
      3 => const ManageServicesScreen(),
      4 => const AdminProfileScreen(),
      _ => const AdminDashboardScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screenForIndex(),
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _AdminBottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            selected: currentIndex == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            label: 'Staff',
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            selected: currentIndex == 1,
            onTap: () => onChanged(1),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => onChanged(2),
                child: const _BrandNavIcon(),
              ),
            ),
          ),
          _NavItem(
            label: 'Services',
            icon: Icons.local_laundry_service_outlined,
            activeIcon: Icons.local_laundry_service_rounded,
            selected: currentIndex == 3,
            onTap: () => onChanged(3),
          ),
          _NavItem(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            selected: currentIndex == 4,
            onTap: () => onChanged(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF35315F) : const Color(0xFF676D76);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF0F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandNavIcon extends StatelessWidget {
  const _BrandNavIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1F71F2), Color(0xFF0042B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0042B8).withValues(alpha: 0.34),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.add_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}

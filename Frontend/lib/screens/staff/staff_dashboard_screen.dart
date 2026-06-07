import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboard = {};
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent) {
      if (mounted) setState(() => _isLoading = true);
    }
    try {
      final apiService = context.read<AppState>().apiService;
      final Future<Map<String, dynamic>> dashCall = apiService.getStaffDashboard();
      final Future<List<Map<String, dynamic>>> ordersCall = apiService.getStaffOrders();
      
      final results = await Future.wait([
        dashCall,
        ordersCall,
        if (silent) Future.delayed(const Duration(milliseconds: 600)),
      ]);
      
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _orders = results[1] as List<Map<String, dynamic>>;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AppState>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  int _statusCount(String status) {
    return _orders.where((order) {
      return order['order_status']?.toString().toLowerCase() ==
          status.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user ?? {};
    final handledOrders = _dashboard['handled_orders'] ??
        _dashboard['total_orders'] ??
        _dashboard['assigned_orders'] ??
        _orders.length;

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
          'Staff Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
              onPressed: () => _loadDashboard(silent: true),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 12, left: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF0F4FF), Color(0xFFE8EFFE)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: RefreshIndicator(
                color: const Color(0xFF3B82F6),
                onRefresh: () => _loadDashboard(silent: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E40AF).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFE8EFFE),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
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
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['full_name']?.toString() ?? 'Staff Member',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          user['role'],
                                          user['position'],
                                          user['phone'],
                                        ]
                                            .where((value) => value != null && value.toString().isNotEmpty)
                                            .map((value) => value.toString())
                                            .join(' • '),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF3B82F6),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Grid Cards
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      children: [
                        _DashboardCard(
                          title: 'Handled',
                          value: handledOrders,
                          colors: const [Color(0xFF287DFF), Color(0xFF0052D9)],
                        ),
                        _DashboardCard(
                          title: 'New',
                          value: _dashboard['new_orders'],
                          colors: const [Color(0xFF18CECF), Color(0xFF04AAB7)],
                        ),
                        _DashboardCard(
                          title: 'Accepted',
                          value: _dashboard['accepted_orders'],
                          colors: const [Color(0xFF8064FF), Color(0xFF5B3CE8)],
                        ),
                        _DashboardCard(
                          title: 'Washing',
                          value: _dashboard['washing_orders'],
                          colors: const [Color(0xFF29C875), Color(0xFF05A65B)],
                        ),
                        _DashboardCard(
                          title: 'Ironing',
                          value: _dashboard['ironing_orders'],
                          colors: const [Color(0xFFFF9F00), Color(0xFFFF7900)],
                        ),
                        _DashboardCard(
                          title: 'Ready',
                          value: _dashboard['ready_orders'],
                          colors: const [Color(0xFFA149FF), Color(0xFF7437EA)],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Action Cards (Replaces old buttons)
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'View All\nOrders',
                            icon: Icons.list_alt_rounded,
                            gradient: const [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                            onTap: () => Navigator.pushNamed(context, AppRoutes.staffOrders),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            title: 'Customer\nBalance',
                            icon: Icons.account_balance_wallet_rounded,
                            gradient: const [Color(0xFF8064FF), Color(0xFF5B3CE8)],
                            onTap: () => Navigator.pushNamed(context, AppRoutes.customerBalance),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Object? value;
  final List<Color> colors;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: colors.first.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${value ?? 0}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(const Rect.fromLTWH(0, 0, 50, 30)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../routes/app_routes.dart';
import 'expenses_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  Map<String, dynamic> _dashboard = {};

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
      final Future<Map<String, dynamic>> apiCall =
          context.read<AppState>().apiService.getAdminDashboard();

      // Ensure minimum delay so RefreshIndicator doesn't get stuck (Flutter bug)
      final results = await Future.wait([
        apiCall,
        if (silent) Future.delayed(const Duration(milliseconds: 600)),
      ]);

      if (!mounted) return;
      setState(() => _dashboard = results[0] as Map<String, dynamic>);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to connect to the server. Please try again.'),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F8FF),
      drawer: _AdminDrawer(onLogout: _logout, onReload: _loadDashboard),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _DashboardHeader(
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onRefresh: () => _loadDashboard(silent: true),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 18.0;
                      final dashboardWidth = constraints.maxWidth > 430
                          ? 430.0
                          : constraints.maxWidth;
                      final contentWidth = dashboardWidth - 34;
                      final cardWidth = (contentWidth - gap) / 2;

                      return RefreshIndicator(
                        onRefresh: () => _loadDashboard(silent: true),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 18, 0, 26),
                          child: Center(
                            child: SizedBox(
                              width: dashboardWidth,
                              child: Column(
                                children: [
                                  const _HeroCard(
                                    imagePath:
                                        'assets/colorful-towels-liquid-laundry-detergent.jpg',
                                  ),
                                  const SizedBox(height: 26),
                                  Wrap(
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'New Orders',
                                        value:
                                            '${_dashboard['pending_orders'] ?? 0}',
                                        subtitle: 'Today',
                                        icon: Icons.shopping_bag_outlined,
                                        iconColors: const [
                                          Color(0xFF287DFF),
                                          Color(0xFF0052D9),
                                        ],
                                        waveColor: const Color(0xFFEAF1FF),
                                      ),
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'In Progress',
                                        value: '${_inProgressOrders()}',
                                        subtitle: 'Orders',
                                        icon: Icons.shopping_basket_outlined,
                                        iconColors: const [
                                          Color(0xFF8064FF),
                                          Color(0xFF5B3CE8),
                                        ],
                                        waveColor: const Color(0xFFF0E9FF),
                                      ),
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'Total Services',
                                        value:
                                            '${_dashboard['total_services'] ?? 0}',
                                        subtitle: 'This Month',
                                        icon: Icons.bookmark_border_rounded,
                                        iconColors: const [
                                          Color(0xFF18CECF),
                                          Color(0xFF04AAB7),
                                        ],
                                        waveColor: const Color(0xFFE0FAF7),
                                      ),
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'Total Revenue',
                                        value: _shortMoney(
                                            _moneyValue('total_payments')),
                                        subtitle: 'This Month',
                                        icon: Icons.attach_money_rounded,
                                        iconColors: const [
                                          Color(0xFF29C875),
                                          Color(0xFF05A65B),
                                        ],
                                        waveColor: const Color(0xFFE5FAEC),
                                      ),
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'Total Expenses',
                                        value: _shortMoney(
                                            _moneyValue('total_expenses')),
                                        subtitle: 'This Month',
                                        icon: Icons.shopping_cart_outlined,
                                        iconColors: const [
                                          Color(0xFFFF9F00),
                                          Color(0xFFFF7900),
                                        ],
                                        waveColor: const Color(0xFFFFF0DA),
                                      ),
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'Out for Delivery',
                                        value:
                                            '${_dashboard['out_for_delivery'] ?? 0}',
                                        subtitle: 'Orders',
                                        icon: Icons.inventory_2_outlined,
                                        iconColors: const [
                                          Color(0xFFA149FF),
                                          Color(0xFF7437EA),
                                        ],
                                        waveColor: const Color(0xFFF0E5FF),
                                      ),
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'Total Orders',
                                        value:
                                            '${_dashboard['total_orders'] ?? 0}',
                                        subtitle: 'This Month',
                                        icon: Icons.airplanemode_active_rounded,
                                        iconColors: const [
                                          Color(0xFF2D84FF),
                                          Color(0xFF075BFF),
                                        ],
                                        waveColor: const Color(0xFFEAF1FF),
                                      ),
                                      _AdminMetricCard(
                                        width: cardWidth,
                                        title: 'Pending Orders',
                                        value:
                                            '${_dashboard['pending_orders'] ?? 0}',
                                        subtitle: 'Orders',
                                        icon: Icons.person_outline_rounded,
                                        iconColors: const [
                                          Color(0xFFFF5B16),
                                          Color(0xFFFF3600),
                                        ],
                                        waveColor: const Color(0xFFFFEAE3),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  int _inProgressOrders() {
    final total =
        int.tryParse((_dashboard['total_orders'] ?? 0).toString()) ?? 0;
    final pending =
        int.tryParse((_dashboard['pending_orders'] ?? 0).toString()) ?? 0;
    final paid = int.tryParse((_dashboard['paid_orders'] ?? 0).toString()) ?? 0;
    final inProgress = total - pending - paid;
    return inProgress < 0 ? 0 : inProgress;
  }

  String _shortMoney(double value) {
    return NumberFormat.compactCurrency(symbol: '\$').format(value);
  }

  double _moneyValue(String key) {
    return double.tryParse((_dashboard[key] ?? 0).toString()) ?? 0;
  }
}

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onRefresh;

  const _DashboardHeader({
    required this.onMenu,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF005FE8), Color(0xFF003792)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
          child: Row(
            children: [
              _HeaderButton(
                icon: Icons.menu_rounded,
                onTap: onMenu,
              ),
              const Expanded(
                child: Text(
                  'Admin Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _HeaderButton(
                icon: Icons.refresh,
                onTap: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String imagePath;

  const _HeroCard({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A3F91).withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF115BD4).withValues(alpha: 0.96),
                      const Color(0xFF115BD4).withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.10),
                    ],
                    stops: const [0, 0.45, 1],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(26, 26, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Color(0xFFD7E6FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'GB Laundry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Clean Quality, Happy Life.',
                      style: TextStyle(
                        color: Color(0xFFD7E6FF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> iconColors;
  final Color waveColor;

  const _AdminMetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColors,
    required this.waveColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColors.last;

    return Container(
      width: width,
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EDF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5073A5).withValues(alpha: 0.11),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              left: -24,
              right: -24,
              bottom: -50,
              child: Container(
                height: 88,
                decoration: BoxDecoration(
                  color: waveColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(160, 70),
                    topRight: Radius.elliptical(160, 70),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 17, 12, 14),
              child: Row(
                children: [
                  _MetricIcon(icon: icon, colors: iconColors),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF66728A),
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFF20283C),
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF66728A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right, color: accent, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;

  const _MetricIcon({
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.26),
            blurRadius: 15,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onReload;

  const _AdminDrawer({
    required this.onLogout,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final name = appState.customerName.isNotEmpty
        ? appState.customerName
        : 'System Admin';
    final role = appState.user?['role']?.toString() ?? 'Admin';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Drawer(
      backgroundColor: const Color(0xFFF4F8FF),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          _DrawerProfileHeader(
            initial: initial,
            name: name,
            role: role,
          ),
          const SizedBox(height: 12),
          _DrawerActionTile(
            icon: Icons.local_laundry_service,
            title: 'Manage Services',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.manageServices);
            },
          ),
          _DrawerActionTile(
            icon: Icons.people,
            title: 'Manage Staff',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.manageStaff);
            },
          ),
          _DrawerActionTile(
            icon: Icons.bar_chart,
            title: 'Reports',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reports);
            },
          ),
          _DrawerActionTile(
            icon: Icons.attach_money,
            title: 'Expenses',
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpensesScreen()),
              );
              onReload();
            },
          ),
          const SizedBox(height: 18),
          _DrawerActionTile(
            icon: Icons.logout,
            title: 'Logout',
            isDanger: true,
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  final String initial;
  final String name;
  final String role;

  const _DrawerProfileHeader({
    required this.initial,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 22,
        18,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E67D8), Color(0xFF0B3F9B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF1554B7),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDanger;

  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : const Color(0xFF1554B7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDanger ? Colors.redAccent : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

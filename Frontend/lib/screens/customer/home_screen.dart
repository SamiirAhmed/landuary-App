import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';
import '../payments/customer_payment_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingBalance = true;
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  double get _balance {
    return _orders.fold<double>(0, (total, order) => total + order.balance);
  }

  int get _unpaidOrders {
    return _orders.where((order) => order.balance > 0).length;
  }

  Future<void> _loadOrders() async {
    final appState = context.read<AppState>();
    final customerId = appState.customerId;
    if (customerId == null) {
      setState(() => _isLoadingBalance = false);
      return;
    }

    try {
      final orders = await appState.apiService.getCustomerOrders(customerId);
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AppState>().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final money = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laundry App'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome, ${appState.customerName}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'What would you like to do today?',
              style: TextStyle(color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 20),
            _BalanceCard(
              isLoading: _isLoadingBalance,
              balance: money.format(_balance),
              unpaidOrders: _unpaidOrders,
              onTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
            ),
            const SizedBox(height: 16),
            _HomeCard(
              title: 'Create Laundry Order',
              subtitle: 'Schedule pickup and add laundry items',
              icon: Icons.local_laundry_service_outlined,
              onTap: () => Navigator.pushNamed(context, AppRoutes.createOrder),
            ),
            _HomeCard(
              title: 'Order History',
              subtitle: 'Review past orders by date',
              icon: Icons.receipt_long_outlined,
              onTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
            ),
            _HomeCard(
              title: 'Payments',
              subtitle: 'View your payment history',
              icon: Icons.payments_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerPaymentHistoryScreen(),
                ),
              ),
            ),
            _HomeCard(
              title: 'Profile',
              subtitle: 'View your account, city, and district',
              icon: Icons.person_outline,
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isLoading;
  final String balance;
  final int unpaidOrders;
  final VoidCallback onTap;

  const _BalanceCard({
    required this.isLoading,
    required this.balance,
    required this.unpaidOrders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1554B7).withValues(alpha: 0.1),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF1554B7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Balance',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? 'Loading...' : balance,
                      style: const TextStyle(
                        color: Color(0xFF1554B7),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isLoading
                          ? 'Checking unpaid orders'
                          : '$unpaidOrders unpaid order${unpaidOrders == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.blueGrey.shade700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

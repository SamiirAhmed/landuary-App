import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/order_model.dart';

class CustomerPaymentHistoryScreen extends StatefulWidget {
  const CustomerPaymentHistoryScreen({super.key});

  @override
  State<CustomerPaymentHistoryScreen> createState() =>
      _CustomerPaymentHistoryScreenState();
}

class _CustomerPaymentHistoryScreenState
    extends State<CustomerPaymentHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];
  List<OrderModel> _orders = [];

  double get _totalPaid {
    return _orders.fold<double>(0, (total, order) {
      if (order.amountPaid != null) return total + order.amountPaid!;
      return total + (order.totalAmount - order.balance);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final appState = context.read<AppState>();
    final customerId = appState.customerId;

    if (customerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orders = await appState.apiService.getCustomerOrders(customerId);
      final paymentGroups = await Future.wait(
        orders.map((order) async {
          final payments = await appState.apiService
              .getPaymentHistory(order.orderId)
              .catchError((_) => <Map<String, dynamic>>[]);
          return payments.map((payment) {
            return {
              ...payment,
              'order_id': payment['order_id'] ?? order.orderId,
              'order_status': order.orderStatus,
              'order_total': order.totalAmount,
            };
          }).toList();
        }),
      );

      final payments = paymentGroups.expand((group) => group).toList();
      payments.sort((a, b) {
        final first = DateTime.tryParse(a['payment_date']?.toString() ?? '');
        final second = DateTime.tryParse(b['payment_date']?.toString() ?? '');
        if (first == null && second == null) return 0;
        if (first == null) return 1;
        if (second == null) return -1;
        return second.compareTo(first);
      });

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _payments = payments;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dateLabel(dynamic rawDate) {
    final parsed = DateTime.tryParse(rawDate?.toString() ?? '');
    if (parsed == null) return 'Unknown date';
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: _isLoading
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _payments.isEmpty ? 2 : _payments.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFF1554B7)
                                  .withValues(alpha: 0.1),
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
                                    'Total Payments',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    money.format(_totalPaid),
                                    style: const TextStyle(
                                      color: Color(0xFF1554B7),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'For your account',
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_payments.isEmpty) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: Text('No payment history found')),
                    );
                  }

                  final payment = _payments[index - 1];
                  final amount = double.tryParse(
                        payment['amount_paid'].toString(),
                      ) ??
                      0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEAF1FF),
                        child: Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF1554B7),
                        ),
                      ),
                      title: Text(
                        money.format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Order #${payment['order_id']}\n'
                          '${payment['payment_method']} | ${_dateLabel(payment['payment_date'])}\n'
                          '${payment['payment_note'] ?? 'No note'}',
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

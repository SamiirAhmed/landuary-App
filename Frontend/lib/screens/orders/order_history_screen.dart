import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  DateTime? _selectedDate;

  String _exactDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Unknown date';

    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;

    return DateFormat('MMM d, yyyy').format(parsed);
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedDate == null) return _orders;

    return _orders.where((order) {
      final parsed =
          DateTime.tryParse(order.createdAt ?? order.pickupDate ?? '');
      if (parsed == null) return false;
      return parsed.year == _selectedDate!.year &&
          parsed.month == _selectedDate!.month &&
          parsed.day == _selectedDate!.day;
    }).toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final customerId = context.read<AppState>().customerId;
    if (customerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final orders = await context
          .read<AppState>()
          .apiService
          .getCustomerOrders(customerId);
      if (!mounted) return;
      orders.sort((a, b) {
        final first = DateTime.tryParse(a.createdAt ?? a.pickupDate ?? '');
        final second = DateTime.tryParse(b.createdAt ?? b.pickupDate ?? '');
        if (first == null && second == null) return 0;
        if (first == null) return 1;
        if (second == null) return -1;
        return second.compareTo(first);
      });
      setState(() => _orders = orders);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$');
    final filteredOrders = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _orders.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: Center(child: Text('No orders found')),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        filteredOrders.isEmpty ? 2 : filteredOrders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickDate,
                                  icon:
                                      const Icon(Icons.calendar_today_outlined),
                                  label: Text(
                                    _selectedDate == null
                                        ? 'Filter by date'
                                        : DateFormat('MMM d, yyyy')
                                            .format(_selectedDate!),
                                  ),
                                ),
                              ),
                              if (_selectedDate != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Clear date filter',
                                  onPressed: () =>
                                      setState(() => _selectedDate = null),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      if (filteredOrders.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(child: Text('No orders for this date')),
                        );
                      }

                      final order = filteredOrders[index - 1];
                      final dateLabel =
                          _exactDate(order.createdAt ?? order.pickupDate);
                      final balance = order.balance;
                      final canPay = balance > 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              dateLabel,
                              style: const TextStyle(
                                color: Color(0xFF1554B7),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF1554B7)
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.receipt_long_outlined,
                                        color: Color(0xFF1554B7),
                                      ),
                                    ),
                                    title: Text('Order #${order.orderId}'),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Order date: $dateLabel\n'
                                        'Status: ${order.orderStatus}\n'
                                        'Pickup: ${_exactDate(order.pickupDate)}\n'
                                        'Payment: ${order.paymentStatus}\n'
                                        'Balance: ${money.format(balance)}',
                                      ),
                                    ),
                                    trailing: Text(
                                      money.format(balance),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1554B7),
                                      ),
                                    ),
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.orderDetails,
                                      arguments: order.orderId,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: canPay
                                          ? () async {
                                              final changed =
                                                  await Navigator.pushNamed(
                                                context,
                                                AppRoutes.payment,
                                                arguments: {
                                                  'order_id': order.orderId,
                                                  'total_amount': balance,
                                                },
                                              );
                                              if (changed == true) {
                                                _loadOrders();
                                              }
                                            }
                                          : null,
                                      icon: Icon(canPay
                                          ? Icons.payments_outlined
                                          : Icons.check_circle_outline),
                                      label: Text(canPay ? 'PAY' : 'PAID'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}

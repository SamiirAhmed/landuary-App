import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/order_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/order_item_card.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await context
          .read<AppState>()
          .apiService
          .getOrderDetails(widget.orderId);
      if (!mounted) return;
      setState(() => _order = order);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        child: _isLoading
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _order == null
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: Center(child: Text('Order not found')),
                    ),
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_order!.customerName ?? 'Customer',
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(_order!.customerPhone ?? '-'),
                              const Divider(height: 28),
                              Text('Pickup address: ${_order!.pickupAddress}'),
                              Text('Pickup date: ${_order!.pickupDate ?? '-'}'),
                              Text('Payment: ${_order!.paymentStatus}'),
                              Text('Balance: ${money.format(_order!.balance)}'),
                              Text('Status: ${_order!.orderStatus}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Items',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._order!.items.map((item) => OrderItemCard(item: item)),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          title: const Text('Total amount'),
                          trailing: Text(
                            money.format(_order!.totalAmount),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final changed = await Navigator.pushNamed(
                                  context,
                                  AppRoutes.payment,
                                  arguments: {
                                    'order_id': _order!.orderId,
                                    'total_amount': _order!.balance,
                                  },
                                );
                                if (changed == true) _loadOrder();
                              },
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('PAY'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.paymentHistory,
                                arguments: _order!.orderId,
                              ),
                              icon: const Icon(Icons.history),
                              label: const Text('HISTORY'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

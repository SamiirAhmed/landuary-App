import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int orderId;

  const PaymentHistoryScreen({super.key, required this.orderId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await context
          .read<AppState>()
          .apiService
          .getPaymentHistory(widget.orderId);
      if (!mounted) return;
      setState(() => _payments = payments);
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
        title: Text('Payments #${widget.orderId}'),
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
            : _payments.isEmpty
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: Center(child: Text('No payments found')),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEAF1FF),
                            child: Icon(Icons.payments_outlined,
                                color: Color(0xFF1554B7)),
                          ),
                          title: Text(money.format(
                              double.parse(payment['amount_paid'].toString()))),
                          subtitle: Text(
                            '${payment['payment_method']}\n${payment['payment_date'] ?? '-'}\n${payment['payment_note'] ?? ''}',
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

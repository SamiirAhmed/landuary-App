import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _methods = ['Cash', 'EVC Plus', 'Zaad', 'Card', 'Bank'];
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().apiService.makePayment({
        'order_id': widget.orderId,
        'amount_paid': amount,
        'payment_method': _paymentMethod,
        'payment_note': _noteController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text('Pay Order #${widget.orderId}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FormSectionTitle(title: 'Payment Details'),
                        const SizedBox(height: 20),
                        Text(
                          'Amount Due',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          money.format(widget.totalAmount),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1554B7)),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _amountController,
                          label: 'Amount Paid',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          items: _methods
                              .map((method) =>
                                  DropdownMenuItem(value: method, child: Text(method)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _paymentMethod = value ?? 'Cash'),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _noteController,
                          label: 'Payment Note',
                          icon: Icons.note_alt_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 22),
                        CustomButton(
                          label: 'Pay',
                          icon: Icons.check_circle_outline,
                          isLoading: _isLoading,
                          onPressed: _pay,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

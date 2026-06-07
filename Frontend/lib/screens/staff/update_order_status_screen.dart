import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';

class UpdateOrderStatusScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const UpdateOrderStatusScreen({super.key, required this.order});

  @override
  State<UpdateOrderStatusScreen> createState() =>
      _UpdateOrderStatusScreenState();
}

class _UpdateOrderStatusScreenState extends State<UpdateOrderStatusScreen> {
  final _remarksController = TextEditingController();
  final _statuses = [
    'Pending',
    'Accepted',
    'Picked Up',
    'Washing',
    'Ironing',
    'Ready',
    'Delivered',
    'Cancelled'
  ];
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order['order_status']?.toString() ?? 'Pending';
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AppState>().user;
      await context.read<AppState>().apiService.updateOrderStatus({
        'order_id': widget.order['order_id'],
        'new_status': _status,
        'changed_by': user?['user_id'],
        'remarks': _remarksController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order status updated')));
      Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order['order_id']}'),
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
                        const FormSectionTitle(title: 'Update Status'),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: InputDecoration(
                            labelText: 'Order Status',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          items: _statuses
                              .map((status) =>
                                  DropdownMenuItem(value: status, child: Text(status)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _status = value ?? 'Pending'),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _remarksController,
                          label: 'Remarks',
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 22),
                        CustomButton(
                            label: 'Update Status',
                            icon: Icons.save,
                            isLoading: _isLoading,
                            onPressed: _update),
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

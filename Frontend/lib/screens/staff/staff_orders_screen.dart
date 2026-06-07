import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../routes/app_routes.dart';
import 'widgets/staff_order_filters_panel.dart';

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  DateTime? _selectedDate;
  String _customerFilter = 'All Customers';

  double _amount(Map<String, dynamic> order, List<String> keys) {
    return _firstAmount(order, keys) ?? 0;
  }

  double? _firstAmount(Map<String, dynamic> order, List<String> keys) {
    for (final key in keys) {
      final value = order[key];
      if (value == null) continue;
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _exactDate(Object? rawDate) {
    final value = rawDate?.toString();
    if (value == null || value.isEmpty) return '-';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    return DateFormat('MMM d, yyyy').format(parsed);
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((order) {
      if (_customerFilter != 'All Customers' &&
          _customerLabel(order) != _customerFilter) {
        return false;
      }

      if (_selectedDate != null) {
        final parsed = DateTime.tryParse(
          order['created_at']?.toString() ??
              order['pickup_date']?.toString() ??
              '',
        );
        if (parsed == null ||
            parsed.year != _selectedDate!.year ||
            parsed.month != _selectedDate!.month ||
            parsed.day != _selectedDate!.day) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> get _customerFilters {
    final customers = _orders.map(_customerLabel).toSet().toList()..sort();
    return ['All Customers', ...customers];
  }

  String _customerLabel(Map<String, dynamic> order) {
    final name = order['customer_name']?.toString() ?? 'Customer';
    final phone = order['phone']?.toString();
    return phone == null || phone.isEmpty ? name : '$name -- $phone';
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

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      if (mounted) setState(() => _isLoading = true);
    }
    try {
      final Future<List<Map<String, dynamic>>> apiCall =
          context.read<AppState>().apiService.getStaffOrders();

      final results = await Future.wait([
        apiCall,
        if (silent) Future.delayed(const Duration(milliseconds: 600)),
      ]);

      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<Map<String, dynamic>>;
        if (!_customerFilters.contains(_customerFilter)) {
          _customerFilter = 'All Customers';
        }
      });
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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Staff Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
              onPressed: () => _loadOrders(silent: true),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : RefreshIndicator(
              color: const Color(0xFF3B82F6),
              onRefresh: () => _loadOrders(silent: true),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount:
                    filteredOrders.isEmpty ? 2 : filteredOrders.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return StaffOrderFiltersPanel(
                      selectedDate: _selectedDate,
                      customerFilter: _customerFilter,
                      customerFilters: _customerFilters,
                      resultCount: filteredOrders.length,
                      onPickDate: _pickDate,
                      onClearDate: () => setState(() => _selectedDate = null),
                      onCustomerFilterChanged: (value) {
                        setState(() {
                          _customerFilter = value ?? 'All Customers';
                        });
                      },
                    );
                  }

                  if (filteredOrders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No orders match filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final order = filteredOrders[index - 1];
                  final total = _amount(order, ['total_amount']);
                  final status = order['order_status']?.toString() ?? 'Pending';
                  
                  // Color styling based on status
                  Color statusColor = const Color(0xFF3B82F6);
                  if (status.toLowerCase() == 'delivered') {
                    statusColor = const Color(0xFF10B981);
                  } else if (status.toLowerCase() == 'ready') {
                    statusColor = const Color(0xFF8B5CF6);
                  } else if (status.toLowerCase() == 'cancelled') {
                    statusColor = const Color(0xFFEF4444);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
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
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.updateOrderStatus,
                          arguments: order,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F4FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Order #${order['order_id']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${order['customer_name']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${order['phone']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    money.format(total),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Color(0xFFE8EFFE), thickness: 1.5),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade400),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${order['pickup_address']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 6),
                                  Text(
                                    _exactDate(order['pickup_date']),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
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
    );
  }
}

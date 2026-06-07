import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/cloth_type_model.dart';
import '../../models/order_item_model.dart';
import '../../models/service_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';
import '../../widgets/order_item_card.dart';
import '../../widgets/service_dropdown.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _quantityController = TextEditingController();
  final _weightController = TextEditingController();
  final _itemNotesController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _specialNotesController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  List<ServiceModel> _services = [];
  List<ClothTypeModel> _clothTypes = [];
  final List<OrderItemModel> _items = [];
  ServiceModel? _selectedService;
  ClothTypeModel? _selectedClothType;
  DateTime? _pickupDate;

  double get _total => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _weightController.dispose();
    _itemNotesController.dispose();
    _pickupAddressController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<AppState>().apiService;
      final services = await api.getServices();
      final clothTypes = await api.getClothTypes();
      if (!mounted) return;
      setState(() {
        _services = services;
        _clothTypes = clothTypes;
      });
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    final service = _selectedService;
    final clothType = _selectedClothType;

    if (service == null || clothType == null) {
      _showError('Please select service and cloth type');
      return;
    }

    final isPerKg = service.priceType == 'Per Kg';
    final quantity = int.tryParse(_quantityController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (isPerKg && (weight == null || weight <= 0)) {
      _showError('Weight is required for per kg service');
      return;
    }

    if (!isPerKg && (quantity == null || quantity <= 0)) {
      _showError('Quantity is required');
      return;
    }

    final subtotal =
        isPerKg ? service.price * weight! : service.price * quantity!;

    setState(() {
      _items.add(
        OrderItemModel(
          serviceId: service.serviceId,
          serviceName: service.serviceName,
          clothTypeId: clothType.clothTypeId,
          clothName: clothType.clothName,
          quantity: isPerKg ? null : quantity,
          weight: isPerKg ? weight : null,
          unitPrice: service.price,
          subtotal: subtotal,
          notes: _itemNotesController.text.trim().isEmpty
              ? null
              : _itemNotesController.text.trim(),
        ),
      );
      _quantityController.clear();
      _weightController.clear();
      _itemNotesController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _pickupDate = picked);
    }
  }

  Future<void> _submitOrder() async {
    final customerId = context.read<AppState>().customerId;

    if (customerId == null) {
      _showError('Please login as a customer first');
      return;
    }

    if (_items.isEmpty ||
        _pickupAddressController.text.trim().isEmpty ||
        _pickupDate == null) {
      _showError(
          'Pickup address, pickup date, and at least one item are required');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final order = await context.read<AppState>().apiService.createOrder({
        'customer_id': customerId,
        'pickup_address': _pickupAddressController.text.trim(),
        'pickup_date': DateFormat('yyyy-MM-dd').format(_pickupDate!),
        'special_notes': _specialNotesController.text.trim(),
        'items': _items.map((item) => item.toCreateJson()).toList(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully')),
      );
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.orderDetails,
        arguments: order.orderId,
      );
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$');
    final isPerKg = _selectedService?.priceType == 'Per Kg';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1554B7),
        foregroundColor: Colors.white,
        title: const Text('Create Laundry Order'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadLookups,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLookups,
        child: _isLoading
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  FormCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FormSectionTitle(title: 'Laundry Item'),
                        const SizedBox(height: 20),
                        ServiceDropdown<ServiceModel>(
                          label: 'Select service',
                          value: _selectedService,
                          items: _services,
                          itemLabel: (service) =>
                              '${service.serviceName} - ${money.format(service.price)}',
                          onChanged: (service) =>
                              setState(() => _selectedService = service),
                        ),
                        const SizedBox(height: 12),
                        ServiceDropdown<ClothTypeModel>(
                          label: 'Select cloth type',
                          value: _selectedClothType,
                          items: _clothTypes,
                          itemLabel: (cloth) => cloth.clothName,
                          onChanged: (cloth) =>
                              setState(() => _selectedClothType = cloth),
                        ),
                        const SizedBox(height: 12),
                        if (isPerKg)
                          CustomTextField(
                            controller: _weightController,
                            label: 'Weight',
                            icon: Icons.scale_outlined,
                            keyboardType: TextInputType.number,
                          )
                        else
                          CustomTextField(
                            controller: _quantityController,
                            label: 'Quantity',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                          ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _itemNotesController,
                          label: 'Item Notes',
                          icon: Icons.note_alt_outlined,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          label: 'Add Item',
                          icon: Icons.add,
                          onPressed: _addItem,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Added Items',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('No items added yet'),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map(
                          (entry) => OrderItemCard(
                            item: entry.value,
                            onRemove: () =>
                                setState(() => _items.removeAt(entry.key)),
                          ),
                        ),
                  const SizedBox(height: 16),
                  FormCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FormSectionTitle(title: 'Pickup Details'),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: _pickupAddressController,
                          label: 'Pickup Address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            title: const Text('Pickup Date'),
                            subtitle: Text(
                              _pickupDate == null
                                  ? 'Choose date'
                                  : DateFormat('yyyy-MM-dd').format(_pickupDate!),
                            ),
                            trailing: const Icon(Icons.calendar_month,
                                color: Color(0xFF1554B7)),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _specialNotesController,
                          label: 'Special Notes',
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Total Amount'),
                          trailing: Text(
                            money.format(_total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1554B7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          label: 'Submit Order',
                          icon: Icons.send,
                          isLoading: _isSubmitting,
                          onPressed: _submitOrder,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

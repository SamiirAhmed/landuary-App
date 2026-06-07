import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/service_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priceType = 'Per Item';
  bool _isLoading = true;
  List<ServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final services =
        await context.read<AppState>().apiService.getAdminServices();
    if (!mounted) return;
    setState(() {
      _services = services;
      _isLoading = false;
    });
  }

  Future<void> _addService() async {
    try {
      await context.read<AppState>().apiService.addService({
        'service_name': _nameController.text.trim(),
        'price_type': _priceType,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
      });
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _loadServices();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _updateService(ServiceModel service,
      {double? price, String? status}) async {
    try {
      await context.read<AppState>().apiService.updateService({
        'service_id': service.serviceId,
        'price': price,
        'status': status,
      });
      _loadServices();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Manage Services'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadServices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
        onRefresh: _loadServices,
        child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  FormCard(
                    child: Column(
                      children: [
                        const FormSectionTitle(title: 'Add Service'),
                        const SizedBox(height: 16),
                        CustomTextField(
                            controller: _nameController,
                            label: 'Service Name',
                            icon: Icons.cleaning_services_outlined),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _priceType,
                          items: ['Per Item', 'Per Kg', 'Fixed']
                              .map((type) => DropdownMenuItem(
                                  value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _priceType = value ?? 'Per Item'),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                            controller: _priceController,
                            label: 'Price',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        CustomTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            icon: Icons.description_outlined),
                        const SizedBox(height: 16),
                        CustomButton(
                            label: 'Add Service',
                            icon: Icons.add,
                            onPressed: _addService),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._services.map(
                    (service) => Card(
                      child: ListTile(
                        title: Text(service.serviceName),
                        subtitle: Text(
                            '${service.priceType} - \$${service.price} - ${service.status}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'active')
                              _updateService(service, status: 'Active');
                            if (value == 'inactive')
                              _updateService(service, status: 'Inactive');
                            if (value == 'price') _showPriceDialog(service);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'price', child: Text('Update price')),
                            PopupMenuItem(
                                value: 'active', child: Text('Activate')),
                            PopupMenuItem(
                                value: 'inactive', child: Text('Inactivate')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showPriceDialog(ServiceModel service) {
    final controller = TextEditingController(text: service.price.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Price'),
        content: TextField(
            controller: controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateService(service,
                  price:
                      double.tryParse(controller.text.trim()) ?? service.price);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

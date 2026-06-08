import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../models/service_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';
import '../../widgets/success_dialog.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      showErrorDialog(
        context,
        title: 'Missing details',
        message: 'Service name and price are required',
      );
      return;
    }

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
      if (mounted)
        showSuccessDialog(context,
            title: 'Success', message: 'Service added successfully');
    } catch (error) {
      if (mounted)
        showErrorDialog(context, title: 'Error', message: error.toString());
    }
  }

  Future<void> _updateServiceStatus(ServiceModel service, String status) async {
    try {
      await context.read<AppState>().apiService.updateService({
        'service_id': service.serviceId,
        'status': status,
      });
      await _loadServices();
      if (mounted) {
        showSuccessDialog(
          context,
          title: 'Success',
          message: 'Service ${status.toLowerCase()} successfully',
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorDialog(context, title: 'Error', message: error.toString());
      }
    }
  }

  Future<void> _deleteService(ServiceModel service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Service'),
        content:
            Text('Are you sure you want to delete ${service.serviceName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context
          .read<AppState>()
          .apiService
          .deleteService(service.serviceId);
      await _loadServices();
      if (mounted)
        showSuccessDialog(context,
            title: 'Deleted', message: 'Service deleted successfully');
    } catch (error) {
      if (mounted)
        showErrorDialog(context, title: 'Error', message: error.toString());
    }
  }

  Future<void> _updateService(
      ServiceModel service, Map<String, dynamic> data) async {
    try {
      await context.read<AppState>().apiService.updateService({
        'service_id': service.serviceId,
        ...data,
      });
      await _loadServices();
      if (mounted)
        showSuccessDialog(context,
            title: 'Success', message: 'Service updated successfully');
    } catch (error) {
      if (mounted)
        showErrorDialog(context, title: 'Error', message: error.toString());
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
                            if (value == 'update') _showEditDialog(service);
                            if (value == 'activate') {
                              _updateServiceStatus(service, 'Active');
                            }
                            if (value == 'inactive') {
                              _updateServiceStatus(service, 'Inactive');
                            }
                            if (value == 'delete') _deleteService(service);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'update',
                              child: Text('Update service'),
                            ),
                            PopupMenuItem(
                              value: service.status == 'Active'
                                  ? 'inactive'
                                  : 'activate',
                              child: Text(
                                service.status == 'Active'
                                    ? 'Inactivate'
                                    : 'Activate',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
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

  void _showEditDialog(ServiceModel service) {
    final nameCtrl = TextEditingController(text: service.serviceName);
    final priceCtrl = TextEditingController(text: service.price.toString());
    final descCtrl = TextEditingController(text: service.description ?? '');
    String type = service.priceType;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Service Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: ['Per Item', 'Per Kg', 'Fixed']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v ?? type),
                  decoration: const InputDecoration(labelText: 'Price Type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty ||
                    priceCtrl.text.trim().isEmpty) {
                  showErrorDialog(
                    ctx,
                    title: 'Missing details',
                    message: 'Service name and price are required',
                  );
                  return;
                }

                Navigator.pop(ctx);
                _updateService(service, {
                  'service_name': nameCtrl.text.trim(),
                  'price_type': type,
                  'price':
                      double.tryParse(priceCtrl.text.trim()) ?? service.price,
                  'description': descCtrl.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

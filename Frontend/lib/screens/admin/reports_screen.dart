import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reports = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await context.read<AppState>().apiService.getReports();
      if (!mounted) return;
      setState(() => _reports = reports);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _ReportTile(
                    label: 'Daily Income',
                    value: money.format(
                      double.parse((_reports['daily_income'] ?? 0).toString()),
                    ),
                  ),
                  _ReportTile(
                    label: 'Monthly Income',
                    value: money.format(
                      double.parse(
                        (_reports['monthly_income'] ?? 0).toString(),
                      ),
                    ),
                  ),
                  _ReportTile(
                    label: 'Total Orders',
                    value: _reports['total_orders'],
                  ),
                  _ReportTile(
                    label: 'Unpaid Orders',
                    value: _reports['unpaid_orders'],
                  ),
                  _ReportTile(
                    label: 'Completed Orders',
                    value: _reports['completed_orders'],
                  ),
                  _ReportTile(
                    label: 'Expenses',
                    value: money.format(
                      double.parse((_reports['expenses'] ?? 0).toString()),
                    ),
                  ),
                  _ReportTile(
                    label: 'Profit',
                    value: money.format(
                      double.parse((_reports['profit'] ?? 0).toString()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String label;
  final Object? value;

  const _ReportTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '${value ?? 0}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1554B7),
          ),
        ),
      ),
    );
  }
}

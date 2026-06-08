import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/form_card.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime _expenseDate = DateTime.now();
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    try {
      final expenses = await context.read<AppState>().apiService.getExpenses();
      if (!mounted) return;
      setState(() => _expenses = expenses);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_titleController.text.trim().isEmpty || amount == null || amount <= 0) {
      _showError('Enter expense title and valid amount');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().apiService.addExpense({
        'expense_title': _titleController.text.trim(),
        'amount': amount,
        'expense_date': DateFormat('yyyy-MM-dd').format(_expenseDate),
        'description': _descriptionController.text.trim(),
      });

      if (!mounted) return;
      _titleController.clear();
      _amountController.clear();
      _descriptionController.clear();
      setState(() => _expenseDate = DateTime.now());
      await _loadExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added')),
      );
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            FormCard(
              maxWidth: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormSectionTitle(title: 'Add Expense'),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: _titleController,
                    label: 'Expense Title',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _amountController,
                    label: 'Amount',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormat('MMM d, yyyy').format(_expenseDate)),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    label: 'Add Expense',
                    icon: Icons.add,
                    isLoading: _isSaving,
                    onPressed: _saveExpense,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Recent Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_expenses.isEmpty)
              const Card(
                child: ListTile(title: Text('No expenses recorded')),
              )
            else
              ..._expenses.map((expense) {
                final amount =
                    double.tryParse(expense['amount'].toString()) ?? 0;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF1554B7).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF1554B7),
                      ),
                    ),
                    title: Text(expense['expense_title']?.toString() ?? '-'),
                    subtitle: Text(
                      '${expense['expense_date'] ?? '-'}\n'
                      '${expense['description'] ?? ''}',
                    ),
                    trailing: Text(
                      money.format(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1554B7),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

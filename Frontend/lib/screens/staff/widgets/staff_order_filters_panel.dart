import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StaffOrderFiltersPanel extends StatelessWidget {
  final DateTime? selectedDate;
  final String customerFilter;
  final List<String> customerFilters;
  final int resultCount;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<String?> onCustomerFilterChanged;

  const StaffOrderFiltersPanel({
    super.key,
    required this.selectedDate,
    required this.customerFilter,
    required this.customerFilters,
    required this.resultCount,
    required this.onPickDate,
    required this.onClearDate,
    required this.onCustomerFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: customerFilter,
              decoration: InputDecoration(
                labelText: 'Customer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: customerFilters
                  .map(
                    (customer) => DropdownMenuItem(
                      value: customer,
                      child: Text(customer, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onCustomerFilterChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      selectedDate == null
                          ? 'Filter by date'
                          : DateFormat('MMM d, yyyy').format(selectedDate!),
                    ),
                  ),
                ),
                if (selectedDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Clear date filter',
                    onPressed: onClearDate,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$resultCount order${resultCount == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.blueGrey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

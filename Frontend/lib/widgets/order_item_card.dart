import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_item_model.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItemModel item;
  final VoidCallback? onRemove;

  const OrderItemCard({
    super.key,
    required this.item,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '\$');
    final amountText = item.weight != null
        ? '${item.weight} kg'
        : '${item.quantity ?? 0} item(s)';

    return Card(
      child: ListTile(
        title: Text('${item.serviceName} - ${item.clothName}'),
        subtitle: Text('$amountText | Unit ${money.format(item.unitPrice)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              money.format(item.subtotal),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}

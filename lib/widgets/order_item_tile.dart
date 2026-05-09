import 'package:flutter/material.dart';
import 'package:dinnerhome/models/order_item.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final VoidCallback? onRemove;
  final String? itemName;

  const OrderItemTile({
    required this.item,
    this.onRemove,
    this.itemName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEC5B13).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${item.quantity}x',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEC5B13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName ?? 'Item ${item.menuItemId}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '\$${(item.priceCents / 100).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:dinnerhome/models/order.dart';

class KdsTicket extends StatelessWidget {
  final Order order;
  final VoidCallback? onMarkPrepping;
  final VoidCallback? onMarkReady;

  const KdsTicket({
    required this.order,
    this.onMarkPrepping,
    this.onMarkReady,
    super.key,
  });

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.sentToKitchen:
        return const Color(0xFFF59E0B);
      case OrderStatus.prepping:
        return const Color(0xFF3B82F6);
      case OrderStatus.ready:
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (order.status) {
      case OrderStatus.sentToKitchen:
        return 'NUEVO';
      case OrderStatus.prepping:
        return 'PREPARANDO';
      case OrderStatus.ready:
        return 'LISTO';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F3460),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _statusColor().withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${order.id.split('-').last}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Table info
            Text(
              'Mesa ${order.tableId}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                order.notes!,
                style: const TextStyle(color: Colors.amber, fontSize: 11),
              ),
            ],
            const SizedBox(height: 8),

            // Divider
            Container(height: 1, color: Colors.white12),

            // Items
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (ctx, idx) {
                  final item = order.items[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: const TextStyle(
                            color: Color(0xFFEC5B13),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Item ${item.menuItemId}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        if (item.modifierIds.isNotEmpty)
                          const Icon(Icons.tune, color: Colors.white38, size: 14),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Action buttons
            if (onMarkPrepping != null || onMarkReady != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onMarkPrepping ?? onMarkReady,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onMarkPrepping != null
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    onMarkPrepping != null ? 'Iniciar Preparación' : 'Marcar Listo',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

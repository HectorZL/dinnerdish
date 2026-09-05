import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/presentation/theme/app_theme.dart';

class KdsTicket extends StatelessWidget {
  final Order order;
  final VoidCallback? onMarkPrepping;
  final VoidCallback? onMarkReady;
  final Function(String)? onItemMarkReady;
  final bool shrinkWrap;

  const KdsTicket({
    required this.order,
    this.onMarkPrepping,
    this.onMarkReady,
    this.onItemMarkReady,
    this.shrinkWrap = false,
    super.key,
  });

  Color _statusBgColor() {
    switch (order.status) {
      case OrderStatus.sentToKitchen:
        return const Color(0xFFFFF7ED); // Orange-50
      case OrderStatus.prepping:
        return const Color(0xFFEFF6FF); // Blue-50
      case OrderStatus.ready:
        return const Color(0xFFECFDF5); // Emerald-50
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusTextColor() {
    switch (order.status) {
      case OrderStatus.sentToKitchen:
        return const Color(0xFFEA580C); // Orange-600
      case OrderStatus.prepping:
        return const Color(0xFF2563EB); // Blue-600
      case OrderStatus.ready:
        return const Color(0xFF059669); // Emerald-600
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _statusBorderColor() {
    switch (order.status) {
      case OrderStatus.sentToKitchen:
        return const Color(0xFFFFEDD5); // Orange-100
      case OrderStatus.prepping:
        return const Color(0xFFDBEAFE); // Blue-100
      case OrderStatus.ready:
        return const Color(0xFFD1FAE5); // Emerald-100
      default:
        return const Color(0xFFE2E8F0);
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [AppShadows.card],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor(),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _statusBorderColor()),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: _statusTextColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${order.id.split('-').last}',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table info
          Row(
            children: [
              const Icon(
                Icons.table_restaurant_rounded,
                color: AppColors.primaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mesa ${order.tableId}',
                style: AppTypography.h3(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // Amber-50
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)), // Amber-200
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706), // Amber-600
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.notes!,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF92400E), // Amber-800
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Divider
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Items
          if (shrinkWrap)
            _buildItemsList()
          else
            Expanded(
              child: _buildItemsList(),
            ),

          // Action buttons
          if (onMarkPrepping != null || onMarkReady != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onMarkPrepping ?? onMarkReady,
                icon: Icon(
                  onMarkPrepping != null
                      ? Icons.play_arrow_rounded
                      : Icons.check_rounded,
                  size: 18,
                ),
                label: Text(
                  onMarkPrepping != null ? 'Iniciar Preparación' : 'Marcar Listo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: onMarkPrepping != null
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const ScrollPhysics(),
      itemCount: order.items.length,
      itemBuilder: (ctx, idx) {
        final item = order.items[idx];
        final isItemReady = item.status.name == 'ready' || item.status.name == 'served';

        final canTapItem = onItemMarkReady != null && !isItemReady;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canTapItem ? () => onItemMarkReady!(item.id) : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (onItemMarkReady != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, left: 4),
                        child: Icon(
                          isItemReady
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: isItemReady
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          size: 24,
                        ),
                      )
                    else if (isItemReady)
                      const Padding(
                        padding: EdgeInsets.only(right: 8, left: 4),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isItemReady
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          color: isItemReady
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFFEA580C),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          decoration:
                              isItemReady ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name ?? item.menuItemId,
                            style: GoogleFonts.plusJakartaSans(
                              color: isItemReady
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration:
                                  isItemReady ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.notes!,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFEA580C),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (item.modifierIds.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.tune,
                          color: Color(0xFF94A3B8),
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

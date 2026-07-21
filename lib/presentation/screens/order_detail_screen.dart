import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import '../theme/app_theme.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({required this.orderId, super.key});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final orderService = ref.read(orderServiceProvider);
      final order = await orderService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPayment() async {
    if (_order == null) return;

    final paymentService = ref.read(paymentServiceProvider);
    final currentUser = ref.read(currentUserProvider).value;
    final auditService = ref.read(auditServiceProvider);

    try {
      await paymentService.requestPayment(
        orderId: _order!.id,
        requestedBy: currentUser!.id,
      );
      await auditService.record(
        action: 'request_payment',
        userId: currentUser.id,
        metadata: {'orderId': _order!.id},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago solicitado al cajero')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/menu');
            }
          },
        ),
        title: Text(
          'Comanda #${widget.orderId}',
          style: AppTypography.h3(color: AppColors.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                _order?.status.name.toUpperCase() ?? '...',
                style: AppTypography.statusBadge(
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? const Center(child: Text('Orden no encontrada'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info
                      StitchCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Detalle de Comanda',
                                  style: AppTypography.h2(),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _order!.status == OrderStatus.draft
                                        ? AppColors.statusPending.withValues(
                                            alpha: 0.1,
                                          )
                                        : _order!.status ==
                                              OrderStatus.sentToKitchen
                                        ? AppColors.statusCooking.withValues(
                                            alpha: 0.1,
                                          )
                                        : _order!.status == OrderStatus.ready
                                        ? AppColors.statusReady.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.tertiaryContainer
                                              .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.full,
                                    ),
                                  ),
                                  child: Text(
                                    _order!.status.name,
                                    style: AppTypography.statusBadge(
                                      color: _order!.status == OrderStatus.draft
                                          ? AppColors.statusPending
                                          : _order!.status ==
                                                OrderStatus.sentToKitchen
                                          ? AppColors.statusCooking
                                          : _order!.status == OrderStatus.ready
                                          ? AppColors.statusReady
                                          : AppColors.tertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildInfoRow('Mesa', _order!.tableId),
                            _buildInfoRow('Mesero', _order!.waiterId),
                            _buildInfoRow('Items', '${_order!.items.length}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Items List
                      StitchCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Artículos',
                                style: AppTypography.h3(),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ..._order!.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xl,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${item.quantity}x',
                                          style: AppTypography.statusBadge(
                                            color: AppColors.primaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item.name ?? 'Item ${item.menuItemId}'}',
                                            style:
                                                AppTypography.bodyMd(
                                                  color: AppColors.onSurface,
                                                ).copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            '\$${(item.priceCents / 100).toStringAsFixed(2)}',
                                            style: AppTypography.bodyMd(
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            item.status ==
                                                order_item.OrderStatus.pending
                                            ? AppColors.statusPending
                                                  .withValues(alpha: 0.1)
                                            : AppColors.statusReady.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.full,
                                        ),
                                      ),
                                      child: Text(
                                        item.status.name,
                                        style: AppTypography.statusBadge(
                                          color:
                                              item.status ==
                                                  order_item.OrderStatus.pending
                                              ? AppColors.statusPending
                                              : AppColors.statusReady,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Totals
                      StitchCard(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Subtotal',
                              '\$${(_order!.subtotalCents / 100).toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: AppSpacing.base),
                            _buildInfoRow(
                              'Impuesto',
                              '\$${(_order!.taxCents / 100).toStringAsFixed(2)}',
                            ),
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL',
                                  style: AppTypography.h2(
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                                Text(
                                  '\$${(_order!.totalCents / 100).toStringAsFixed(2)}',
                                  style: AppTypography.h2(
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Action Buttons
                      if (_order!.status != OrderStatus.closed &&
                          _order!.status != OrderStatus.billed)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/orders/${widget.orderId}/edit'),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            label: const Text('Añadir Platos'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryContainer,
                              side: const BorderSide(
                                color: AppColors.primaryContainer,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_order!.status != OrderStatus.closed &&
                          _order!.status != OrderStatus.billed)
                        const SizedBox(height: AppSpacing.sm),
                      if (_order!.status == OrderStatus.ready ||
                          _order!.status == OrderStatus.billed)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.go(
                                  '/orders/${widget.orderId}/payment',
                                ),
                                icon: const Icon(Icons.payments, size: 20),
                                label: const Text('Ir a Pago'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.xl,
                                    ),
                                  ),
                                  elevation: 8,
                                  shadowColor: AppColors.primaryContainer
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _requestPayment,
                                icon: const Icon(Icons.receipt, size: 20),
                                label: const Text('Solicitar Pago'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryContainer,
                                  side: const BorderSide(
                                    color: AppColors.primaryContainer,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.xl,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
          ),
          Text(
            value,
            style: AppTypography.bodyMd(
              color: AppColors.onSurface,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

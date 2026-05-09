import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/order.dart';
import '../../models/payment_method.dart';
import '../theme/app_theme.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PaymentProcessingScreen({required this.orderId, super.key});

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen> {
  Order? _order;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final List<int> _splitAmounts = [];

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderService = ref.read(orderServiceProvider);
      final order = await orderService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_order == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      if (_splitAmounts.isNotEmpty) {
        await paymentService.splitPayment(
          orderId: widget.orderId,
          splitAmountsCents: _splitAmounts,
          processedBy: currentUser.id,
        );
      } else {
        await paymentService.processPayment(
          orderId: widget.orderId,
          amountCents: _order!.totalCents,
          method: _selectedMethod,
          processedBy: currentUser.id,
        );
      }

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar pago: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.statusReady, size: 28),
            const SizedBox(width: 12),
            Text(
              'Pago Exitoso',
              style: AppTypography.h2(color: AppColors.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Orden', '#${widget.orderId}'),
            const SizedBox(height: AppSpacing.base),
            _buildSummaryRow('Método', _methodLabel(_selectedMethod)),
            const SizedBox(height: AppSpacing.base),
            _buildSummaryRow(
              'Total',
              '\$${(_order?.totalCents ?? 0 / 100).toStringAsFixed(2)}',
            ),
            if (_splitAmounts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.base),
              _buildSummaryRow(
                'División',
                '${_splitAmounts.length} partes',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/cashier/payments');
            },
            child: Text(
              'Volver a Solicitudes',
              style: AppTypography.statusBadge(color: AppColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMd(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
        Text(value,
            style: AppTypography.bodyMd(
                color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }



  String _methodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.qr:
        return 'QR';
      case PaymentMethod.split:
        return 'Dividido';
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
          onPressed: () => context.go('/cashier/payments'),
        ),
        title: Text(
          'Procesar Pago',
          style: AppTypography.h3(color: AppColors.onSurface),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: AppColors.error.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTypography.bodyMd(
                    color: AppColors.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadOrder,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Orden no encontrada',
              style: AppTypography.bodyMd(
                  color: AppColors.outline.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    final order = _order!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary card
              StitchCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mesa ${order.tableId} • Cuenta Detallada',
                            style: AppTypography.h2()),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'PEDIDO #${order.id}',
                            style: AppTypography.labelCaps(
                                color: AppColors.primaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${order.items.length} Comensales | Atendido por: ${order.waiterId}',
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Receipt Card
              StitchCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: const Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: Text('CONCEPTO',
                                  style: AppTypography.labelCaps())),
                          Expanded(
                              flex: 2,
                              child: Text('CANT.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelCaps())),
                          Expanded(
                              flex: 2,
                              child: Text('PRECIO',
                                  textAlign: TextAlign.right,
                                  style: AppTypography.labelCaps())),
                          Expanded(
                              flex: 2,
                              child: Text('TOTAL',
                                  textAlign: TextAlign.right,
                                  style: AppTypography.labelCaps())),
                        ],
                      ),
                    ),
                    // Items
                    ...order.items.map((item) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFFF8FAFC))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Item ${item.menuItemId}',
                                        style: AppTypography.bodyLg(
                                            color: AppColors.onSurface)),
                                    Text(
                                      item.modifierIds.isEmpty
                                          ? ''
                                          : 'Mod: ${item.modifierIds.length}',
                                      style: AppTypography.statusBadge(
                                          color: AppColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyLg(
                                        color: AppColors.onSurface)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    '\$${(item.priceCents / 100).toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.bodyLg(
                                        color: AppColors.onSurface)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    '\$${(item.priceCents * item.quantity / 100).toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: AppTypography.h3(
                                        color: AppColors.onSurface)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Discount / Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionChip(
                        Icons.percent, 'Descuento %', AppColors.primaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionChip(
                        Icons.card_giftcard, 'Cortesia', AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionChip(
                        Icons.edit, 'Modificar', AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Checkout Section
              StitchCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payments,
                            color: AppColors.primaryContainer, size: 24),
                        const SizedBox(width: AppSpacing.base),
                        Text('Finalizar Pago', style: AppTypography.h3()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTotalRow('Subtotal',
                        '\$${(order.subtotalCents / 100).toStringAsFixed(2)}'),
                    const SizedBox(height: AppSpacing.base),
                    _buildTotalRow('IVA (10%)',
                        '\$${(order.taxCents / 100).toStringAsFixed(2)}'),
                    const Divider(
                        height: 24,
                        color: Color(0xFFE2E8F0)),
                    _buildTotalRow(
                      'TOTAL A PAGAR',
                      '\$${(order.totalCents / 100).toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Payment Methods
                    Text('MÉTODO DE PAGO',
                        style: AppTypography.labelCaps()),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 400 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 1.5,
                          children: [
                            _buildMethodCard(PaymentMethod.creditCard,
                                Icons.credit_card, 'Tarjeta'),
                            _buildMethodCard(
                                PaymentMethod.cash, Icons.money, 'Efectivo'),
                            _buildMethodCard(PaymentMethod.split,
                                Icons.call_split, 'Dividir'),
                            _buildMethodCard(
                                PaymentMethod.qr, Icons.qr_code, 'QR / Bizum'),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Options
                    Row(
                      children: [
                        const Icon(Icons.check_box,
                            color: AppColors.primaryContainer, size: 20),
                        const SizedBox(width: AppSpacing.base),
                        Text('Emitir Factura Completa (con CIF)',
                            style: AppTypography.bodyMd(
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.check_box,
                            color: AppColors.primaryContainer, size: 20),
                        const SizedBox(width: AppSpacing.base),
                        Text('Enviar Ticket por Email',
                            style: AppTypography.bodyMd(
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Primary Action
                    StitchPrimaryButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      isLoading: _isProcessing,
                      icon: Icons.receipt_long,
                      label: 'PROCESAR PAGO Y CERRAR',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppTypography.statusBadge(color: color)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color == AppColors.primaryContainer
            ? color
            : const Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.h2(color: AppColors.primaryContainer)
              : AppTypography.bodyLg(color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.h2(color: AppColors.primaryContainer).copyWith(
                  fontWeight: FontWeight.w900)
              : AppTypography.bodyLg(color: AppColors.onSurface),
        ),
      ],
    );
  }

  Widget _buildMethodCard(
      PaymentMethod method, IconData icon, String label) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer
                : const Color(0xFFF1F5F9),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryContainer
                  : const Color(0xFF94A3B8),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.statusBadge(
                color: isSelected
                    ? AppColors.primaryContainer
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/global_additional.dart';
import '../../providers/providers.dart';
import '../../models/order.dart';
import '../../models/order_item.dart' hide OrderStatus;
import '../../models/table.dart';
import '../../models/menu_item.dart';
import '../../models/payment_method.dart';
import '../theme/app_theme.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String initialMode;

  const PaymentProcessingScreen({
    required this.orderId,
    this.initialMode = 'total',
    super.key,
  });

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
  bool _isSplitMode = false;
  Map<String, MenuItem> _menuItems = {};
  List<GlobalAdditional> _availableAdditions = [];
  int _discountAmountCents = 0;
  final Map<String, int> _courtesyItemQuantities = {};

  // Split-by-dishes state
  int _currentDinerNumber = 1;
  final Map<String, int> _paidItemQuantities = {};
  final Map<String, int> _selectedItemQuantities = {};
  final List<Map<String, dynamic>> _dinerPaymentsHistory = [];

  int get _courtesyDiscountCents {
    if (_order == null) return 0;
    return _order!.items.fold<int>(
      0,
      (sum, item) =>
          sum + (item.priceCents * (_courtesyItemQuantities[item.id] ?? 0)),
    );
  }

  int get _totalDiscountCents => _discountAmountCents + _courtesyDiscountCents;

  int get _effectiveOrderSubtotalCents {
    if (_order == null) return 0;
    final net = _order!.subtotalCents - _courtesyDiscountCents;
    return net < 0 ? 0 : net;
  }

  int get _effectiveOrderTaxCents {
    if (_order == null) return 0;
    if (_courtesyDiscountCents >= _order!.subtotalCents && _order!.subtotalCents > 0) return 0;
    return (_effectiveOrderSubtotalCents * 0.15).round();
  }

  int get _finalTotalCents {
    if (_order == null) return 0;
    if (_effectiveOrderSubtotalCents == 0 && _order!.subtotalCents > 0) return 0;
    final total = _effectiveOrderSubtotalCents +
        _effectiveOrderTaxCents -
        _discountAmountCents;
    return total < 0 ? 0 : total;
  }

  int _getUnpaidQuantity(OrderItem item) {
    final paid = _paidItemQuantities[item.id] ?? 0;
    final remaining = item.quantity - paid;
    return remaining < 0 ? 0 : remaining;
  }

  int _getSelectedQuantity(OrderItem item) {
    return _selectedItemQuantities[item.id] ?? 0;
  }

  bool get _hasUnpaidItems {
    if (_order == null) return false;
    return _order!.items.any((item) => _getUnpaidQuantity(item) > 0);
  }

  int get _currentDinerSubtotalCents {
    if (!_isSplitMode) return _effectiveOrderSubtotalCents;
    if (_order == null) return 0;
    return _order!.items.fold<int>(0, (sum, item) {
      final selected = _getSelectedQuantity(item);
      if (selected == 0) return sum;
      final courtesy = _courtesyItemQuantities[item.id] ?? 0;
      final paidSoFar = _paidItemQuantities[item.id] ?? 0;
      final totalNonCourtesy = (item.quantity - courtesy).clamp(0, item.quantity);
      final nonCourtesyRemaining = (totalNonCourtesy - paidSoFar).clamp(0, totalNonCourtesy);
      final chargedForDiner = selected.clamp(0, nonCourtesyRemaining);
      return sum + (item.priceCents * chargedForDiner);
    });
  }

  int get _currentDinerTaxCents {
    if (!_isSplitMode) return _effectiveOrderTaxCents;
    if (_order == null || _currentDinerSubtotalCents == 0) return 0;
    return (_currentDinerSubtotalCents * 0.15).round();
  }

  int get _currentDinerTotalCents {
    if (!_isSplitMode) return _finalTotalCents;
    return _currentDinerSubtotalCents + _currentDinerTaxCents;
  }

  int get _remainingTableTotalCents {
    if (_order == null) return 0;
    final remainingSubtotal = _order!.items.fold<int>(0, (sum, item) {
      final unpaid = _getUnpaidQuantity(item);
      if (unpaid == 0) return sum;
      final courtesy = _courtesyItemQuantities[item.id] ?? 0;
      final paidSoFar = _paidItemQuantities[item.id] ?? 0;
      final totalNonCourtesy = (item.quantity - courtesy).clamp(0, item.quantity);
      final nonCourtesyRemaining = (totalNonCourtesy - paidSoFar).clamp(0, totalNonCourtesy);
      final chargedRemaining = unpaid.clamp(0, nonCourtesyRemaining);
      return sum + (item.priceCents * chargedRemaining);
    });
    final remainingTax = (remainingSubtotal * 0.15).round();
    return remainingSubtotal + remainingTax;
  }

  void _incrementItemSelection(OrderItem item) {
    final available = _getUnpaidQuantity(item);
    final current = _getSelectedQuantity(item);
    if (current < available) {
      setState(() {
        _selectedItemQuantities[item.id] = current + 1;
      });
    }
  }

  void _decrementItemSelection(OrderItem item) {
    final current = _getSelectedQuantity(item);
    if (current > 0) {
      setState(() {
        if (current == 1) {
          _selectedItemQuantities.remove(item.id);
        } else {
          _selectedItemQuantities[item.id] = current - 1;
        }
      });
    }
  }

  void _selectAllRemainingItems() {
    if (_order == null) return;
    setState(() {
      for (final item in _order!.items) {
        final remaining = _getUnpaidQuantity(item);
        if (remaining > 0) {
          _selectedItemQuantities[item.id] = remaining;
        } else {
          _selectedItemQuantities.remove(item.id);
        }
      }
    });
  }

  void _clearSelectedItems() {
    setState(() {
      _selectedItemQuantities.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _isSplitMode = widget.initialMode == 'split';
    if (_isSplitMode) {
      _selectedMethod = PaymentMethod.split;
    }
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderService = ref.read(orderServiceProvider);
      final menuService = ref.read(menuServiceProvider);
      final additionalService = ref.read(additionalServiceProvider);
      final order = await orderService.getOrder(widget.orderId);

      Map<String, MenuItem> menuItemsMap = {};
      try {
        final menuItems = await menuService.fetchMenu();
        menuItemsMap = {for (var item in menuItems) item.id: item};
      } catch (_) {}

      List<GlobalAdditional> additions = [];
      try {
        additions = await additionalService.fetchAdditions(
          onlyAvailable: true,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _order = order;
        _menuItems = menuItemsMap;
        _availableAdditions = additions;
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

  void _showAddAdditionalDialog() {
    final order = _order;
    if (order == null || order.status == OrderStatus.closed) return;
    if (_availableAdditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay adicionales globales disponibles para cobrar.'),
        ),
      );
      return;
    }

    var selectedAdditionalId = _availableAdditions.first.id;
    var quantity = 1;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedAdditional = _availableAdditions.firstWhere(
            (addition) => addition.id == selectedAdditionalId,
          );
          return AlertDialog(
            title: const Text('Añadir adicional a la cuenta'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Caja usa el catálogo global; el precio se valida antes de cobrar.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAdditionalId,
                    decoration: const InputDecoration(labelText: 'Adicional'),
                    items: _availableAdditions
                        .map(
                          (addition) => DropdownMenuItem(
                            value: addition.id,
                            child: Text(
                              '${addition.name} · ${(addition.priceCents / 100).toStringAsFixed(2)} €',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (additionalId) {
                      if (additionalId != null) {
                        setDialogState(
                          () => selectedAdditionalId = additionalId,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Cantidad'),
                      const Spacer(),
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setDialogState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: () => setDialogState(() => quantity++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    'Total adicional: ${((selectedAdditional.priceCents * quantity) / 100).toStringAsFixed(2)} €',
                    textAlign: TextAlign.right,
                    style: AppTypography.h3(color: AppColors.primaryContainer),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => _addCashierAdditional(
                  dialogContext,
                  selectedAdditional,
                  quantity,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Añadir y cobrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCashierAdditional(
    BuildContext dialogContext,
    GlobalAdditional additional,
    int quantity,
  ) async {
    final order = _order;
    final cashier = ref.read(currentUserProvider).value;
    if (order == null || cashier == null) return;

    try {
      final updated = await ref
          .read(orderServiceProvider)
          .addCashierAdditional(
            orderId: order.id,
            additionalId: additional.id,
            quantity: quantity,
            byUserId: cashier.id,
          );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _discountAmountCents = 0;
      });
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${additional.name} añadido a la cuenta')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo añadir el adicional: $error')),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (_order == null || _isProcessing) return;

    // Guard — no procesar si ya está cerrado
    if (_order!.status == OrderStatus.closed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este pedido ya fue procesado y cerrado.'),
        ),
      );
      return;
    }

    if (_isSplitMode && (_selectedItemQuantities.isEmpty || _selectedItemQuantities.values.every((q) => q == 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos 1 plato para este comensal.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final orderService = ref.read(orderServiceProvider);
      final tableService = ref.read(tableServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
        setState(() => _isProcessing = false);
        return;
      }

      if (!_isSplitMode) {
        if (_finalTotalCents == 0 && _totalDiscountCents == 0 && _order!.totalCents > 0) {
          throw Exception(
            'El total a pagar no puede ser 0 a menos que sea una cortesía o descuento del 100%.',
          );
        }

        await paymentService.processPayment(
          orderId: widget.orderId,
          amountCents: _finalTotalCents,
          method: _selectedMethod == PaymentMethod.split
              ? PaymentMethod.cash
              : _selectedMethod,
          processedBy: currentUser.id,
        );

        if (_order!.status != OrderStatus.billed) {
          await orderService.updateStatus(
            orderId: widget.orderId,
            status: OrderStatus.billed,
            byUserId: currentUser.id,
          );
        }
        await orderService.updateStatus(
          orderId: widget.orderId,
          status: OrderStatus.closed,
          byUserId: currentUser.id,
        );

        if (_order!.tableId.isNotEmpty) {
          try {
            await tableService.updateTableStatus(
              _order!.tableId,
              TableStatus.available,
            );
          } catch (_) {}
        }

        if (!mounted) return;
        _showSuccessDialog();
      } else {
        // Modalidad Cuenta Separada (Cobro de platos seleccionados por este comensal)
        final effectiveMethod = _selectedMethod == PaymentMethod.split
            ? PaymentMethod.cash
            : _selectedMethod;

        final txn = await paymentService.processPayment(
          orderId: widget.orderId,
          amountCents: _currentDinerTotalCents,
          method: effectiveMethod,
          processedBy: currentUser.id,
        );

        final selectedSummary = _order!.items
            .where((item) => _getSelectedQuantity(item) > 0)
            .map((item) {
              final name = item.name ??
                  _menuItems[item.menuItemId]?.name ??
                  'Item ${item.menuItemId}';
              return '${_getSelectedQuantity(item)}x $name';
            })
            .toList();

        final currentDiner = _currentDinerNumber;
        final currentAmount = _currentDinerTotalCents;

        _dinerPaymentsHistory.add({
          'diner': 'Comensal $currentDiner',
          'amountCents': currentAmount,
          'method': effectiveMethod,
          'items': selectedSummary,
          'transactionId': txn.id,
        });

        for (final entry in _selectedItemQuantities.entries) {
          _paidItemQuantities[entry.key] =
              (_paidItemQuantities[entry.key] ?? 0) + entry.value;
        }
        _selectedItemQuantities.clear();

        if (!_hasUnpaidItems) {
          // Todos los platos de la orden fueron liquidados
          if (_order!.status != OrderStatus.billed) {
            await orderService.updateStatus(
              orderId: widget.orderId,
              status: OrderStatus.billed,
              byUserId: currentUser.id,
            );
          }
          await orderService.updateStatus(
            orderId: widget.orderId,
            status: OrderStatus.closed,
            byUserId: currentUser.id,
          );

          if (_order!.tableId.isNotEmpty) {
            try {
              await tableService.updateTableStatus(
                _order!.tableId,
                TableStatus.available,
              );
            } catch (_) {}
          }

          if (!mounted) return;
          _showSuccessDialog();
        } else {
          // Quedan platos pendientes para el siguiente comensal
          if (!mounted) return;
          setState(() {
            _currentDinerNumber++;
            _selectedMethod = PaymentMethod.cash;
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Pago de Comensal $currentDiner registrado (\$${(currentAmount / 100).toStringAsFixed(2)}). Seleccione los platos del Comensal $_currentDinerNumber.',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
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
            const Icon(
              Icons.check_circle,
              color: AppColors.statusReady,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Pago Exitoso',
              style: AppTypography.h2(color: AppColors.onSurface),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Orden', '#${widget.orderId}'),
              const SizedBox(height: AppSpacing.base),
              _buildSummaryRow(
                'Modalidad',
                _isSplitMode ? 'Cuenta Separada' : 'Cuenta Total',
              ),
              const SizedBox(height: AppSpacing.base),
              if (_isSplitMode && _dinerPaymentsHistory.isNotEmpty) ...[
                _buildSummaryRow(
                  'Comensales',
                  '${_dinerPaymentsHistory.length} comensales pagaron',
                ),
                const SizedBox(height: AppSpacing.base),
                const Divider(height: 16),
                Text(
                  'Desglose de pagos:',
                  style: AppTypography.statusBadge(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                ..._dinerPaymentsHistory.map((p) {
                  final dinerName = p['diner'] as String;
                  final amount = p['amountCents'] as int;
                  final method = p['method'] as PaymentMethod;
                  final items = (p['items'] as List<String>).join(', ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dinerName,
                              style: AppTypography.bodyMd(
                                color: AppColors.onSurface,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${(amount / 100).toStringAsFixed(2)} · ${_methodLabel(method)}',
                              style: AppTypography.bodyMd(
                                color: AppColors.primaryContainer,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (items.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            items,
                            style: AppTypography.statusBadge(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),
              ] else ...[
                _buildSummaryRow('Método', _methodLabel(_selectedMethod)),
                const SizedBox(height: AppSpacing.base),
              ],
              _buildSummaryRow(
                'Total Liquidado',
                '\$${(_finalTotalCents / 100).toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/cashier/pending');
            },
            child: Text(
              'Volver a Solicitudes',
              style: AppTypography.statusBadge(
                color: AppColors.primaryContainer,
              ),
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
        Text(
          label,
          style: AppTypography.bodyMd(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMd(
            color: AppColors.onSurface,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
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
          onPressed: () => context.go('/cashier/pending'),
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTypography.bodyMd(
                  color: AppColors.onSurface.withValues(alpha: 0.7),
                ),
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
                color: AppColors.outline.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final order = _order!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mesa ${order.tableId}',
                                style: AppTypography.h2(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cuenta Detallada',
                                style: AppTypography.h3(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            'PEDIDO #${order.id}',
                            style: AppTypography.labelCaps(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${order.items.length} Comensales | Atendido por: ${order.waiterId}',
                      style: AppTypography.bodyMd(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Receipt Card
              // Mode Banner if in Split Mode
              if (_isSplitMode) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comensal #$_currentDinerNumber',
                                    style: AppTypography.h3(
                                      color: AppColors.primaryContainer,
                                    ),
                                  ),
                                  Text(
                                    'Selecciona los platos que pagará este comensal',
                                    style: AppTypography.statusBadge(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('selectAllRemainingButton'),
                            onPressed: _selectAllRemainingItems,
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Todos los restantes'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              foregroundColor: AppColors.primaryContainer,
                              side: const BorderSide(
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                          if (_selectedItemQuantities.isNotEmpty)
                            IconButton(
                              key: const Key('clearSelectionButton'),
                              tooltip: 'Limpiar selección',
                              onPressed: _clearSelectedItems,
                              icon: const Icon(Icons.clear, size: 18),
                              color: AppColors.error,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              // Receipt Card
              StitchCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'CONCEPTO',
                              style: AppTypography.labelCaps(),
                            ),
                          ),
                          Expanded(
                            flex: _isSplitMode ? 3 : 2,
                            child: Text(
                              _isSplitMode ? 'SELECCIÓN' : 'CANT.',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelCaps(),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'PRECIO',
                              textAlign: TextAlign.right,
                              style: AppTypography.labelCaps(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Items
                    ...order.items.map((item) {
                      final unpaid = _getUnpaidQuantity(item);
                      final selected = _getSelectedQuantity(item);
                      final isPaidOut = unpaid == 0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isPaidOut
                              ? const Color(0xFFF8FAFC)
                              : (_isSplitMode && selected > 0
                                  ? AppColors.primaryFixed.withValues(alpha: 0.1)
                                  : Colors.white),
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFF8FAFC)),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Concepto & Status
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name ??
                                        _menuItems[item.menuItemId]?.name ??
                                        'Item ${item.menuItemId}',
                                    style: AppTypography.bodyLg(
                                      color: isPaidOut
                                          ? AppColors.onSurfaceVariant
                                          : AppColors.onSurface,
                                    ).copyWith(
                                      decoration: isPaidOut
                                          ? TextDecoration.lineThrough
                                          : null,
                                      fontWeight: selected > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if ((_courtesyItemQuantities[item.id] ?? 0) > 0)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xs,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                      child: Text(
                                        '🎁 Cortesía: ${_courtesyItemQuantities[item.id]} de ${item.quantity} (\$0.00)',
                                        style: AppTypography.statusBadge(
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ),
                                  if (isPaidOut)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.xs,
                                        ),
                                      ),
                                      child: Text(
                                        '✓ Pagado completo (${item.quantity} de ${item.quantity})',
                                        style: AppTypography.statusBadge(
                                          color: const Color(0xFF15803D),
                                        ),
                                      ),
                                    )
                                  else if (_isSplitMode)
                                    Text(
                                      '$selected de $unpaid disponible(s)${item.quantity > unpaid ? ' · ${item.quantity - unpaid} pagado(s)' : ''}',
                                      style: AppTypography.statusBadge(
                                        color: selected > 0
                                            ? AppColors.primaryContainer
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    )
                                  else if (item.modifierIds.isNotEmpty)
                                    Text(
                                      'Mod: ${item.modifierIds.length}',
                                      style: AppTypography.statusBadge(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Selection / Quantity
                            Expanded(
                              flex: _isSplitMode ? 3 : 2,
                              child: _isSplitMode
                                  ? (isPaidOut
                                      ? const Center(
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF10B981),
                                            size: 20,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              key: Key(
                                                'decrementItem_${item.id}',
                                              ),
                                              iconSize: 22,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              color: selected > 0
                                                  ? AppColors.primaryContainer
                                                  : const Color(0xFFCBD5E1),
                                              onPressed: selected > 0
                                                  ? () => _decrementItemSelection(
                                                      item,
                                                    )
                                                  : null,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                              child: Text(
                                                '$selected',
                                                style: AppTypography.h3(
                                                  color: selected > 0
                                                      ? AppColors
                                                          .primaryContainer
                                                      : AppColors.onSurface,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              key: Key(
                                                'incrementItem_${item.id}',
                                              ),
                                              iconSize: 22,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              color: selected < unpaid
                                                  ? AppColors.primaryContainer
                                                  : const Color(0xFFCBD5E1),
                                              onPressed: selected < unpaid
                                                  ? () => _incrementItemSelection(
                                                      item,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ))
                                  : Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyLg(
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                            ),
                            // Price
                            Expanded(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: _isSplitMode
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '\$${((item.priceCents * (selected > 0 ? selected : 1)) / 100).toStringAsFixed(2)}',
                                            textAlign: TextAlign.right,
                                            style: AppTypography.bodyLg(
                                              color: selected > 0
                                                  ? AppColors.primaryContainer
                                                  : AppColors.onSurfaceVariant,
                                            ).copyWith(
                                              fontWeight: selected > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (selected == 0)
                                            Text(
                                              'c/u',
                                              style: AppTypography.statusBadge(
                                                color: AppColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      )
                                    : Text(
                                        '\$${((item.priceCents * item.quantity) / 100).toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                        style: AppTypography.bodyLg(
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              if (_isSplitMode && _dinerPaymentsHistory.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                StitchCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: AppColors.primaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pagos Realizados en Esta Mesa',
                            style: AppTypography.h3(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._dinerPaymentsHistory.map((p) {
                        final diner = p['diner'] as String;
                        final amount = p['amountCents'] as int;
                        final method = p['method'] as PaymentMethod;
                        final items = (p['items'] as List<String>).join(', ');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$diner · ${_methodLabel(method)}',
                                      style: AppTypography.bodyMd(
                                        color: AppColors.onSurface,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (items.isNotEmpty)
                                      Text(
                                        items,
                                        style: AppTypography.statusBadge(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(amount / 100).toStringAsFixed(2)}',
                                style: AppTypography.h3(
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Discount / Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionChip(
                      Icons.percent,
                      'Descuento',
                      AppColors.primaryContainer,
                      _showDiscountDialog,
                      key: const Key('openDiscountDialogButton'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionChip(
                      Icons.card_giftcard,
                      'Cortesia',
                      AppColors.onSurfaceVariant,
                      _showCortesiaDialog,
                      key: const Key('openCortesiaDialogButton'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildActionChip(
                      Icons.edit,
                      'Añadir adicional',
                      AppColors.onSurfaceVariant,
                      _showAddAdditionalDialog,
                    ),
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
                        Icon(
                          Icons.payments,
                          color: AppColors.primaryContainer,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.base),
                        Text(
                          _isSplitMode
                              ? 'Cobro Comensal #$_currentDinerNumber'
                              : 'Finalizar Pago',
                          style: AppTypography.h3(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!_isSplitMode) ...[
                      _buildTotalRow(
                        'Subtotal',
                        '\$${(order.subtotalCents / 100).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _buildTotalRow(
                        'IVA (15%)',
                        '\$${(_effectiveOrderTaxCents / 100).toStringAsFixed(2)}',
                      ),
                      if (_courtesyDiscountCents > 0) ...[
                        const SizedBox(height: AppSpacing.base),
                        _buildTotalRow(
                          'Cortesía (Platos \$0.00)',
                          '-\$${(_courtesyDiscountCents / 100).toStringAsFixed(2)}',
                          isDiscount: true,
                        ),
                      ],
                      if (_discountAmountCents > 0) ...[
                        const SizedBox(height: AppSpacing.base),
                        _buildTotalRow(
                          'Descuento General',
                          '-\$${(_discountAmountCents / 100).toStringAsFixed(2)}',
                          isDiscount: true,
                        ),
                      ],
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _buildTotalRow(
                        'TOTAL A PAGAR',
                        '\$${(_finalTotalCents / 100).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ] else ...[
                      _buildTotalRow(
                        'Subtotal Comensal #$_currentDinerNumber',
                        '\$${(_currentDinerSubtotalCents / 100).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _buildTotalRow(
                        'IVA Comensal (15%)',
                        '\$${(_currentDinerTaxCents / 100).toStringAsFixed(2)}',
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),
                      _buildTotalRow(
                        'TOTAL COMENSAL #$_currentDinerNumber',
                        '\$${(_currentDinerTotalCents / 100).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saldo Restante en Mesa:',
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '\$${(_remainingTableTotalCents / 100).toStringAsFixed(2)}',
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurface,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    // Modalidad de Cobro (Cuenta Total vs Cuenta Separada)
                    Text('MODALIDAD DE COBRO', style: AppTypography.labelCaps()),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            key: const Key('modeTotalButton'),
                            onTap: () {
                              setState(() {
                                _isSplitMode = false;
                                if (_selectedMethod == PaymentMethod.split) {
                                  _selectedMethod = PaymentMethod.cash;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: !_isSplitMode
                                    ? AppColors.primaryContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: !_isSplitMode
                                      ? AppColors.primaryContainer
                                      : const Color(0xFFE2E8F0),
                                  width: !_isSplitMode ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 18,
                                    color: !_isSplitMode
                                        ? Colors.white
                                        : AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cuenta Total',
                                    style: AppTypography.bodyMd(
                                      color: !_isSplitMode
                                          ? Colors.white
                                          : AppColors.onSurface,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: InkWell(
                            key: const Key('modeSplitButton'),
                            onTap: () {
                              setState(() {
                                _isSplitMode = true;
                                _selectedMethod = PaymentMethod.cash;
                              });
                            },
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _isSplitMode
                                    ? AppColors.primaryContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: _isSplitMode
                                      ? AppColors.primaryContainer
                                      : const Color(0xFFE2E8F0),
                                  width: _isSplitMode ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call_split,
                                    size: 18,
                                    color: _isSplitMode
                                        ? Colors.white
                                        : AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cuenta Separada',
                                    style: AppTypography.bodyMd(
                                      color: _isSplitMode
                                          ? Colors.white
                                          : AppColors.onSurface,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Payment Methods
                    Text(
                      _isSplitMode
                          ? 'MÉTODO DE PAGO (COMENSAL #$_currentDinerNumber)'
                          : 'MÉTODO DE PAGO',
                      style: AppTypography.labelCaps(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 400
                            ? 4
                            : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 1.5,
                          children: [
                            _buildMethodCard(
                              PaymentMethod.creditCard,
                              Icons.credit_card,
                              'Tarjeta',
                            ),
                            _buildMethodCard(
                              PaymentMethod.cash,
                              Icons.money,
                              'Efectivo',
                            ),
                            _buildMethodCard(
                              PaymentMethod.split,
                              Icons.call_split,
                              'Dividir',
                              key: const Key('splitPaymentButton'),
                            ),
                            _buildMethodCard(
                              PaymentMethod.qr,
                              Icons.qr_code,
                              'QR / Bizum',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Options
                    Row(
                      children: [
                        const Icon(
                          Icons.check_box,
                          color: AppColors.primaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.base),
                        Text(
                          'Emitir Factura Completa (con CIF)',
                          style: AppTypography.bodyMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_box,
                          color: AppColors.primaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.base),
                        Text(
                          'Enviar Ticket por Email',
                          style: AppTypography.bodyMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Primary Action
                    StitchPrimaryButton(
                      key: const Key('processPaymentButton'),
                      onPressed: (_isProcessing ||
                              (_isSplitMode && _currentDinerTotalCents == 0))
                          ? null
                          : _processPayment,
                      isLoading: _isProcessing,
                      icon: _isSplitMode
                          ? Icons.call_split
                          : Icons.receipt_long,
                      label: _isSplitMode
                          ? (_currentDinerTotalCents == 0
                              ? 'SELECCIONA PLATOS (COMENSAL #$_currentDinerNumber)'
                              : (_remainingTableTotalCents -
                                          _currentDinerTotalCents <=
                                      0
                                  ? 'COBRAR COMENSAL #$_currentDinerNumber (\$${(_currentDinerTotalCents / 100).toStringAsFixed(2)}) Y CERRAR'
                                  : 'COBRAR COMENSAL #$_currentDinerNumber (\$${(_currentDinerTotalCents / 100).toStringAsFixed(2)}) Y SIGUIENTE'))
                          : 'COBRAR CUENTA TOTAL',
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

  Widget _buildActionChip(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    Key? key,
  }) {
    return OutlinedButton.icon(
      key: key,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppTypography.statusBadge(color: color)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color == AppColors.primaryContainer
              ? color
              : const Color(0xFFE2E8F0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.h2(color: AppColors.primaryContainer)
              : AppTypography.bodyLg(
                  color: isDiscount
                      ? AppColors.error
                      : AppColors.onSurfaceVariant,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.h2(
                  color: AppColors.primaryContainer,
                ).copyWith(fontWeight: FontWeight.w900)
              : AppTypography.bodyLg(
                  color: isDiscount ? AppColors.error : AppColors.onSurface,
                ),
        ),
      ],
    );
  }

  void _showCortesiaDialog() {
    if (_order == null || _order!.items.isEmpty) return;

    final tempCourtesy = Map<String, int>.from(_courtesyItemQuantities);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          int calcTempDiscount() {
            return _order!.items.fold<int>(
              0,
              (sum, item) =>
                  sum + (item.priceCents * (tempCourtesy[item.id] ?? 0)),
            );
          }

          final currentDiscount = calcTempDiscount();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppColors.primaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platos de Cortesía',
                        style: AppTypography.h3(),
                      ),
                      Text(
                        'Asigna valor \$0.00 a platos específicos o a la orden completa',
                        style: AppTypography.bodyMd(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('allOrderCourtesyButton'),
                            onPressed: () {
                              setDialogState(() {
                                for (final item in _order!.items) {
                                  tempCourtesy[item.id] = item.quantity;
                                }
                              });
                            },
                            icon: const Icon(Icons.all_inclusive, size: 16),
                            label: const Text('Toda la orden (\$0)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryContainer,
                              side: const BorderSide(
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('clearCourtesyButton'),
                            onPressed: () {
                              setDialogState(() {
                                tempCourtesy.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Limpiar cortesías'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    ..._order!.items.map((item) {
                      final itemCourtesy = tempCourtesy[item.id] ?? 0;
                      final isCourtesy = itemCourtesy > 0;
                      final name = item.name ??
                          _menuItems[item.menuItemId]?.name ??
                          'Item ${item.menuItemId}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isCourtesy
                              ? const Color(0xFFFEF3C7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isCourtesy
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: AppTypography.bodyMd(
                                      color: AppColors.onSurface,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} pedida(s) · \$${(item.priceCents / 100).toStringAsFixed(2)} c/u',
                                    style: AppTypography.bodyMd(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isCourtesy)
                                    Text(
                                      'Cortesía: ${itemCourtesy}x (Valor: \$0.00)',
                                      style: AppTypography.statusBadge(
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: Key('decrementCourtesy_${item.id}'),
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: itemCourtesy > 0
                                        ? () {
                                            setDialogState(() {
                                              if (itemCourtesy == 1) {
                                                tempCourtesy.remove(item.id);
                                              } else {
                                                tempCourtesy[item.id] =
                                                    itemCourtesy - 1;
                                              }
                                            });
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '$itemCourtesy',
                                    style: AppTypography.bodyLg(
                                      color: AppColors.onSurface,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    key: Key('incrementCourtesy_${item.id}'),
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: itemCourtesy < item.quantity
                                        ? () {
                                            setDialogState(() {
                                              tempCourtesy[item.id] =
                                                  itemCourtesy + 1;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Descuento por Cortesía:',
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '-\$${(currentDiscount / 100).toStringAsFixed(2)}',
                            style: AppTypography.h3(
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('applyCourtesyConfirmButton'),
                onPressed: () {
                  setState(() {
                    _courtesyItemQuantities.clear();
                    _courtesyItemQuantities.addAll(tempCourtesy);
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Aplicar Cortesía'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDiscountDialog() {
    if (_order == null) return;
    final controller = TextEditingController(
      text: _discountAmountCents > 0
          ? (_discountAmountCents / 100).toStringAsFixed(2)
          : '',
    );
    bool isPercentage = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Icon(
                  Icons.percent,
                  color: AppColors.primaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Aplicar Descuento', style: AppTypography.h3()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text(
                        'Monto (\$)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      selected: !isPercentage,
                      onSelected: (_) => setStateDialog(() {
                        isPercentage = false;
                        errorMessage = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text(
                        'Porcentaje (%)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      selected: isPercentage,
                      onSelected: (_) => setStateDialog(() {
                        isPercentage = true;
                        errorMessage = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('discountValueInput'),
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: isPercentage
                      ? 'Porcentaje (0-100%)'
                      : 'Monto de Descuento (\$)',
                  prefixText: isPercentage ? '' : '\$ ',
                  suffixText: isPercentage ? '%' : '',
                  errorText: errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                onChanged: (_) {
                  if (errorMessage != null) {
                    setStateDialog(() => errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Solo valores numéricos positivos. No se permiten caracteres especiales ni negativos.',
                style: AppTypography.bodyMd(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            if (_discountAmountCents > 0)
              TextButton(
                onPressed: () {
                  setState(() => _discountAmountCents = 0);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Quitar Descuento',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              key: const Key('applyDiscountConfirmButton'),
              onPressed: () {
                final text = controller.text.trim();
                final val = double.tryParse(text);
                if (val == null || val < 0) {
                  setStateDialog(() {
                    errorMessage = 'Ingresa un número positivo válido';
                  });
                  return;
                }
                if (isPercentage && val > 100) {
                  setStateDialog(() {
                    errorMessage = 'El porcentaje no puede superar 100%';
                  });
                  return;
                }

                final maxAllowedCents =
                    _effectiveOrderSubtotalCents + _effectiveOrderTaxCents;
                int calculatedDiscount = 0;
                if (isPercentage) {
                  calculatedDiscount =
                      ((_order!.totalCents * val) / 100).round();
                } else {
                  calculatedDiscount = (val * 100).round();
                }

                if (calculatedDiscount > maxAllowedCents) {
                  calculatedDiscount = maxAllowedCents;
                }

                setState(() {
                  _discountAmountCents = calculatedDiscount;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    PaymentMethod method,
    IconData icon,
    String label, {
    Key? key,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      key: key,
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryFixed : Colors.white,
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

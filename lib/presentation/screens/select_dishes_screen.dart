import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import '../theme/app_theme.dart';

class SelectDishesScreen extends ConsumerStatefulWidget {
  final String orderId;

  const SelectDishesScreen({required this.orderId, super.key});

  @override
  ConsumerState<SelectDishesScreen> createState() =>
      _SelectDishesScreenState();
}

class _SelectDishesScreenState extends ConsumerState<SelectDishesScreen> {
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  final Map<String, int> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final menuService = ref.read(menuServiceProvider);
      final menu = await menuService.fetchMenu();
      setState(() {
        _menuItems = menu.where((item) => item.available).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToOrder(MenuItem item) async {
    final quantity = _selectedQuantities[item.id] ?? 1;
    final orderService = ref.read(orderServiceProvider);
    final currentUser = ref.read(currentUserProvider).value;
    final auditService = ref.read(auditServiceProvider);

    if (currentUser == null) return;

    final orderItem = order_item.OrderItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      menuItemId: item.id,
      quantity: quantity,
      priceCents: item.priceCents,
      status: order_item.OrderStatus.pending,
      modifierIds: [],
    );

    try {
      await orderService.addItem(
        orderId: widget.orderId,
        item: orderItem,
      );
      await auditService.record(
        action: 'add_item',
        userId: currentUser.id,
        metadata: {
          'orderId': widget.orderId,
          'itemId': item.id,
          'quantity': quantity,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} añadido')),
        );
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/menu');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        title: Text(
          'Seleccionar Platos',
          style: AppTypography.h3(color: AppColors.onSurface),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
              ? const Center(child: Text('No hay platos disponibles'))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _menuItems.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, idx) {
                    final item = _menuItems[idx];
                    final qty = _selectedQuantities[item.id] ?? 1;
                    return StitchCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTypography.bodyMd(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${(item.priceCents / 100).toStringAsFixed(2)}',
                                  style: AppTypography.bodyMd(
                                      color: AppColors.primaryContainer,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (item.modifiers.isNotEmpty)
                                  Text(
                                    '+${item.modifiers.length} opciones',
                                    style: AppTypography.statusBadge(
                                        color: AppColors.outline),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: qty > 1
                                    ? () => setState(() =>
                                        _selectedQuantities[item.id] = qty - 1)
                                    : null,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: qty > 1
                                        ? AppColors.primaryContainer
                                        : AppColors.surfaceContainer,
                                  ),
                                  child: Icon(Icons.remove,
                                      size: 18,
                                      color: qty > 1
                                          ? Colors.white
                                          : AppColors.outline),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text(
                                  '$qty',
                                  style: AppTypography.h3(
                                      color: AppColors.onSurface),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _selectedQuantities[item.id] = qty + 1),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryContainer,
                                  ),
                                  child: const Icon(Icons.add,
                                      size: 18, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.base),
                              ElevatedButton(
                                onPressed: () => _addToOrder(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.xl),
                                  ),
                                ),
                                child: const Text('Añadir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}


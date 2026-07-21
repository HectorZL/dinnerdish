import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/global_additional.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/models/table.dart' as table_model;
import '../theme/app_theme.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  final String? existingOrderId;
  const CreateOrderScreen({this.existingOrderId, super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  int _selectedCategoryIndex = 0;
  List<String> _categories = ['Todos'];

  Order? _currentOrder;
  List<MenuItem> _menuItems = [];
  List<GlobalAdditional> _availableAdditions = [];
  final Map<String, int> _selectedQuantities = {};
  final Map<String, int> _selectedAdditionalQuantities = {};
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // F2-03: Cancelar borrador huérfano si el usuario sale sin enviar
    _cancelOrphanDraftIfNeeded();
    super.dispose();
  }

  void _cancelOrphanDraftIfNeeded() {
    // Solo cancelar si el borrador existe y no fue enviado a cocina
    final order = _currentOrder;
    if (order != null &&
        order.status == OrderStatus.draft &&
        widget.existingOrderId == null) {
      // Cancelar de forma fire-and-forget (no await en dispose)
      try {
        ref
            .read(orderServiceProvider)
            .updateStatus(
              orderId: order.id,
              status: OrderStatus.closed,
              byUserId: order.waiterId,
            );
      } catch (_) {
        // Ignorar errores al limpiar borradores
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final menuService = ref.read(menuServiceProvider);
      final menu = await menuService.fetchMenu();
      final additions = await ref
          .read(additionalServiceProvider)
          .fetchAdditions();

      final currentUser = ref.read(currentUserProvider).value;
      Order? order;
      final orderService = ref.read(orderServiceProvider);

      if (widget.existingOrderId != null) {
        order = await orderService.getOrder(widget.existingOrderId!);
        if (order != null) {
          for (var item in order.items) {
            final additionalId = globalAdditionalIdFromMenuItemId(
              item.menuItemId,
            );
            if (additionalId != null) {
              _selectedAdditionalQuantities[additionalId] =
                  (_selectedAdditionalQuantities[additionalId] ?? 0) +
                  item.quantity;
              continue;
            }
            final key = _selectionKey(
              item.menuItemId,
              variationId: item.variationId,
              modifierIds: item.modifierIds,
            );
            _selectedQuantities[key] =
                (_selectedQuantities[key] ?? 0) + item.quantity;
          }
        }
      } else if (currentUser != null) {
        order = await orderService.createDraft(waiterId: currentUser.id);
      }

      setState(() {
        _menuItems = menu;
        _availableAdditions = additions;
        // Extraer categorías dinámicamente
        final dynamicCategories = menu.map((e) => e.category).toSet().toList()
          ..sort();
        _categories = ['Todos', ...dynamicCategories];

        _currentOrder = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  int get _totalSelectedItems {
    final dishes = _selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
    final additions = _selectedAdditionalQuantities.values.fold(
      0,
      (sum, qty) => sum + qty,
    );
    return dishes + additions;
  }

  int get _totalSelectedCents {
    var total = 0;
    for (final entry in _selectedQuantities.entries) {
      if (entry.value <= 0) continue;
      final selection = _parseSelectionKey(entry.key);
      final item = _menuItems.firstWhere(
        (menuItem) => menuItem.id == selection.menuItemId,
      );
      final basePrice = selection.variationId == null
          ? item.priceCents
          : item.variations
                .firstWhere(
                  (variation) => variation.id == selection.variationId,
                )
                .priceCents;
      final modifiersPrice = item.modifiers
          .where((modifier) => selection.modifierIds.contains(modifier.id))
          .fold<int>(0, (sum, modifier) => sum + modifier.priceCents);
      total += (basePrice + modifiersPrice) * entry.value;
    }
    for (final entry in _selectedAdditionalQuantities.entries) {
      if (entry.value <= 0) continue;
      final additional = _additionById(entry.key);
      if (additional != null) {
        total += additional.priceCents * entry.value;
      }
    }
    return total;
  }

  GlobalAdditional? _additionById(String id) {
    for (final additional in _availableAdditions) {
      if (additional.id == id) return additional;
    }
    return null;
  }

  String _selectionKey(
    String menuItemId, {
    String? variationId,
    Iterable<String> modifierIds = const [],
  }) {
    final modifiers = modifierIds.toList()..sort();
    return '$menuItemId|${variationId ?? ''}|${modifiers.join(',')}';
  }

  _OrderSelection _parseSelectionKey(String key) {
    final parts = key.split('|');
    if (parts.length == 3) {
      return _OrderSelection(
        menuItemId: parts[0],
        variationId: parts[1].isEmpty ? null : parts[1],
        modifierIds: parts[2].isEmpty ? const [] : parts[2].split(','),
      );
    }
    final legacyParts = key.split('_');
    return _OrderSelection(
      menuItemId: legacyParts.first,
      variationId: legacyParts.length > 1 ? legacyParts[1] : null,
      modifierIds: const [],
    );
  }

  Future<void> _sendToKitchen(String tableId) async {
    if (_currentOrder == null) return;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    // F2-01: Validar mesa antes de enviar
    if (tableId.trim().isEmpty && widget.existingOrderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona una mesa antes de enviar el pedido.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final orderService = ref.read(orderServiceProvider);

      // Update Table
      if (tableId.isNotEmpty) {
        if (tableId != _currentOrder!.tableId) {
          await orderService.updateTable(
            orderId: _currentOrder!.id,
            tableId: tableId,
          );
        }
        await ref
            .read(tableServiceProvider)
            .updateTableStatus(tableId, table_model.TableStatus.occupied);
      }

      // Calculate differences instead of clearing all items
      final existingItemsByKey = <String, List<order_item.OrderItem>>{};
      if (widget.existingOrderId != null) {
        for (var existing in _currentOrder!.items) {
          if (isGlobalAdditionalLine(existing.menuItemId)) continue;
          final key = _selectionKey(
            existing.menuItemId,
            variationId: existing.variationId,
            modifierIds: existing.modifierIds,
          );
          existingItemsByKey.putIfAbsent(key, () => []).add(existing);
        }
      }

      final allKeys = _selectedQuantities.keys.toSet().union(
        existingItemsByKey.keys.toSet(),
      );
      for (final key in allKeys) {
        final desiredQty = _selectedQuantities[key] ?? 0;
        final existingItems = existingItemsByKey[key] ?? [];
        final existingQty = existingItems.fold(
          0,
          (sum, item) => sum + item.quantity,
        );
        final diff = desiredQty - existingQty;

        if (diff > 0) {
          final selection = _parseSelectionKey(key);
          final item = _menuItems.firstWhere(
            (menuItem) => menuItem.id == selection.menuItemId,
          );
          final selectedModifiers = item.modifiers
              .where((modifier) => selection.modifierIds.contains(modifier.id))
              .toList();

          String displayName = item.name;
          int priceCents = item.priceCents;
          if (selection.variationId != null) {
            final variation = item.variations.firstWhere(
              (value) => value.id == selection.variationId,
            );
            displayName = '${item.name} (${variation.name})';
            priceCents = variation.priceCents;
          }
          if (selectedModifiers.isNotEmpty) {
            displayName =
                '$displayName · ${selectedModifiers.map((modifier) => modifier.name).join(', ')}';
            priceCents += selectedModifiers.fold<int>(
              0,
              (sum, modifier) => sum + modifier.priceCents,
            );
          }

          final orderItem = order_item.OrderItem(
            id: 'item-${DateTime.now().millisecondsSinceEpoch}-${key.hashCode}',
            menuItemId: item.id,
            name: displayName,
            quantity: diff,
            priceCents: priceCents,
            status: order_item.OrderStatus.pending,
            modifierIds: selection.modifierIds,
            variationId: selection.variationId,
          );
          await orderService.addItem(
            orderId: _currentOrder!.id,
            item: orderItem,
          );
        } else if (diff < 0) {
          // Need to remove items
          int toRemove = -diff;

          // Sort so we remove pending first, then prepping, etc.
          existingItems.sort((a, b) {
            final orderMap = {
              order_item.OrderStatus.pending: 0,
              order_item.OrderStatus.sent: 1,
              order_item.OrderStatus.preparing: 2,
              order_item.OrderStatus.ready: 3,
              order_item.OrderStatus.served: 4,
            };
            return orderMap[a.status]!.compareTo(orderMap[b.status]!);
          });

          for (var existing in existingItems) {
            if (toRemove <= 0) break;

            if (existing.quantity <= toRemove) {
              await orderService.removeItem(
                orderId: _currentOrder!.id,
                itemId: existing.id,
                byUserId: currentUser.id,
              );
              toRemove -= existing.quantity;
            } else {
              final updatedItem = existing.copyWith(
                quantity: existing.quantity - toRemove,
              );
              await orderService.updateItem(
                orderId: _currentOrder!.id,
                item: updatedItem,
                byUserId: currentUser.id,
              );
              toRemove = 0;
            }
          }
        }
      }

      final existingAdditionsById = <String, List<order_item.OrderItem>>{};
      if (widget.existingOrderId != null) {
        for (final existing in _currentOrder!.items) {
          final additionalId = globalAdditionalIdFromMenuItemId(
            existing.menuItemId,
          );
          if (additionalId != null) {
            existingAdditionsById
                .putIfAbsent(additionalId, () => [])
                .add(existing);
          }
        }
      }
      final additionIds = _selectedAdditionalQuantities.keys.toSet().union(
        existingAdditionsById.keys.toSet(),
      );
      for (final additionalId in additionIds) {
        final desiredQty = _selectedAdditionalQuantities[additionalId] ?? 0;
        final existingItems = existingAdditionsById[additionalId] ?? [];
        final existingQty = existingItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );
        final diff = desiredQty - existingQty;
        if (diff > 0) {
          final additional = _additionById(additionalId);
          if (additional == null) {
            throw StateError(
              'El adicional seleccionado ya no está disponible.',
            );
          }
          await orderService.addItem(
            orderId: _currentOrder!.id,
            item: order_item.OrderItem(
              id: 'additional-${DateTime.now().microsecondsSinceEpoch}-$additionalId',
              menuItemId: globalAdditionalLineMenuItemId(additional.id),
              name: additional.name,
              quantity: diff,
              priceCents: additional.priceCents,
              status: order_item.OrderStatus.pending,
              modifierIds: [additional.id],
            ),
          );
        } else if (diff < 0) {
          var toRemove = -diff;
          for (final existing in existingItems) {
            if (toRemove <= 0) break;
            if (existing.quantity <= toRemove) {
              await orderService.removeItem(
                orderId: _currentOrder!.id,
                itemId: existing.id,
                byUserId: currentUser.id,
              );
              toRemove -= existing.quantity;
            } else {
              await orderService.updateItem(
                orderId: _currentOrder!.id,
                item: existing.copyWith(quantity: existing.quantity - toRemove),
                byUserId: currentUser.id,
              );
              toRemove = 0;
            }
          }
        }
      }

      final sentOrder = await orderService.sendToKitchen(
        orderId: _currentOrder!.id,
        byUserId: currentUser.id,
      );

      setState(() => _currentOrder = sentOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido enviado a cocina')),
        );
        context.go('/orders/tracking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    }
  }

  void _showModifiersBottomSheet(MenuItem item, {String? variationId}) {
    final selectedModifierIds = <String>{};
    final selectedAdditionalIds = <String>{};
    String? selectedVariationId = variationId;
    var quantity = 1;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final effectiveVariationId =
              selectedVariationId ??
              (item.variations.isEmpty ? null : item.variations.first.id);
          final variation = effectiveVariationId == null
              ? null
              : item.variations.firstWhere(
                  (value) => value.id == effectiveVariationId,
                );
          final basePrice = variation?.priceCents ?? item.priceCents;
          final maxQuantity = variation?.stock ?? item.stock;
          final displayName = variation == null
              ? item.name
              : '${item.name} (${variation.name})';
          final localExtras = item.modifiers
              .where((modifier) => selectedModifierIds.contains(modifier.id))
              .fold<int>(0, (sum, modifier) => sum + modifier.priceCents);
          final globalExtras = _availableAdditions
              .where(
                (addition) =>
                    addition.available &&
                    selectedAdditionalIds.contains(addition.id),
              )
              .fold<int>(0, (sum, addition) => sum + addition.priceCents);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(displayName, style: AppTypography.h2()),
                  const SizedBox(height: 8),
                  Text(
                    'Personaliza el plato o añade porciones del catálogo global.',
                    style: AppTypography.bodyMd(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (variationId == null && item.variations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(effectiveVariationId),
                      initialValue: effectiveVariationId,
                      decoration: const InputDecoration(labelText: 'Variación'),
                      items: item.variations
                          .map(
                            (value) => DropdownMenuItem(
                              value: value.id,
                              child: Text(value.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setModalState(() => selectedVariationId = value),
                    ),
                  ],
                  if (item.modifiers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Personalizaciones del plato',
                      style: AppTypography.h3(),
                    ),
                    ...item.modifiers.map(
                      (modifier) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selectedModifierIds.contains(modifier.id),
                        title: Text(modifier.name),
                        subtitle: Text(
                          modifier.priceCents == 0
                              ? 'Sin coste adicional'
                              : '+${(modifier.priceCents / 100).toStringAsFixed(2)} €',
                        ),
                        onChanged: (selected) => setModalState(() {
                          if (selected ?? false) {
                            selectedModifierIds.add(modifier.id);
                          } else {
                            selectedModifierIds.remove(modifier.id);
                          }
                        }),
                      ),
                    ),
                  ],
                  if (_availableAdditions.any(
                    (addition) => addition.available,
                  )) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Adicionales para cualquier plato',
                      style: AppTypography.h3(),
                    ),
                    ..._availableAdditions
                        .where((addition) => addition.available)
                        .map(
                          (addition) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selectedAdditionalIds.contains(addition.id),
                            title: Text(addition.name),
                            subtitle: Text(
                              '+${(addition.priceCents / 100).toStringAsFixed(2)} €',
                            ),
                            onChanged: (selected) => setModalState(() {
                              if (selected ?? false) {
                                selectedAdditionalIds.add(addition.id);
                              } else {
                                selectedAdditionalIds.remove(addition.id);
                              }
                            }),
                          ),
                        ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Cantidad'),
                      const Spacer(),
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setModalState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$quantity', style: AppTypography.h3()),
                      IconButton(
                        onPressed: quantity < maxQuantity
                            ? () => setModalState(() => quantity++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StitchPrimaryButton(
                    label:
                        'Añadir · ${((basePrice + localExtras + globalExtras) * quantity / 100).toStringAsFixed(2)} €',
                    icon: Icons.add,
                    onPressed: () {
                      final key = _selectionKey(
                        item.id,
                        variationId: effectiveVariationId,
                        modifierIds: selectedModifierIds,
                      );
                      setState(() {
                        _selectedQuantities[key] =
                            (_selectedQuantities[key] ?? 0) + quantity;
                        for (final additionalId in selectedAdditionalIds) {
                          _selectedAdditionalQuantities[additionalId] =
                              (_selectedAdditionalQuantities[additionalId] ??
                                  0) +
                              quantity;
                        }
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVariationsBottomSheet(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.name, style: AppTypography.h2()),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona las variaciones y cantidades:',
                    style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  if (_availableAdditions.any(
                        (addition) => addition.available,
                      ) ||
                      item.modifiers.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showModifiersBottomSheet(item);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Añadir variación con adicionales'),
                      ),
                    ),
                  ...item.variations.map((v) {
                    final key = _selectionKey(item.id, variationId: v.id);
                    final qty = _selectedQuantities[key] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${(v.priceCents / 100).toStringAsFixed(2)}€ • ${v.stock} disp.',
                                  style: TextStyle(
                                    color: v.stock == 0
                                        ? Colors.red
                                        : const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AppColors.primaryContainer,
                                ),
                                onPressed: qty > 0
                                    ? () {
                                        setModalState(() {
                                          _selectedQuantities[key] = qty - 1;
                                        });
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primaryContainer,
                                ),
                                onPressed: () {
                                  if (qty >= v.stock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No hay suficiente stock para la variación ${v.name}',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setModalState(() {
                                    _selectedQuantities[key] = qty + 1;
                                  });
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  StitchPrimaryButton(
                    onPressed: () => Navigator.pop(ctx),
                    label: 'Confirmar',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            _buildTopAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        'Error: $_errorMessage',
                        style: GoogleFonts.plusJakartaSans(color: Colors.red),
                      ),
                    )
                  : Column(
                      children: [
                        // Search & Filter Bar
                        _buildSearchBar(),
                        // Category Tabs
                        _buildCategoryTabs(),
                        // Product Grid
                        Expanded(child: _buildDishGrid()),
                      ],
                    ),
            ),
            // Floating Order Summary
            if (!_isLoading && _errorMessage == null)
              _buildOrderSummary(tablesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    final currentUser = ref.read(currentUserProvider).value;
    final displayName = currentUser?.name ?? 'Mesero';
    final tableInfo = _currentOrder != null && _currentOrder!.tableId.isNotEmpty
        ? 'Mesa ${_currentOrder!.tableId}'
        : 'Nuevo Pedido';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF131D21)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/menu');
                  }
                },
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tableInfo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Servicio Activo • $displayName',
                    style: AppTypography.statusBadge(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
              border: Border.all(color: AppColors.primaryContainer, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar plato...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: const BorderSide(
              color: AppColors.primaryContainer,
              width: 2,
            ),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: List.generate(_categories.length, (index) {
          final isActive = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () {
                setState(() => _selectedCategoryIndex = index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? AppColors.primaryContainer
                    : Colors.white,
                foregroundColor: isActive
                    ? Colors.white
                    : const Color(0xFF64748B),
                elevation: isActive ? 4 : 0,
                shadowColor: isActive
                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  side: isActive
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                _categories[index],
                style: AppTypography.labelCaps(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDishGrid() {
    if (_menuItems.isEmpty) {
      return Center(
        child: Text(
          'No hay platos disponibles',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
        ),
      );
    }

    final query = _searchController.text.toLowerCase();
    final selectedCat = _categories[_selectedCategoryIndex];
    final filteredItems = _menuItems.where((item) {
      if (!item.available) return false;
      final matchesSearch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query);
      final matchesCat = selectedCat == 'Todos' || item.category == selectedCat;
      return matchesSearch && matchesCat;
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron platos',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 120),
      itemCount: filteredItems.length,
      itemBuilder: (ctx, idx) => _buildDishCard(filteredItems[idx]),
    );
  }

  Widget _buildDishCard(MenuItem item) {
    final hasVariations = item.variations.isNotEmpty;
    final totalQuantity = _selectedQuantities.entries
        .where((entry) => _parseSelectionKey(entry.key).menuItemId == item.id)
        .fold<int>(0, (sum, entry) => sum + entry.value);
    final isOutOfStock = !hasVariations && item.stock <= 0;

    final priceLabel = hasVariations
        ? 'Desde ${(item.variations.map((v) => v.priceCents).reduce((a, b) => a < b ? a : b) / 100).toStringAsFixed(2)} €'
        : '${(item.priceCents / 100).toStringAsFixed(2)} €';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: totalQuantity > 0
              ? AppColors.primaryContainer.withValues(alpha: 0.4)
              : isOutOfStock
              ? Colors.grey.shade200
              : AppColors.primaryContainer.withValues(alpha: 0.15),
          width: totalQuantity > 0 ? 2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isOutOfStock
              ? null
              : () {
                  if (hasVariations) {
                    _showVariationsBottomSheet(item);
                  } else if (item.modifiers.isNotEmpty ||
                      _availableAdditions.any(
                        (addition) => addition.available,
                      )) {
                    _showModifiersBottomSheet(item);
                  } else {
                    if (totalQuantity >= item.stock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No hay más stock disponible'),
                        ),
                      );
                      return;
                    }
                    final key = _selectionKey(item.id);
                    setState(() {
                      _selectedQuantities[key] =
                          (_selectedQuantities[key] ?? 0) + 1;
                    });
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.grey.shade100
                        : totalQuantity > 0
                        ? AppColors.primaryContainer.withValues(alpha: 0.15)
                        : AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: isOutOfStock
                        ? Colors.grey.shade400
                        : AppColors.primaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isOutOfStock
                              ? Colors.grey.shade400
                              : AppColors.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Price badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? Colors.grey.shade200
                                  : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              priceLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isOutOfStock
                                    ? Colors.grey.shade500
                                    : Colors.white,
                              ),
                            ),
                          ),
                          // Stock / variations badge
                          if (hasVariations)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '${item.variations.length} opciones',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? AppColors.errorContainer
                                    : item.stock <= 5
                                    ? const Color(0xFFFFF3CD)
                                    : const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                isOutOfStock
                                    ? 'Agotado'
                                    : 'Stock: ${item.stock}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isOutOfStock
                                      ? AppColors.error
                                      : item.stock <= 5
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action — stepper or add button
                if (hasVariations)
                  GestureDetector(
                    onTap: () => _showVariationsBottomSheet(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: totalQuantity > 0
                            ? AppColors.primaryContainer
                            : AppColors.primaryContainer.withValues(
                                alpha: 0.12,
                              ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 16,
                            color: totalQuantity > 0
                                ? Colors.white
                                : AppColors.primaryContainer,
                          ),
                          if (totalQuantity > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$totalQuantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (isOutOfStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  )
                else if (totalQuantity == 0)
                  GestureDetector(
                    onTap: () {
                      if (totalQuantity >= item.stock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No hay más stock disponible'),
                          ),
                        );
                        return;
                      }
                      setState(() => _selectedQuantities[item.id] = 1);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(
                          () =>
                              _selectedQuantities[item.id] = totalQuantity - 1,
                        ),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove,
                            size: 18,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Center(
                          child: Text(
                            '$totalQuantity',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (totalQuantity >= item.stock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No hay más stock disponible'),
                              ),
                            );
                            return;
                          }
                          setState(
                            () => _selectedQuantities[item.id] =
                                totalQuantity + 1,
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
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

  Widget _buildOrderSummary(AsyncValue<List<table_model.Table>> tablesAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: StitchPrimaryButton(
        onPressed: _totalSelectedItems > 0
            ? () {
                String selectedTableId = _currentOrder?.tableId ?? '';
                final availableTables =
                    tablesAsync.value
                        ?.where(
                          (t) => t.status == table_model.TableStatus.available,
                        )
                        .map((t) => t.id)
                        .toList() ??
                    [];
                final allTables = tablesAsync.value ?? [];
                if (allTables.isEmpty) {
                  availableTables.addAll(['01', '02', '03', '04']);
                }
                if (widget.existingOrderId == null) {
                  if (selectedTableId.isEmpty ||
                      !availableTables.contains(selectedTableId)) {
                    selectedTableId = availableTables.isNotEmpty
                        ? availableTables.first
                        : '';
                  }
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (ctx) => StatefulBuilder(
                    builder: (context, setModalState) {
                      final selectedItems = <MapEntry<String, int>>[
                        ..._selectedQuantities.entries.where(
                          (e) => e.value > 0,
                        ),
                        ..._selectedAdditionalQuantities.entries
                            .where((e) => e.value > 0)
                            .map(
                              (entry) => MapEntry(
                                'additional|${entry.key}',
                                entry.value,
                              ),
                            ),
                      ];
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Revisar Pedido', style: AppTypography.h2()),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 250,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: selectedItems.length,
                                  itemBuilder: (context, index) {
                                    final entry = selectedItems[index];
                                    if (entry.key.startsWith('additional|')) {
                                      final additionalId = entry.key.substring(
                                        'additional|'.length,
                                      );
                                      final additional = _additionById(
                                        additionalId,
                                      );
                                      if (additional == null) {
                                        return const SizedBox.shrink();
                                      }
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.primaryContainer,
                                        ),
                                        title: Text(
                                          additional.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${(additional.priceCents / 100).toStringAsFixed(2)}€ c/u',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color:
                                                    AppColors.primaryContainer,
                                              ),
                                              onPressed: () {
                                                setModalState(() {
                                                  if (entry.value > 1) {
                                                    _selectedAdditionalQuantities[additionalId] =
                                                        entry.value - 1;
                                                  } else {
                                                    _selectedAdditionalQuantities
                                                        .remove(additionalId);
                                                  }
                                                });
                                                setState(() {});
                                                if (_totalSelectedItems == 0) {
                                                  Navigator.pop(ctx);
                                                }
                                              },
                                            ),
                                            Text(
                                              '${_selectedAdditionalQuantities[additionalId] ?? 0}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                color:
                                                    AppColors.primaryContainer,
                                              ),
                                              onPressed: () {
                                                setModalState(() {
                                                  _selectedAdditionalQuantities[additionalId] =
                                                      entry.value + 1;
                                                });
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final selection = _parseSelectionKey(
                                      entry.key,
                                    );
                                    final itemId = selection.menuItemId;
                                    final variationId = selection.variationId;

                                    final item = _menuItems.firstWhere(
                                      (m) => m.id == itemId,
                                    );

                                    String displayName = item.name;
                                    int priceCents = item.priceCents;

                                    if (variationId != null) {
                                      final variation = item.variations
                                          .firstWhere(
                                            (v) => v.id == variationId,
                                          );
                                      displayName =
                                          '${item.name} (${variation.name})';
                                      priceCents = variation.priceCents;
                                    }
                                    final selectedModifiers = item.modifiers
                                        .where(
                                          (modifier) => selection.modifierIds
                                              .contains(modifier.id),
                                        )
                                        .toList();
                                    if (selectedModifiers.isNotEmpty) {
                                      displayName =
                                          '$displayName · ${selectedModifiers.map((modifier) => modifier.name).join(', ')}';
                                      priceCents += selectedModifiers.fold<int>(
                                        0,
                                        (sum, modifier) =>
                                            sum + modifier.priceCents,
                                      );
                                    }

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${(priceCents / 100).toStringAsFixed(2)}€ c/u',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: AppColors.primaryContainer,
                                            ),
                                            onPressed: () {
                                              if (entry.value > 1) {
                                                setModalState(
                                                  () =>
                                                      _selectedQuantities[entry
                                                              .key] =
                                                          entry.value - 1,
                                                );
                                                setState(
                                                  () =>
                                                      _selectedQuantities[entry
                                                              .key] =
                                                          entry.value - 1,
                                                );
                                              } else {
                                                setModalState(
                                                  () => _selectedQuantities
                                                      .remove(entry.key),
                                                );
                                                setState(
                                                  () => _selectedQuantities
                                                      .remove(entry.key),
                                                );
                                              }
                                              if (_totalSelectedItems == 0) {
                                                Navigator.pop(ctx);
                                              }
                                            },
                                          ),
                                          Text(
                                            '${_selectedQuantities[entry.key] ?? 0}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors.primaryContainer,
                                            ),
                                            onPressed: () {
                                              final maxStock =
                                                  variationId != null
                                                  ? item.variations
                                                        .firstWhere(
                                                          (v) =>
                                                              v.id ==
                                                              variationId,
                                                        )
                                                        .stock
                                                  : item.stock;
                                              if (entry.value >= maxStock) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'No hay más stock disponible',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              setModalState(
                                                () =>
                                                    _selectedQuantities[entry
                                                            .key] =
                                                        entry.value + 1,
                                              );
                                              setState(
                                                () =>
                                                    _selectedQuantities[entry
                                                            .key] =
                                                        entry.value + 1,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const Divider(height: 32),
                              if (widget.existingOrderId == null)
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      availableTables.contains(selectedTableId)
                                      ? selectedTableId
                                      : null,
                                  decoration: InputDecoration(
                                    labelText: 'Seleccionar Mesa',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: availableTables.map((table) {
                                    return DropdownMenuItem<String>(
                                      value: table,
                                      child: Text('Mesa $table'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(
                                        () => selectedTableId = val,
                                      );
                                    }
                                  },
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    'Mesa seleccionada: $selectedTableId',
                                    style: AppTypography.h3(),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total:', style: AppTypography.h3()),
                                  Text(
                                    '${(_totalSelectedCents / 100).toStringAsFixed(2)}€',
                                    style: AppTypography.h2(
                                      color: AppColors.primaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              StitchPrimaryButton(
                                onPressed:
                                    (widget.existingOrderId == null &&
                                        availableTables.isEmpty)
                                    ? null
                                    : () {
                                        Navigator.pop(ctx);
                                        _sendToKitchen(selectedTableId);
                                      },
                                icon: Icons.restaurant,
                                label: 'Confirmar y Enviar a Cocina',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            : null,
        icon: Icons.receipt_long,
        label:
            '$_totalSelectedItems Items — ${(_totalSelectedCents / 100).toStringAsFixed(2)}€',
      ),
    );
  }
}

class _OrderSelection {
  final String menuItemId;
  final String? variationId;
  final List<String> modifierIds;

  const _OrderSelection({
    required this.menuItemId,
    required this.variationId,
    required this.modifierIds,
  });
}

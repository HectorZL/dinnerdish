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

class ActiveCartState {
  String? tableId;
  Map<String, int> selectedQuantities = {};
  Map<String, int> selectedAdditionalQuantities = {};

  void clear() {
    tableId = null;
    selectedQuantities.clear();
    selectedAdditionalQuantities.clear();
  }
}

final activeCartProvider = Provider<ActiveCartState>((ref) => ActiveCartState());

class CreateOrderScreen extends ConsumerStatefulWidget {
  final String? existingOrderId;
  final String? tableId;
  const CreateOrderScreen({this.existingOrderId, this.tableId, super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  String? _selectedTableId;
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
    if (widget.existingOrderId == null) {
      final activeCart = ref.read(activeCartProvider);
      _selectedTableId = widget.tableId ?? activeCart.tableId;
      _selectedQuantities.addAll(activeCart.selectedQuantities);
      _selectedAdditionalQuantities.addAll(activeCart.selectedAdditionalQuantities);
    }
    _loadData();
  }

  void _syncActiveCart() {
    if (widget.existingOrderId == null) {
      final activeCart = ref.read(activeCartProvider);
      activeCart.tableId = _selectedTableId;
      activeCart.selectedQuantities = Map.from(_selectedQuantities);
      activeCart.selectedAdditionalQuantities =
          Map.from(_selectedAdditionalQuantities);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final menuService = ref.read(menuServiceProvider);
      final menu = await menuService.fetchMenu();
      final additions = await ref
          .read(additionalServiceProvider)
          .fetchAdditions();

      Order? order;
      final orderService = ref.read(orderServiceProvider);

      if (widget.existingOrderId != null) {
        order = await orderService.getOrder(widget.existingOrderId!);
        if (order != null) {
          _selectedTableId = order.tableId;
          _selectedQuantities.clear();
          _selectedAdditionalQuantities.clear();
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

  List<GlobalAdditional> _additionsForItem(MenuItem item) {
    final assignedIds = item.additionalIds.toSet();
    return _availableAdditions
        .where((additional) => assignedIds.contains(additional.id))
        .toList();
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
    final currentUser = ref.read(currentUserProvider).valueOrNull;
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
      late Order activeOrder;

      if (widget.existingOrderId != null && _currentOrder != null) {
        activeOrder = _currentOrder!;
        if (tableId.isNotEmpty && tableId != activeOrder.tableId) {
          await orderService.updateTable(
            orderId: activeOrder.id,
            tableId: tableId,
          );
        }
      } else {
        // Create draft now in the backend atomically
        activeOrder = await orderService.createDraft(
          waiterId: currentUser.id,
          tableId: tableId,
        );
      }

      // Update Table status to occupied
      if (tableId.isNotEmpty) {
        await ref
            .read(tableServiceProvider)
            .updateTableStatus(tableId, table_model.TableStatus.occupied);
      }

      // Calculate differences instead of clearing all items
      final existingItemsByKey = <String, List<order_item.OrderItem>>{};
      if (widget.existingOrderId != null && _currentOrder != null) {
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
          final priceCents = selection.variationId == null
              ? item.priceCents
              : item.variations
                    .firstWhere(
                      (variation) => variation.id == selection.variationId,
                    )
                    .priceCents;

          await orderService.addItem(
            orderId: activeOrder.id,
            item: order_item.OrderItem(
              id: 'item-${DateTime.now().microsecondsSinceEpoch}-${selection.menuItemId}',
              menuItemId: selection.menuItemId,
              name: item.name,
              quantity: diff,
              priceCents: priceCents,
              variationId: selection.variationId,
              modifierIds: selection.modifierIds,
              status: order_item.OrderStatus.pending,
            ),
          );
        } else if (diff < 0) {
          var toRemove = -diff;
          for (final existing in existingItems) {
            if (toRemove <= 0) break;
            if (existing.quantity <= toRemove) {
              await orderService.removeItem(
                orderId: activeOrder.id,
                itemId: existing.id,
                byUserId: currentUser.id,
              );
              toRemove -= existing.quantity;
            } else {
              final updatedItem = existing.copyWith(
                quantity: existing.quantity - toRemove,
              );
              await orderService.updateItem(
                orderId: activeOrder.id,
                item: updatedItem,
                byUserId: currentUser.id,
              );
              toRemove = 0;
            }
          }
        }
      }

      final existingAdditionsById = <String, List<order_item.OrderItem>>{};
      if (widget.existingOrderId != null && _currentOrder != null) {
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
            orderId: activeOrder.id,
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
                orderId: activeOrder.id,
                itemId: existing.id,
                byUserId: currentUser.id,
              );
              toRemove -= existing.quantity;
            } else {
              await orderService.updateItem(
                orderId: activeOrder.id,
                item: existing.copyWith(quantity: existing.quantity - toRemove),
                byUserId: currentUser.id,
              );
              toRemove = 0;
            }
          }
        }
      }

      final sentOrder = await orderService.sendToKitchen(
        orderId: activeOrder.id,
        byUserId: currentUser.id,
      );

      ref.read(activeCartProvider).clear();
      setState(() {
        _currentOrder = sentOrder;
        _selectedQuantities.clear();
        _selectedAdditionalQuantities.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido confirmado y enviado a cocina con éxito'),
            backgroundColor: Color(0xFF10B981),
          ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableVariations = item.variations
              .where((value) => value.stock > 0)
              .toList();
          final effectiveVariationId =
              selectedVariationId ??
              (availableVariations.isEmpty
                  ? null
                  : availableVariations.first.id);
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
          final itemAdditions = _additionsForItem(item);
          final globalExtras = itemAdditions
              .where(
                (addition) =>
                    addition.available &&
                    selectedAdditionalIds.contains(addition.id),
              )
              .fold<int>(0, (sum, addition) => sum + addition.priceCents);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personaliza el plato o añade porciones del catálogo.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    if (variationId == null && item.variations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tamaño / Variación',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: ValueKey(effectiveVariationId),
                            value: effectiveVariationId,
                            isExpanded: true,
                            items: item.variations
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value.id,
                                    enabled: value.stock > 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${value.name} — ${(value.priceCents / 100).toStringAsFixed(2)} €',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          value.stock > 0
                                              ? 'Disp. (${value.stock})'
                                              : 'Agotado',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: value.stock > 0
                                                ? const Color(0xFF15803D)
                                                : AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setModalState(
                                () => selectedVariationId = value),
                          ),
                        ),
                      ),
                    ],
                    if (item.modifiers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Personalizaciones del plato',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...item.modifiers.map(
                        (modifier) {
                          final isSelected =
                              selectedModifierIds.contains(modifier.id);
                          return InkWell(
                            onTap: () => setModalState(() {
                              if (isSelected) {
                                selectedModifierIds.remove(modifier.id);
                              } else {
                                selectedModifierIds.add(modifier.id);
                              }
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFF7ED)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          modifier.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isSelected
                                                ? const Color(0xFF9A3412)
                                                : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          modifier.priceCents == 0
                                              ? 'Sin coste adicional'
                                              : '+${(modifier.priceCents / 100).toStringAsFixed(2)} €',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: isSelected
                                                ? const Color(0xFFEA580C)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFFEA580C)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFFCBD5E1),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (itemAdditions.any((addition) => addition.available)) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Adicionales de ${item.name}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...itemAdditions
                          .where((addition) => addition.available)
                          .map(
                            (addition) {
                              final isSelected = selectedAdditionalIds
                                  .contains(addition.id);
                              return InkWell(
                                onTap: () => setModalState(() {
                                  if (isSelected) {
                                    selectedAdditionalIds.remove(addition.id);
                                  } else {
                                    selectedAdditionalIds.add(addition.id);
                                  }
                                }),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFF7ED)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFF97316)
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              addition.name,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: isSelected
                                                    ? const Color(0xFF9A3412)
                                                    : const Color(0xFF1E293B),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '+${(addition.priceCents / 100).toStringAsFixed(2)} €',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFFEA580C),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFDCFCE7),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Disponible',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color:
                                                          const Color(0xFF15803D),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? const Color(0xFFEA580C)
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFEA580C)
                                                : const Color(0xFFCBD5E1),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check,
                                                size: 14, color: Colors.white)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Cantidad',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: quantity > 1
                                    ? () => setModalState(() => quantity--)
                                    : null,
                                icon: const Icon(Icons.remove, size: 18),
                                color: const Color(0xFF475569),
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: quantity < maxQuantity
                                    ? () => setModalState(() => quantity++)
                                    : null,
                                icon: const Icon(Icons.add, size: 18),
                                color: const Color(0xFFEA580C),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StitchPrimaryButton(
                      label:
                          'Añadir · ${((basePrice + localExtras + globalExtras) * quantity / 100).toStringAsFixed(2)} €',
                      icon: Icons.add,
                      onPressed: maxQuantity > 0
                          ? () {
                              final key = _selectionKey(
                                item.id,
                                variationId: effectiveVariationId,
                                modifierIds: selectedModifierIds,
                              );
                              setState(() {
                                _selectedQuantities[key] =
                                    (_selectedQuantities[key] ?? 0) + quantity;
                                for (final additionalId
                                    in selectedAdditionalIds) {
                                  _selectedAdditionalQuantities[additionalId] =
                                      (_selectedAdditionalQuantities[additionalId] ??
                                          0) +
                                      quantity;
                                }
                              });
                              _syncActiveCart();
                              Navigator.of(context).pop();
                            }
                          : null,
                    ),
                  ],
                ),
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
    final tables = tablesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            _buildTopAppBar(tables),
            // Table selection banner if not selected
            _buildTableSelectionBanner(tables),
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

  table_model.Table? _findTable(List<table_model.Table> tables, String? tableId) {
    if (tableId == null) return null;
    for (final t in tables) {
      if (t.id == tableId || t.number.toString() == tableId) {
        return t;
      }
    }
    return null;
  }

  Widget _buildTableSelectionBanner(List<table_model.Table> tables) {
    if (_selectedTableId != null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFED7AA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.table_restaurant_outlined,
              color: Color(0xFFC2410C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mesa no asignada',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                Text(
                  'Elige la mesa antes de confirmar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showTablePickerModal(tables),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Elegir',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTablePickerModal(
    List<table_model.Table> tables, {
    VoidCallback? onTableSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sections = <String, List<table_model.Table>>{};
        for (final table in tables) {
          final sec = (table.section != null && table.section!.trim().isNotEmpty)
              ? table.section!.trim()
              : 'General';
          sections.putIfAbsent(sec, () => []).add(table);
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Mesa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Elige la mesa para este pedido',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tables.isEmpty
                    ? Center(
                        child: Text(
                          'No hay mesas registradas',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    : ListView(
                        children: sections.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  entry.key.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: entry.value.map((table) {
                                  final isSelected = _selectedTableId == table.id;
                                  final isOccupied =
                                      table.status == table_model.TableStatus.occupied;

                                  Color statusBg = const Color(0xFFDCFCE7);
                                  Color statusText = const Color(0xFF15803D);
                                  String statusLabel = 'Disponible';

                                  if (isOccupied) {
                                    statusBg = const Color(0xFFFEF3C7);
                                    statusText = const Color(0xFFD97706);
                                    statusLabel = 'Ocupada';
                                  } else if (table.status == table_model.TableStatus.reserved) {
                                    statusBg = const Color(0xFFDBEAFE);
                                    statusText = const Color(0xFF1D4ED8);
                                    statusLabel = 'Reservada';
                                  }

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedTableId = table.id;
                                      });
                                      _syncActiveCart();
                                      onTableSelected?.call();
                                      Navigator.of(ctx).pop();
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 105,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFFF7ED)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFEA580C)
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2.0 : 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.table_restaurant,
                                            size: 26,
                                            color: isSelected
                                                ? const Color(0xFFEA580C)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Mesa ${table.number}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? const Color(0xFF9A3412)
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${table.seats} pers.',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: statusText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(List<table_model.Table> tables) {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final displayName = currentUser?.name ?? 'Mesero';
    final curTable = _findTable(tables, _selectedTableId);

    final tableNameText = curTable != null
        ? (curTable.section != null && curTable.section!.isNotEmpty
            ? 'Mesa ${curTable.number} · ${curTable.section}'
            : 'Mesa ${curTable.number}')
        : 'Seleccionar Mesa';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  InkWell(
                    onTap: () => _showTablePickerModal(tables),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Text(
                          tableNameText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: curTable != null
                                ? AppColors.onSurface
                                : const Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          curTable != null
                              ? Icons.edit
                              : Icons.keyboard_arrow_down,
                          size: 16,
                          color: const Color(0xFFEA580C),
                        ),
                      ],
                    ),
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
    final isOutOfStock = hasVariations
        ? item.variations.every((variation) => variation.stock <= 0)
        : item.stock <= 0;

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
                  if (hasVariations ||
                      item.modifiers.isNotEmpty ||
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
                    _syncActiveCart();
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
                          // Stock por variación
                          if (hasVariations)
                            ...item.variations.map(
                              (variation) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: variation.stock > 0
                                      ? const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.1)
                                      : AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  '${variation.name}: ${variation.stock > 0 ? 'Disponible' : 'Agotado'} (${variation.stock})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: variation.stock > 0
                                        ? const Color(0xFF059669)
                                        : AppColors.error,
                                  ),
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
                                    ? 'Agotado (0)'
                                    : 'Disponible (${item.stock})',
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
                if (hasVariations && !isOutOfStock)
                  GestureDetector(
                    onTap: () => _showModifiersBottomSheet(item),
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
                      _syncActiveCart();
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
                        onTap: () {
                          setState(() {
                            if (totalQuantity <= 1) {
                              _selectedQuantities.remove(item.id);
                            } else {
                              _selectedQuantities[item.id] = totalQuantity - 1;
                            }
                          });
                          _syncActiveCart();
                        },
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
                          _syncActiveCart();
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

  Widget _buildQuantityStepper({
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(9)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                quantity == 1 ? Icons.delete_outline : Icons.remove,
                size: 18,
                color: quantity == 1
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF475569),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(9)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                Icons.add,
                size: 18,
                color: Color(0xFFEA580C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewOrderSheet(List<table_model.Table> allTables) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final curTable = _findTable(allTables, _selectedTableId);

          final selectedItems = <MapEntry<String, int>>[
            ..._selectedQuantities.entries.where((e) => e.value > 0),
            ..._selectedAdditionalQuantities.entries
                .where((e) => e.value > 0)
                .map((entry) => MapEntry('additional|${entry.key}', entry.value)),
          ];

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Revisar Pedido',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Table selector chip
                  InkWell(
                    onTap: () => _showTablePickerModal(
                      allTables,
                      onTableSelected: () => setSheetState(() {}),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: curTable != null
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: curTable != null
                              ? const Color(0xFFFDBA74)
                              : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                curTable != null
                                    ? Icons.table_restaurant
                                    : Icons.warning_amber_rounded,
                                color: curTable != null
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                curTable != null
                                    ? 'Mesa ${curTable.number}${curTable.section != null && curTable.section!.isNotEmpty ? ' · ${curTable.section}' : ''}'
                                    : 'Mesa no seleccionada',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: curTable != null
                                      ? const Color(0xFF9A3412)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                curTable != null ? 'Cambiar' : 'Elegir mesa',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: curTable != null
                                      ? const Color(0xFFEA580C)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: curTable != null
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFFDC2626),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selected items list
                  Expanded(
                    child: selectedItems.isEmpty
                        ? Center(
                            child: Text(
                              'No hay productos en el pedido',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: selectedItems.length,
                            itemBuilder: (context, index) {
                              final entry = selectedItems[index];

                              if (entry.key.startsWith('additional|')) {
                                final additionalId = entry.key.substring(
                                  'additional|'.length,
                                );
                                final additional = _additionById(additionalId);
                                if (additional == null) {
                                  return const SizedBox.shrink();
                                }
                                final unitPrice = additional.priceCents;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFF15803D),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              additional.name,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Adicional · ${(unitPrice / 100).toStringAsFixed(2)} € c/u',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFEA580C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildQuantityStepper(
                                        quantity: entry.value,
                                        onDecrement: () {
                                          setSheetState(() {
                                            if (entry.value > 1) {
                                              _selectedAdditionalQuantities[
                                                  additionalId] = entry.value - 1;
                                            } else {
                                              _selectedAdditionalQuantities
                                                  .remove(additionalId);
                                            }
                                          });
                                          setState(() {});
                                          _syncActiveCart();
                                          if (_totalSelectedItems == 0) {
                                            Navigator.of(sheetCtx).pop();
                                          }
                                        },
                                        onIncrement: () {
                                          setSheetState(() {
                                            _selectedAdditionalQuantities[
                                                additionalId] = entry.value + 1;
                                          });
                                          setState(() {});
                                          _syncActiveCart();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final selection = _parseSelectionKey(entry.key);
                              final item = _menuItems.firstWhere(
                                (m) => m.id == selection.menuItemId,
                              );

                              String displayName = item.name;
                              int unitPrice = item.priceCents;
                              String? extraDetails;

                              if (selection.variationId != null) {
                                final variation = item.variations.firstWhere(
                                  (v) => v.id == selection.variationId,
                                );
                                displayName =
                                    '${item.name} (${variation.name})';
                                unitPrice = variation.priceCents;
                              }

                              final selectedModifiers = item.modifiers
                                  .where(
                                    (modifier) => selection.modifierIds
                                        .contains(modifier.id),
                                  )
                                  .toList();
                              if (selectedModifiers.isNotEmpty) {
                                extraDetails = selectedModifiers
                                    .map((modifier) => modifier.name)
                                    .join(', ');
                                unitPrice += selectedModifiers.fold<int>(
                                  0,
                                  (sum, modifier) => sum + modifier.priceCents,
                                );
                              }

                              final maxStock = selection.variationId != null
                                  ? item.variations
                                      .firstWhere(
                                        (v) => v.id == selection.variationId,
                                      )
                                      .stock
                                  : item.stock;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu,
                                        color: Color(0xFFEA580C),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: const Color(0xFF1E293B),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (extraDetails != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              extraDetails,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Text(
                                            '${(unitPrice / 100).toStringAsFixed(2)} € c/u',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFEA580C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuantityStepper(
                                      quantity: entry.value,
                                      onDecrement: () {
                                        setSheetState(() {
                                          if (entry.value > 1) {
                                            _selectedQuantities[entry.key] =
                                                entry.value - 1;
                                          } else {
                                            _selectedQuantities
                                                .remove(entry.key);
                                          }
                                        });
                                        setState(() {});
                                        _syncActiveCart();
                                        if (_totalSelectedItems == 0) {
                                          Navigator.of(sheetCtx).pop();
                                        }
                                      },
                                      onIncrement: () {
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
                                        setSheetState(() {
                                          _selectedQuantities[entry.key] =
                                              entry.value + 1;
                                        });
                                        setState(() {});
                                        _syncActiveCart();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),

                  // Financial totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ($_totalSelectedItems productos):',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '${(_totalSelectedCents / 100).toStringAsFixed(2)} €',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Button
                  if (_selectedTableId == null)
                    StitchPrimaryButton(
                      icon: Icons.table_restaurant,
                      label: 'Seleccionar Mesa para Continuar',
                      onPressed: () => _showTablePickerModal(
                        allTables,
                        onTableSelected: () => setSheetState(() {}),
                      ),
                    )
                  else
                    StitchPrimaryButton(
                      icon: Icons.restaurant,
                      label: 'Confirmar y Enviar a Cocina',
                      onPressed: () async {
                        Navigator.of(sheetCtx).pop();
                        await _sendToKitchen(_selectedTableId!);
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

  Widget _buildOrderSummary(AsyncValue<List<table_model.Table>> tablesAsync) {
    final allTables = tablesAsync.valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: StitchPrimaryButton(
        onPressed: _totalSelectedItems > 0
            ? () => _showReviewOrderSheet(allTables)
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

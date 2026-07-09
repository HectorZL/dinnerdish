import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/menu_item.dart';
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
  final List<String> _categories = [
    'Todos',
    'Entrantes',
    'Platos Principales',
    'Bebidas',
    'Postres',
    'Vinos',
  ];

  Order? _currentOrder;
  List<MenuItem> _menuItems = [];
  final Map<String, int> _selectedQuantities = {};
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
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final menuService = ref.read(menuServiceProvider);
      final menu = await menuService.fetchMenu();

      final currentUser = ref.read(currentUserProvider).value;
      Order? order;
      final orderService = ref.read(orderServiceProvider);
      
      if (widget.existingOrderId != null) {
        order = await orderService.getOrder(widget.existingOrderId!);
        if (order != null) {
          for (var item in order.items) {
            _selectedQuantities[item.menuItemId] = (_selectedQuantities[item.menuItemId] ?? 0) + item.quantity;
          }
        }
      } else if (currentUser != null) {
        order = await orderService.createDraft(waiterId: currentUser.id);
      }

      setState(() {
        _menuItems = menu;
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
    return _selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  int get _totalSelectedCents {
    var total = 0;
    for (final entry in _selectedQuantities.entries) {
      if (entry.value > 0) {
        final item = _menuItems.firstWhere((m) => m.id == entry.key);
        total += item.priceCents * entry.value;
      }
    }
    return total;
  }


  Future<void> _sendToKitchen(String tableId) async {
    if (_currentOrder == null) return;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

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
        await ref.read(tableServiceProvider).updateTableStatus(
          tableId,
          table_model.TableStatus.occupied,
        );
      }

      if (widget.existingOrderId != null) {
        for (var existing in _currentOrder!.items.toList()) {
          await orderService.removeItem(
            orderId: _currentOrder!.id,
            itemId: existing.id,
            byUserId: currentUser.id,
          );
        }
      }

      for (final entry in _selectedQuantities.entries) {
        if (entry.value <= 0) continue;
        final item = _menuItems.firstWhere((m) => m.id == entry.key);
        final orderItem = order_item.OrderItem(
          id: 'item-${DateTime.now().millisecondsSinceEpoch}-${entry.key}',
          menuItemId: item.id,
          name: item.name,
          quantity: entry.value,
          priceCents: item.priceCents,
          status: order_item.OrderStatus.pending,
          modifierIds: [],
        );
        await orderService.addItem(
          orderId: _currentOrder!.id,
          item: orderItem,
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
      }
    }
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
                            Expanded(
                              child: _buildDishGrid(),
                            ),
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
                    style: AppTypography.statusBadge(color: AppColors.primaryContainer),
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
              border: Border.all(color: AppColors.primaryContainer, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
              ],
              image: const DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDwlJyRUytgNUtSy1ACnp9jgsFrf3sxLFeD4a3O8FmMc1R5s2o7AQIcyI5tnEsSSrs2j_wtdYri1dGbRFmSFsuIBCtQT9EqZmB1-BFReegVtMCVBV4kOUJk4-TuYvm5SqLSk9Bfp3va46GC7Wf1lRzPsd4o1oq4d2D0EXYMmz2hRW_8Wti6ZKGZcrdThb-3TdZ8o6s3srnUy90A_jFwsSQXwMz41JEXrT6sbDfo_AgvyqwTK2DeFNjc_1qRM-ykAYBLGfitiIA_WdXN',
                ),
                fit: BoxFit.cover,
              ),
            ),
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
          hintText: 'Buscar plato o ingrediente...',
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
            borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
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
                backgroundColor:
                    isActive ? AppColors.primaryContainer : Colors.white,
                foregroundColor:
                    isActive ? Colors.white : const Color(0xFF64748B),
                elevation: isActive ? 4 : 0,
                shadowColor: isActive ? AppColors.primaryContainer.withValues(alpha: 0.3) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  side: isActive
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      final matchesSearch = query.isEmpty ||
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.gutter,
            mainAxisSpacing: AppSpacing.gutter,
            childAspectRatio: crossAxisCount > 1 ? 0.85 : 1.2,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (ctx, idx) => _buildDishCard(filteredItems[idx]),
        );
      },
    );
  }

  Widget _buildDishCard(MenuItem item) {
    final quantity = _selectedQuantities[item.id] ?? 0;
    final hasVariants = item.modifiers.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl * 2), // rounded-xl with overflow hidden
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.restaurant, color: const Color(0xFF94A3B8), size: 48),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                    ),
                    child: Text(
                      '\$${(item.priceCents / 100).toStringAsFixed(2)}',
                      style: AppTypography.statusBadge(color: AppColors.primaryContainer).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTypography.h3(color: AppColors.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(
                          () => _selectedQuantities[item.id] = (quantity) + 1,
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasVariants
                        ? '${item.modifiers.length} variante${item.modifiers.length > 1 ? 's' : ''} disponible${item.modifiers.length > 1 ? 's' : ''}'
                        : 'Sin variantes',
                    style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (quantity > 0) ...[
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                            () => _selectedQuantities[item.id] = quantity - 1,
                          ),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryContainer,
                            ),
                            child: const Icon(Icons.remove, color: Colors.white, size: 18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$quantity',
                            style: AppTypography.h3(color: AppColors.onSurface),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(
                            () => _selectedQuantities[item.id] = quantity + 1,
                          ),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryContainer,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
                final availableTables = tablesAsync.value?.where((t) => t.status == table_model.TableStatus.available).map((t) => t.id).toList() ?? [];
                final allTables = tablesAsync.value ?? [];
                if (allTables.isEmpty) {
                  // Fallback just in case
                  availableTables.addAll(['01', '02', '03', '04']);
                }
                if (widget.existingOrderId == null) {
                  if (selectedTableId.isEmpty || !availableTables.contains(selectedTableId)) {
                    selectedTableId = availableTables.isNotEmpty ? availableTables.first : '';
                  }
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) => StatefulBuilder(
                    builder: (context, setModalState) {
                      final selectedItems = _selectedQuantities.entries.where((e) => e.value > 0).toList();
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
                                    final item = _menuItems.firstWhere((m) => m.id == entry.key);
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('\$${(item.priceCents / 100).toStringAsFixed(2)} c/u'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryContainer),
                                            onPressed: () {
                                              if (entry.value > 1) {
                                                setModalState(() => _selectedQuantities[item.id] = entry.value - 1);
                                                setState(() => _selectedQuantities[item.id] = entry.value - 1);
                                              } else {
                                                setModalState(() => _selectedQuantities.remove(item.id));
                                                setState(() => _selectedQuantities.remove(item.id));
                                              }
                                              if (_selectedQuantities.isEmpty) Navigator.pop(ctx);
                                            },
                                          ),
                                          Text('${_selectedQuantities[item.id] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryContainer),
                                            onPressed: () {
                                              setModalState(() => _selectedQuantities[item.id] = entry.value + 1);
                                              setState(() => _selectedQuantities[item.id] = entry.value + 1);
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
                                  initialValue: availableTables.contains(selectedTableId) ? selectedTableId : null,
                                  decoration: InputDecoration(
                                    labelText: 'Seleccionar Mesa',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: availableTables.map((table) {
                                    return DropdownMenuItem<String>(value: table, child: Text('Mesa $table'));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedTableId = val);
                                  },
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('Mesa seleccionada: $selectedTableId', style: AppTypography.h3()),
                                ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total:', style: AppTypography.h3()),
                                  Text('\$${(_totalSelectedCents / 100).toStringAsFixed(2)}', style: AppTypography.h2(color: AppColors.primaryContainer)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              StitchPrimaryButton(
                                onPressed: (widget.existingOrderId == null && availableTables.isEmpty) ? null : () {
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
            '$_totalSelectedItems Items — \$${(_totalSelectedCents / 100).toStringAsFixed(2)}',
      ),
    );
  }
}

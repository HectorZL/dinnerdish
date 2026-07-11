import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../exceptions/menu_exception.dart';
import '../../models/menu_item.dart';
import '../../models/menu_item_variation.dart';
import '../../models/modifier.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  List<MenuItem> _items = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final menuService = ref.read(menuServiceProvider);
      final items = await menuService.fetchMenu();
      final categories = await menuService.getCategories();
      setState(() {
        _items = items;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading menu data: $e\n$st');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == null) return _items;
    return _items.where((item) => item.category == _selectedCategory).toList();
  }

  Future<void> _createItem(MenuItem item) async {
    try {
      final menuService = ref.read(menuServiceProvider);
      await menuService.createMenuItem(item);
      await _loadData();
    } catch (e, st) {
      debugPrint('Error creating menu item: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear: $e')),
      );
    }
  }

  Future<void> _updateItem(String id, MenuItem item) async {
    try {
      final menuService = ref.read(menuServiceProvider);
      await menuService.updateMenuItem(id, item);
      await _loadData();
    } catch (e, st) {
      debugPrint('Error updating menu item: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final menuService = ref.read(menuServiceProvider);
      await menuService.deleteMenuItem(id);
      await _loadData();
    } on MenuItemNotFoundException catch (e) {
      debugPrint('Delete failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } catch (e, st) {
      debugPrint('Error deleting menu item: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    final updated = item.copyWith(available: !item.available);
    await _updateItem(item.id, updated);
  }

  Future<void> _updatePrice(MenuItem item, int newPriceCents) async {
    if (newPriceCents == item.priceCents) return;
    final updated = item.copyWith(priceCents: newPriceCents);
    await _updateItem(item.id, updated);
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _MenuItemFormDialog(
        categories: _categories,
        onSave: (item) => _createItem(item),
      ),
    );
  }

  void _showEditDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => _MenuItemFormDialog(
        existingItem: item,
        categories: _categories,
        onSave: (updated) => _updateItem(item.id, updated),
      ),
    );
  }

  Future<bool> _confirmDelete(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Text(
          'Eliminar Plato',
          style: AppTypography.h2(color: AppColors.onSurface),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${item.name}"?',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppTypography.statusBadge(
                  color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: AppTypography.statusBadge(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final isMobile = !isDesktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StitchTopAppBar(
              title: 'Gestión de Menú',
              showBack: true,
              onBack: () => context.go('/menu'),
              actions: [
                TextButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, color: AppColors.primaryContainer),
                  label: const Text('Nuevo Item', style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
            floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _showCreateDialog,
              backgroundColor: AppColors.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildCategoryTabs(),
        Expanded(child: _buildItemGrid()),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: AppTypography.bodyMd(
                  color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadData,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu,
                size: 64,
                color: AppColors.outline.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay platos en el menú',
              style: AppTypography.h3(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Añade un nuevo plato para empezar',
              style: AppTypography.bodyMd(
                  color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Item'),
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

  Widget _buildCategoryTabs() {
    final allSelected = _selectedCategory == null;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildCategoryChip('Todos', allSelected, () {
            setState(() => _selectedCategory = null);
          }),
          ..._categories.map((cat) => _buildCategoryChip(
                cat,
                _selectedCategory == cat,
                () => setState(() => _selectedCategory = cat),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Material(
        color: isSelected
            ? AppColors.primaryContainer
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: AppTypography.statusBadge(
                color: isSelected
                    ? Colors.white
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemGrid() {
    final filtered = _filteredItems;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No hay platos en esta categoría',
          style: AppTypography.bodyMd(color: AppColors.outline),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.sm),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) =>
              _buildItemCard(filtered[index]),
        );
      },
    );
  }

  Widget _buildItemCard(MenuItem item) {
    return StitchCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header area
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.restaurant,
                    color: AppColors.outline, size: 20),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTypography.bodyMd(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.modifiers.isEmpty
                              ? 'Sin modificadores'
                              : '${item.modifiers.length} modificador(es)',
                          style: AppTypography.statusBadge(
                              color: AppColors.outline),
                        ),
                        const SizedBox(height: 4),
                        _InlinePriceEdit(
                          initialPriceCents: item.priceCents,
                          onSave: (cents) =>
                              _updatePrice(item, cents),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: Checkbox(
                          value: item.available,
                          onChanged: (_) =>
                              _toggleAvailability(item),
                          // ignore: deprecated_member_use
                          activeColor: AppColors.statusReady,
                          checkColor: Colors.white,
                          side: const BorderSide(
                              color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit,
                                  size: 14),
                              color: AppColors.primaryContainer,
                              onPressed: () =>
                                  _showEditDialog(item),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete,
                                  size: 14),
                              color: AppColors.error,
                              onPressed: () async {
                                final confirmed =
                                    await _confirmDelete(item);
                                if (confirmed) {
                                  _deleteItem(item.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.xl)),
            ),
            child: Text(
              item.category,
              style: AppTypography.statusBadge(
                  color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Inline Price Edit Widget
// ────────────────────────────────────────────────────────────

class _InlinePriceEdit extends StatefulWidget {
  final int initialPriceCents;
  final ValueChanged<int> onSave;

  const _InlinePriceEdit({
    required this.initialPriceCents,
    required this.onSave,
  });

  @override
  State<_InlinePriceEdit> createState() => _InlinePriceEditState();
}

class _InlinePriceEditState extends State<_InlinePriceEdit> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatPrice(widget.initialPriceCents),
    );
  }

  @override
  void didUpdateWidget(_InlinePriceEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing &&
        oldWidget.initialPriceCents != widget.initialPriceCents) {
      _controller.text = _formatPrice(widget.initialPriceCents);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatPrice(int cents) {
    final euros = cents / 100;
    return euros.toStringAsFixed(2);
  }

  int? _parsePrice(String text) {
    final cleaned = text.replaceAll(',', '.');
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed < 0) return null;
    return (parsed * 100).round();
  }

  void _save() {
    final cents = _parsePrice(_controller.text);
    if (cents != null) {
      widget.onSave(cents);
    }
    setState(() {
      _controller.text = _formatPrice(widget.initialPriceCents);
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 100,
        height: 32,
        child: TextField(
          controller: _controller,
          style: AppTypography.bodyMd(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.primaryContainer),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.primaryContainer),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                  color: AppColors.primaryContainer, width: 2),
            ),
          ),
          onSubmitted: (_) => _save(),
          autofocus: true,
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isEditing = true),
      child: Text(
        '${_formatPrice(widget.initialPriceCents)} €',
        style: AppTypography.bodyMd(
                color: AppColors.primaryContainer)
            .copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Create/Edit Dialog
// ────────────────────────────────────────────────────────────

class _MenuItemFormDialog extends StatefulWidget {
  final MenuItem? existingItem;
  final List<String> categories;
  final ValueChanged<MenuItem> onSave;

  const _MenuItemFormDialog({
    this.existingItem,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<_MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late bool _available;
  late String _category;
  late List<_ModifierEntry> _modifierEntries;
  late List<_VariationEntry> _variationEntries;
  late bool _hasVariations;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null
          ? (item.priceCents / 100).toStringAsFixed(2)
          : '',
    );
    _stockController = TextEditingController(
      text: item != null ? item.stock.toString() : '0',
    );
    _available = item?.available ?? true;
    _category = item?.category ??
        (widget.categories.isNotEmpty ? widget.categories.first : '');
    _hasVariations = item?.variations.isNotEmpty ?? false;

    _modifierEntries = (item?.modifiers ?? [])
        .map((m) => _ModifierEntry(
              id: m.id,
              nameController: TextEditingController(text: m.name),
              priceController: TextEditingController(
                text: (m.priceCents / 100).toStringAsFixed(2),
              ),
            ))
        .toList();
    if (_modifierEntries.isEmpty) {
      _addModifierEntry();
    }

    _variationEntries = (item?.variations ?? [])
        .map((v) => _VariationEntry(
              id: v.id,
              nameController: TextEditingController(text: v.name),
              priceController: TextEditingController(
                text: (v.priceCents / 100).toStringAsFixed(2),
              ),
              stockController: TextEditingController(text: v.stock.toString()),
            ))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    for (final entry in _modifierEntries) {
      entry.nameController.dispose();
      entry.priceController.dispose();
    }
    for (final entry in _variationEntries) {
      entry.nameController.dispose();
      entry.priceController.dispose();
      entry.stockController.dispose();
    }
    super.dispose();
  }

  void _addModifierEntry() {
    setState(() {
      _modifierEntries.add(_ModifierEntry(
        id:
            'mod-${DateTime.now().millisecondsSinceEpoch}-${_modifierEntries.length}',
        nameController: TextEditingController(),
        priceController: TextEditingController(),
      ));
    });
  }

  void _removeModifierEntry(int index) {
    if (_modifierEntries.length <= 1) return;
    setState(() {
      final entry = _modifierEntries.removeAt(index);
      entry.nameController.dispose();
      entry.priceController.dispose();
    });
  }

  void _addVariationEntry() {
    setState(() {
      _variationEntries.add(_VariationEntry(
        id: 'var-${DateTime.now().millisecondsSinceEpoch}-${_variationEntries.length}',
        nameController: TextEditingController(),
        priceController: TextEditingController(),
        stockController: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeVariationEntry(int index) {
    if (_variationEntries.length <= 1) return;
    setState(() {
      final entry = _variationEntries.removeAt(index);
      entry.nameController.dispose();
      entry.priceController.dispose();
      entry.stockController.dispose();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    int priceCents = 0;
    int stock = 0;

    if (!_hasVariations) {
      final priceText = _priceController.text.replaceAll(',', '.');
      priceCents = (double.parse(priceText) * 100).round();
      stock = int.parse(_stockController.text);
    }

    final modifiers = _modifierEntries
        .where((e) => e.nameController.text.trim().isNotEmpty)
        .map((e) {
      final priceText = e.priceController.text.replaceAll(',', '.');
      final modPriceCents =
          (double.parse(priceText.isEmpty ? '0' : priceText) * 100)
              .round();
      return Modifier(
        id: e.id,
        name: e.nameController.text.trim(),
        priceCents: modPriceCents,
      );
    }).toList();

    final variations = _hasVariations
        ? _variationEntries.map((e) {
            final priceText = e.priceController.text.replaceAll(',', '.');
            final varPriceCents = (double.parse(priceText) * 100).round();
            final varStock = int.parse(e.stockController.text);
            return MenuItemVariation(
              id: e.id,
              name: e.nameController.text.trim(),
              priceCents: varPriceCents,
              stock: varStock,
            );
          }).toList()
        : <MenuItemVariation>[];

    final item = MenuItem(
      id: widget.existingItem?.id ??
          'item-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      priceCents: priceCents,
      modifiers: modifiers,
      available: _available,
      category: _category,
      stock: stock,
      variations: variations,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl * 2),
      ),
      title: Text(
        _isEditing ? 'Editar Plato' : 'Nuevo Plato',
        style: AppTypography.h2(color: AppColors.onSurface),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMd(color: AppColors.onSurface),
                  decoration: _inputDecoration('Nombre del plato'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: Colors.white,
                  style: AppTypography.bodyMd(color: AppColors.onSurface),
                  decoration: _inputDecoration('Categoría'),
                  items: widget.categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      '¿Tiene variaciones?',
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Switch(
                      value: _hasVariations,
                      onChanged: (v) {
                        setState(() {
                          _hasVariations = v;
                          if (_hasVariations && _variationEntries.isEmpty) {
                            _addVariationEntry();
                          }
                        });
                      },
                      activeColor: AppColors.primaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!_hasVariations) ...[
                  TextFormField(
                    controller: _priceController,
                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration('Precio (€)'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      final cleaned = v.replaceAll(',', '.');
                      final parsed = double.tryParse(cleaned);
                      if (parsed == null || parsed < 0) return 'Precio inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _stockController,
                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Stock Inicial'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      final parsed = int.tryParse(v);
                      if (parsed == null || parsed < 0) return 'Stock inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (_hasVariations) ...[
                  Row(
                    children: [
                      Text(
                        'Variaciones',
                        style: AppTypography.bodyMd(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addVariationEntry,
                        icon: const Icon(Icons.add,
                            size: 16,
                            color: AppColors.primaryContainer),
                        label: Text(
                          'Añadir Var.',
                          style: AppTypography.statusBadge(
                              color: AppColors.primaryContainer),
                        ),
                      ),
                    ],
                  ),
                  ..._variationEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final variation = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: variation.nameController,
                              style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.normal),
                              decoration: _inputDecoration('Nombre (ej: Familiar)'),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Req.'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: variation.priceController,
                              style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.normal),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _inputDecoration('Precio'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Req.';
                                final cleaned = v.replaceAll(',', '.');
                                final parsed = double.tryParse(cleaned);
                                if (parsed == null || parsed < 0) return 'Error';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: variation.stockController,
                              style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.normal),
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Stock'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Req.';
                                final parsed = int.tryParse(v);
                                if (parsed == null || parsed < 0) return 'Error';
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                size: 20, color: AppColors.error),
                            onPressed: () => _removeVariationEntry(index),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Row(
                  children: [
                    Text(
                      'Disponible',
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Switch(
                      value: _available,
                      onChanged: (v) => setState(() => _available = v),
                      activeColor: AppColors.primaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      'Modificadores',
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addModifierEntry,
                      icon: const Icon(Icons.add,
                          size: 16,
                          color: AppColors.primaryContainer),
                      label: Text(
                        'Añadir',
                        style: AppTypography.statusBadge(
                            color: AppColors.primaryContainer),
                      ),
                    ),
                  ],
                ),
                ..._modifierEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final modifier = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: modifier.nameController,
                            style: AppTypography.bodyMd(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.normal),
                            decoration: _inputDecoration('Nombre'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: modifier.priceController,
                            style: AppTypography.bodyMd(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.normal),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration('Precio'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              size: 20, color: AppColors.error),
                          onPressed: () =>
                              _removeModifierEntry(index),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: AppTypography.statusBadge(
                color: AppColors.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: Colors.white,
          ),
          child: Text(_isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodyMd(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(
            color: AppColors.primaryContainer, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _ModifierEntry {
  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  _ModifierEntry({
    required this.id,
    required this.nameController,
    required this.priceController,
  });
}

class _VariationEntry {
  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController stockController;

  _VariationEntry({
    required this.id,
    required this.nameController,
    required this.priceController,
    required this.stockController,
  });
}


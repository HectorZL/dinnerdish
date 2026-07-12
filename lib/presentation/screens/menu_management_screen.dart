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
      final allCategories = {
        ...categories,
        'Entrantes',
        'Platos Principales',
        'Postres',
        'Bebidas',
        'Jugos',
        'Especiales',
        'Vinos'
      }.toList()..sort();

      setState(() {
        _items = items;
        _categories = allCategories;
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
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isMobile = !isDesktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const StitchAdminSidebar(activeTab: 'Menú'),
          Expanded(
            child: Column(
              children: [
                StitchTopAppBar(
                  title: 'Gestión de Menú',
                  showBack: !isDesktop,
                  onBack: () => context.go('/menu'),
                  navLinks: isDesktop
                      ? const [
                          NavLink('Inicio', false, route: '/menu'),
                          NavLink('Usuarios', false, route: '/admin/users'),
                          NavLink('Menú', true, route: '/admin/menu'),
                          NavLink('Reportes', false, route: '/admin/reports'),
                        ]
                      : null,
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
        ],
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
      key: Key('category_chip_$label'),
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
    // Use ListView instead of GridView for mobile — better readability
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildItemCard(filtered[index]),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    final hasVariations = item.variations.isNotEmpty;
    final priceLabel = hasVariations
        ? 'Desde ${(item.variations.map((v) => v.priceCents).reduce((a, b) => a < b ? a : b) / 100).toStringAsFixed(2)} €'
        : '${(item.priceCents / 100).toStringAsFixed(2)} €';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: item.available
              ? AppColors.primaryContainer.withValues(alpha: 0.2)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditDialog(item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.available
                        ? AppColors.primaryContainer.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: item.available
                        ? AppColors.primaryContainer
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + availability row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: item.available
                                    ? AppColors.onSurface
                                    : Colors.grey.shade500,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Availability pill
                          GestureDetector(
                            onTap: () => _toggleAvailability(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.available
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: item.available
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    item.available ? 'Activo' : 'Inactivo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: item.available
                                          ? const Color(0xFF059669)
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Price + Category + Stock row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // Price
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priceLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF594138).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Stock badge
                          if (!hasVariations)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.stock > 5
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Stock: ${item.stock}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: item.stock > 5
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          if (hasVariations)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.variations.length} variacion(es)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),
                          // Modifiers count badge
                          if (item.modifiers.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.modifiers.length} modificador(es)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions column
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.primaryContainer,
                      tooltip: 'Editar',
                      onPressed: () => _showEditDialog(item),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error,
                      tooltip: 'Eliminar',
                      onPressed: () async {
                        final confirmed = await _confirmDelete(item);
                        if (confirmed) _deleteItem(item.id);
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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

    try {
      if (!_hasVariations) {
        final priceText = _priceController.text.replaceAll(',', '.');
        final parsed = double.tryParse(priceText);
        if (parsed == null || parsed < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Precio inválido. Ingresa un número positivo.')),
          );
          return;
        }
        priceCents = (parsed * 100).round();

        final stockParsed = int.tryParse(_stockController.text);
        if (stockParsed == null || stockParsed < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock inválido. Ingresa un número entero positivo.')),
          );
          return;
        }
        stock = stockParsed;
      } else {
        // F1-02: Cuando hay variaciones, el stock base no aplica.
        // Usamos 99 como valor placeholder (el stock real está en las variaciones).
        stock = 99;
        priceCents = 0; // El precio se obtiene de las variaciones
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en los datos: $e')),
      );
      return;
    }

    final modifiers = _modifierEntries
        .where((e) => e.nameController.text.trim().isNotEmpty)
        .map((e) {
      final priceText = e.priceController.text.replaceAll(',', '.');
      final modPriceCents =
          ((double.tryParse(priceText) ?? 0) * 100).round();
      return Modifier(
        id: e.id,
        name: e.nameController.text.trim(),
        priceCents: modPriceCents,
      );
    }).toList();

    // F1-03: Filtrar variaciones sin nombre antes de guardar
    final variations = _hasVariations
        ? _variationEntries
            .where((e) => e.nameController.text.trim().isNotEmpty)
            .map((e) {
              final priceText = e.priceController.text.replaceAll(',', '.');
              final varPriceCents =
                  ((double.tryParse(priceText) ?? 0) * 100).round();
              final varStock = int.tryParse(e.stockController.text) ?? 0;
              return MenuItemVariation(
                id: e.id,
                name: e.nameController.text.trim(),
                priceCents: varPriceCents,
                stock: varStock,
              );
            }).toList()
        : <MenuItemVariation>[];

    if (_hasVariations && variations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una variación con nombre.')),
      );
      return;
    }

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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl * 1.5),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl * 1.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ]
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note : Icons.add_circle_outline,
                    color: AppColors.primaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Editar Plato' : 'Nuevo Plato',
                    style: AppTypography.h2(color: AppColors.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card 1: Detalles Básicos
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Detalles Básicos', style: AppTypography.h3(color: AppColors.primaryContainer)),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _nameController,
                                style: AppTypography.bodyMd(color: AppColors.onSurface),
                                decoration: _inputDecoration('Nombre del plato'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              DropdownButtonFormField<String>(
                                initialValue: _category,
                                dropdownColor: Colors.white,
                                style: AppTypography.bodyMd(color: AppColors.onSurface),
                                decoration: _inputDecoration('Categoría'),
                                items: widget.categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _category = v);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Text('Disponible en menú', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                                  const Spacer(),
                                  Switch(
                                    value: _available,
                                    onChanged: (v) => setState(() => _available = v),
                                    activeColor: AppColors.primaryContainer,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Card 2: Precios y Variaciones
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppSpacing.sm,
                                children: [
                                  Text('Precios y Variaciones', style: AppTypography.h3(color: AppColors.primaryContainer)),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('¿Tiene variaciones?', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                                      const SizedBox(width: AppSpacing.sm),
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
                                ],
                              ),
                              const Divider(),
                              if (!_hasVariations) ...[
                                // Precio
                                TextFormField(
                                  controller: _priceController,
                                  style: AppTypography.bodyMd(color: AppColors.onSurface),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration('Precio Base (€)').copyWith(
                                    prefixIcon: const Icon(Icons.euro, size: 16, color: Color(0xFFF26522)),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Requerido';
                                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                                    if (parsed == null || parsed < 0) return 'Inválido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                // Stock stepper
                                _buildStockStepper(
                                  label: 'Stock disponible',
                                  controller: _stockController,
                                ),
                              ],
                              if (_hasVariations) ...[
                                ..._variationEntries.asMap().entries.map((entry) =>
                                  _buildVariationCard(entry.key, entry.value),
                                ),
                                const SizedBox(height: 4),
                                _buildAddVariationButton(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Card 3: Modificadores
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modificadores Opcionales', style: AppTypography.h3(color: AppColors.primaryContainer)),
                              Text('Ingredientes extra o exclusiones (ej: Sin cebolla, Extra queso)', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                              const Divider(),
                              ..._modifierEntries.asMap().entries.map((entry) {
                                final index = entry.key;
                                final modifier = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: modifier.nameController,
                                          style: AppTypography.bodyMd(color: AppColors.onSurface),
                                          decoration: _inputDecoration('Nombre'),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          controller: modifier.priceController,
                                          style: AppTypography.bodyMd(color: AppColors.onSurface),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: _inputDecoration('Precio (+€)'),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle, color: AppColors.error),
                                        onPressed: () => _removeModifierEntry(index),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _addModifierEntry,
                                  icon: const Icon(Icons.add, color: AppColors.primaryContainer),
                                  label: Text('Añadir Modificador', style: AppTypography.statusBadge(color: AppColors.primaryContainer)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl * 1.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar', style: AppTypography.statusBadge(color: AppColors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    label: Text(_isEditing ? 'Guardar Cambios' : 'Crear Plato'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Variations section UI ──────────────────────────────────────────────
  Widget _buildVariationCard(int index, _VariationEntry variation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Variation header
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Variación',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF26522),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Nombre field
                  TextFormField(
                    controller: variation.nameController,
                    style: const TextStyle(
                      color: Color(0xFF131D21),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration('Nombre (ej: Mediano, Grande)'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nombre requerido' : null,
                  ),
                  const SizedBox(height: 8),
                  // Precio y Stock en row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: variation.priceController,
                          style: const TextStyle(
                            color: Color(0xFF131D21),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDecoration('Precio (€)').copyWith(
                            prefixIcon: const Icon(Icons.euro, size: 16, color: Color(0xFFF26522)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Stock stepper para la variación
                  _buildStockStepper(
                    label: 'Stock inicial',
                    controller: variation.stockController,
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFFBA1A1A), size: 20),
              tooltip: 'Eliminar variación',
              onPressed: () => _removeVariationEntry(index),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add variation button as dashed card ──────────────────────────────────
  Widget _buildAddVariationButton() {
    return GestureDetector(
      onTap: _addVariationEntry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.5),
            width: 1.5,
            // Dashed effect via a custom approach
          ),
          color: AppColors.primaryContainer.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Añadir nueva variación',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF26522),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable stock stepper ───────────────────────────────────────────
  Widget _buildStockStepper({
    required String label,
    required TextEditingController controller,
  }) {
    final current = int.tryParse(controller.text) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2D5D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFFF26522)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF594138),
              ),
            ),
          ),
          // Minus button
          GestureDetector(
            onTap: () {
              if (current > 0) {
                setState(() => controller.text = '${current - 1}');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: current > 0
                    ? AppColors.primaryContainer.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.remove,
                size: 18,
                color: current > 0 ? AppColors.primaryContainer : Colors.grey.shade400,
              ),
            ),
          ),
          // Count display
          Container(
            width: 52,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              '$current',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF131D21),
              ),
            ),
          ),
          // Plus button
          GestureDetector(
            onTap: () {
              setState(() => controller.text = '${current + 1}');
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF594138),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF26522), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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


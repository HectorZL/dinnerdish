import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/menu_item.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final isMobile = !isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                StitchTopAppBar(
                  navLinks: isDesktop
                      ? const [
                          NavLink('Panel', false),
                          NavLink('Inventario', true),
                          NavLink('Reportes', false),
                        ]
                      : null,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildOverviewCard(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildFilters(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildInventoryTable(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavBar(currentUser) : null,
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 320,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xl),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: AppColors.primaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Principal',
                          style: AppTypography.bodyLg(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A))),
                      Text('Gestión Global',
                          style: AppTypography.bodyMd(
                              color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildNavItem(Icons.group_outlined, 'Usuarios', false, context),
            _buildNavItem(
                Icons.inventory_2, 'Inventario', true, context),
            _buildNavItem(
                Icons.bar_chart_outlined, 'Reportes', false, context),
            _buildNavItem(
                Icons.settings_outlined, 'Ajustes', false, context),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VERSIÓN',
                      style: AppTypography.labelCaps(
                          color: const Color(0xFF94A3B8))),
                  Text('v1.0.4',
                      style: AppTypography.bodyMd(
                          color: const Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String title, bool isActive, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF7ED) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isActive
            ? const Border(
                right: BorderSide(color: AppColors.primaryContainer, width: 4))
            : null,
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isActive
                ? AppColors.primaryContainer
                : const Color(0xFF475569)),
        title: Text(title,
            style: AppTypography.bodyMd(
                color: isActive
                    ? AppColors.primaryContainer
                    : const Color(0xFF475569))),
        onTap: () {
          switch (title) {
            case 'Usuarios':
              context.go('/admin/users');
            case 'Reportes':
              context.go('/admin/reports');
          }
        },
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
    );
  }

  Widget _buildBottomNavBar(dynamic currentUser) {
    return StitchBottomNavBar(
      currentRoute: '/admin/inventory',
      currentUser: currentUser,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestión de Inventario',
                  style: AppTypography.h1(color: AppColors.onBackground)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Supervisa el stock actual de tus platos y variaciones en tiempo real.',
                  style: AppTypography.bodyMd(color: AppColors.secondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    final menuItemsAsync = ref.watch(menuItemsProvider);
    return menuItemsAsync.when(
      data: (items) {
        int lowStockCount = 0;
        double totalValue = 0.0;

        for (var item in items) {
          if (item.variations.isNotEmpty) {
            for (var v in item.variations) {
              totalValue += (v.priceCents / 100) * v.stock;
              if (v.stock <= 5) {
                lowStockCount++;
              }
            }
          } else {
            totalValue += (item.priceCents / 100) * item.stock;
            if (item.stock <= 5) {
              lowStockCount++;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [AppShadows.card],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Icon(Icons.warning,
                              color: AppColors.error, size: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.base,
                              vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text('Crítico',
                              style: AppTypography.statusBadge(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text('$lowStockCount',
                        style: AppTypography.h2(color: AppColors.onBackground)),
                    Text('Platos con Stock Bajo',
                        style: AppTypography.bodyMd(
                            color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [AppShadows.card],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(Icons.payments,
                          color: Color(0xFF3B82F6), size: 22),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text('${totalValue.toStringAsFixed(2)}€',
                        style: AppTypography.h2(color: AppColors.onBackground)),
                    Text('Valor Total del Stock',
                        style: AppTypography.bodyMd(
                            color: const Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => const SizedBox(height: 100, child: Center(child: Text('Error al cargar resumen'))),
    );
  }

  Widget _buildFilters() {
    return TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar plato o variación...',
        hintStyle: AppTypography.bodyMd(color: const Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildInventoryTable() {
    final menuItemsAsync = ref.watch(menuItemsProvider);

    return menuItemsAsync.when(
      data: (items) {
        final filteredItems = items.where((item) {
          final nameMatch = item.name.toLowerCase().contains(_searchQuery);
          final catMatch = item.category.toLowerCase().contains(_searchQuery);
          final varMatch = item.variations.any((v) => v.name.toLowerCase().contains(_searchQuery));
          return nameMatch || catMatch || varMatch;
        }).toList();

        if (filteredItems.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Center(
              child: Text('No hay platos que coincidan con la búsqueda'),
            ),
          );
        }

        // Flattens dishes and variations to individual rows for the stock table
        final List<_StockTableRowData> rowsData = [];
        for (var item in filteredItems) {
          if (item.variations.isNotEmpty) {
            for (var v in item.variations) {
              rowsData.add(_StockTableRowData(
                item: item,
                variationId: v.id,
                name: '${item.name} (${v.name})',
                category: item.category,
                stock: v.stock,
                priceCents: v.priceCents,
              ));
            }
          } else {
            rowsData.add(_StockTableRowData(
              item: item,
              variationId: null,
              name: item.name,
              category: item.category,
              stock: item.stock,
              priceCents: item.priceCents,
            ));
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [AppShadows.card],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.7),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columnSpacing: AppSpacing.lg,
                    horizontalMargin: AppSpacing.md,
                    columns: const [
                      DataColumn(label: Text('Plato / Variación',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Categoría',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Stock Actual',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Precio',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Estado',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                      DataColumn(label: Text('Acciones',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    ],
                    rows: rowsData.map((data) => _buildDataRow(data)).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error al cargar inventario: $err')),
    );
  }

  DataRow _buildDataRow(_StockTableRowData data) {
    Color statusColor;
    String status;

    if (data.stock == 0) {
      status = 'Agotado';
      statusColor = AppColors.error;
    } else if (data.stock <= 5) {
      status = 'Stock Bajo';
      statusColor = AppColors.statusCooking;
    } else {
      status = 'Óptimo';
      statusColor = AppColors.statusReady;
    }

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.restaurant, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.name,
                    style: AppTypography.bodyMd(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
                if (data.variationId != null)
                  Text('Variación',
                      style: AppTypography.bodyMd(
                          fontSize: 10,
                          color: AppColors.primaryContainer))
                else
                  Text('Plato Base',
                      style: AppTypography.bodyMd(
                          fontSize: 10,
                          color: const Color(0xFF64748B))),
              ],
            ),
          ],
        )),
        DataCell(Text(data.category,
            style: AppTypography.bodyMd(color: const Color(0xFF475569)))),
        DataCell(Center(
          child: Text('${data.stock}',
              style: AppTypography.h3(
                  color: statusColor,
                  fontWeight: FontWeight.bold)),
        )),
        DataCell(Text('${(data.priceCents / 100).toStringAsFixed(2)}€',
            style: AppTypography.bodyMd(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B)))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(status,
                  style: AppTypography.statusBadge(color: statusColor)),
            ],
          ),
        )),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_road, size: 20, color: AppColors.primaryContainer),
              tooltip: 'Ajustar Stock',
              onPressed: () => _showAdjustStockDialog(data),
            ),
          ],
        )),
      ],
    );
  }

  Future<void> _showAdjustStockDialog(_StockTableRowData data) async {
    final TextEditingController controller = TextEditingController(text: data.stock.toString());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Text(
          'Ajustar Stock',
          style: AppTypography.h2(color: AppColors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajustar el stock de "${data.name}"',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              decoration: InputDecoration(
                labelText: 'Nuevo Stock',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: AppTypography.statusBadge(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newStock = int.tryParse(controller.text);
      if (newStock != null && newStock >= 0) {
        final change = newStock - data.stock;
        await ref.read(menuServiceProvider).adjustStock(data.item.id, data.variationId, change);
        ref.invalidate(menuItemsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock actualizado correctamente')),
          );
        }
      }
    }
  }
}

class _StockTableRowData {
  final MenuItem item;
  final String? variationId;
  final String name;
  final String category;
  final int stock;
  final int priceCents;

  _StockTableRowData({
    required this.item,
    required this.variationId,
    required this.name,
    required this.category,
    required this.stock,
    required this.priceCents,
  });
}

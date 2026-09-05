import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/models/table.dart' as table_model;
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/router/route_guards.dart';
import '../theme/app_theme.dart';

class TableManagementScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const TableManagementScreen({this.initialFilter, super.key});

  @override
  ConsumerState<TableManagementScreen> createState() =>
      _TableManagementScreenState();
}

class _TableManagementScreenState extends ConsumerState<TableManagementScreen> {
  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialFilter ?? 'all';
  }

  Future<void> _showTableForm({table_model.Table? existing}) async {
    final table = await showDialog<table_model.Table>(
      context: context,
      builder: (_) => _TableFormDialog(existing: existing),
    );
    if (table == null) return;

    try {
      final service = ref.read(tableServiceProvider);
      if (existing == null) {
        await service.createTable(table);
      } else {
        await service.updateTable(existing.id, table);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la mesa: $error')),
      );
    }
  }

  Order? _findActiveOrderForTable(table_model.Table table, List<Order> activeOrders) {
    try {
      return activeOrders.firstWhere(
        (o) => o.tableId == table.id || o.tableId == table.number.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  void _openTable(
    table_model.Table table,
    Order? activeOrder,
    bool canManage,
  ) {
    if (activeOrder != null) {
      _showTableDishesDialog(table, activeOrder);
    } else if (canManage) {
      _showTableForm(existing: table);
    }
  }

  void _showTableDishesDialog(table_model.Table table, Order order) {
    final currentUser = ref.read(currentUserProvider).value;
    final waiterDisplay = (currentUser != null && currentUser.id == order.waiterId)
        ? currentUser.name
        : (order.waiterId.length > 8
            ? 'Mesero #${order.waiterId.substring(0, 6).toUpperCase()}'
            : (order.waiterId.isEmpty ? 'No asignado' : order.waiterId));
    final shortOrderId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with close button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          table.number.toString().padLeft(2, '0'),
                          style: AppTypography.h3(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mesa ${table.number} • Platos Activos',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (table.section != null && table.section!.isNotEmpty)
                                ? table.section!
                                : 'Salón Principal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 22),
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: 'Cerrar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Meta Info Box (Mesero & Comanda)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Waiter
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                waiterDisplay,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        color: const Color(0xFFCBD5E1),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      // Comanda
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            '#$shortOrderId',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section title
                Text(
                  'Platos servidos y en cocina (${order.items.length}):',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),

                // Dish Items List
                if (order.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No hay platos registrados en esta mesa aún.'),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: order.items.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final item = order.items[idx];
                        Color statusColor;
                        Color statusBg;
                        String statusText;
                        switch (item.status) {
                          case oi.OrderStatus.pending:
                            statusColor = const Color(0xFFD97706);
                            statusBg = const Color(0xFFFEF3C7);
                            statusText = 'Pendiente';
                            break;
                          case oi.OrderStatus.sent:
                            statusColor = const Color(0xFF2563EB);
                            statusBg = const Color(0xFFDBEAFE);
                            statusText = 'Enviado';
                            break;
                          case oi.OrderStatus.preparing:
                            statusColor = AppColors.statusCooking;
                            statusBg = AppColors.statusCooking.withValues(alpha: 0.15);
                            statusText = 'En Cocina';
                            break;
                          case oi.OrderStatus.ready:
                            statusColor = const Color(0xFF059669);
                            statusBg = const Color(0xFFD1FAE5);
                            statusText = 'Listo';
                            break;
                          case oi.OrderStatus.served:
                            statusColor = AppColors.primaryContainer;
                            statusBg = AppColors.primaryContainer.withValues(alpha: 0.15);
                            statusText = 'Servido';
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'x${item.quantity}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name ?? 'Plato',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                    if (item.notes != null && item.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Nota: ${item.notes}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 18),

                // Button "Ver Comanda Completa"
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/orders/${order.id}');
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Ver Comanda Completa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);
    final activeOrders = ref.watch(activeOrdersProvider).value ?? <Order>[];
    final currentUser = ref.watch(currentUserProvider).value;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final canManage = RouteGuard.canAccessAdmin(
      currentUser,
      ref.watch(rolePermissionsProvider),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          StitchTopAppBar(
            title: 'Mesas',
            showBack: true,
            onBack: () => context.go('/menu'),
            navLinks: isDesktop
                ? [
                    const NavLink('Inicio', false, route: '/menu'),
                    const NavLink('Pedidos', false, route: '/orders/tracking'),
                    const NavLink('Mesas', true, route: '/tables'),
                    if (canManage)
                      const NavLink('Menú', false, route: '/admin/menu'),
                  ]
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(canManage),
                      const SizedBox(height: AppSpacing.lg),
                      tablesAsync.when(
                        data: (tables) {
                          final occupiedCount = tables
                              .where((t) => t.status == table_model.TableStatus.occupied)
                              .length;
                          final availableCount = tables
                              .where((t) => t.status == table_model.TableStatus.available)
                              .length;
                          final reservedCount = tables
                              .where((t) => t.status == table_model.TableStatus.reserved)
                              .length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filter Chips
                              _buildFilterBar(
                                total: tables.length,
                                occupied: occupiedCount,
                                available: availableCount,
                                reserved: reservedCount,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildTableGrid(
                                _filterTables(tables),
                                activeOrders,
                                canManage,
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => Center(
                          child: Text('No se pudieron cargar las mesas: $error'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? StitchBottomNavBar(
              currentRoute: '/tables',
              currentUser: currentUser,
            )
          : null,
    );
  }

  List<table_model.Table> _filterTables(List<table_model.Table> tables) {
    switch (_statusFilter) {
      case 'occupied':
        return tables.where((t) => t.status == table_model.TableStatus.occupied).toList();
      case 'available':
        return tables.where((t) => t.status == table_model.TableStatus.available).toList();
      case 'reserved':
        return tables.where((t) => t.status == table_model.TableStatus.reserved).toList();
      default:
        return tables;
    }
  }

  Widget _buildFilterBar({
    required int total,
    required int occupied,
    required int available,
    required int reserved,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'Todas ($total)', AppColors.onSurface),
          const SizedBox(width: 8),
          _buildFilterChip('occupied', 'Ocupadas con Platos ($occupied)', AppColors.primaryContainer),
          const SizedBox(width: 8),
          _buildFilterChip('available', 'Disponibles ($available)', AppColors.tertiaryContainer),
          const SizedBox(width: 8),
          _buildFilterChip('reserved', 'Reservadas ($reserved)', const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: color,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : const Color(0xFFE2E8F0),
        width: isSelected ? 1.5 : 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Widget _buildHeader(bool canManage) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista de Salón y Platos por Mesa', style: AppTypography.h2()),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Toca cualquier mesa ocupada para revisar los platos que se están preparando o sirviendo.',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        if (canManage)
          SizedBox(
            width: 170,
            child: StitchPrimaryButton(
              label: 'Nueva mesa',
              icon: Icons.add,
              onPressed: _showTableForm,
            ),
          ),
      ],
    );
  }

  Widget _buildTableGrid(
    List<table_model.Table> tables,
    List<Order> activeOrders,
    bool canManage,
  ) {
    if (tables.isEmpty) {
      return StitchCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.table_restaurant_outlined,
                size: 48,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _statusFilter == 'occupied'
                    ? 'No hay mesas ocupadas actualmente'
                    : 'No hay mesas configuradas',
                style: AppTypography.h3(),
              ),
              if (canManage) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: 180,
                  child: StitchPrimaryButton(
                    label: 'Crear mesa',
                    icon: Icons.add,
                    onPressed: _showTableForm,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final cardWidth = isMobile
            ? constraints.maxWidth
            : (constraints.maxWidth > 900 ? (constraints.maxWidth - 32) / 3 : (constraints.maxWidth - 16) / 2);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tables.map((table) {
            final activeOrder = _findActiveOrderForTable(table, activeOrders);
            return _TableCard(
              width: cardWidth,
              table: table,
              activeOrder: activeOrder,
              canManage: canManage,
              onTap: () => _openTable(table, activeOrder, canManage),
              onEdit: canManage ? () => _showTableForm(existing: table) : null,
            );
          }).toList(),
        );
      },
    );
  }
}

class _TableCard extends StatelessWidget {
  final double width;
  final table_model.Table table;
  final Order? activeOrder;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _TableCard({
    required this.width,
    required this.table,
    this.activeOrder,
    required this.canManage,
    required this.onTap,
    this.onEdit,
  });

  Color get _statusColor {
    switch (table.status) {
      case table_model.TableStatus.available:
        return AppColors.tertiaryContainer;
      case table_model.TableStatus.occupied:
        return AppColors.primaryContainer;
      case table_model.TableStatus.reserved:
        return const Color(0xFF3B82F6);
    }
  }

  String get _statusLabel {
    switch (table.status) {
      case table_model.TableStatus.available:
        return 'Disponible';
      case table_model.TableStatus.occupied:
        return 'Ocupada';
      case table_model.TableStatus.reserved:
        return 'Reservada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDishes = activeOrder != null && activeOrder!.items.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: _statusColor.withValues(alpha: table.status == table_model.TableStatus.occupied ? 0.6 : 0.25),
              width: table.status == table_model.TableStatus.occupied ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _statusColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Table number circle, capacity & actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor.withValues(alpha: 0.12),
                      border: Border.all(color: _statusColor, width: 3),
                    ),
                    child: Text(
                      table.number.toString().padLeft(2, '0'),
                      style: AppTypography.h3(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mesa ${table.number}',
                              style: AppTypography.bodyMd(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                _statusLabel.toUpperCase(),
                                style: AppTypography.statusBadge(
                                  color: _statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${table.seats} comensales',
                          style: AppTypography.bodyMd(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Editar mesa',
                      color: const Color(0xFF94A3B8),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onEdit,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: AppSpacing.sm),

              // Dishes breakdown in this table
              if (hasDishes) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'PLATOS EN MESA (${activeOrder!.items.length}):',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelCaps(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      '#${activeOrder!.id.length > 6 ? activeOrder!.id.substring(0, 6).toUpperCase() : activeOrder!.id.toUpperCase()}',
                      style: AppTypography.statusBadge(
                        color: const Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Show up to 3 dishes
                ...activeOrder!.items.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'x${item.quantity}',
                            style: AppTypography.statusBadge(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name ?? 'Plato',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (activeOrder!.items.length > 3)
                  Text(
                    '+${activeOrder!.items.length - 3} platos más...',
                    style: AppTypography.statusBadge(
                      color: AppColors.primaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 14, color: AppColors.primaryContainer),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Toca para ver detalle de platos',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.statusBadge(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (table.status == table_model.TableStatus.occupied) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: AppColors.primaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ocupada • Sin comanda activa',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.statusBadge(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: const Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mesa libre • Lista para servicio',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.statusBadge(color: const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TableFormDialog extends StatefulWidget {
  final table_model.Table? existing;

  const _TableFormDialog({this.existing});

  @override
  State<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<_TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _seatsController;
  late table_model.TableStatus _status;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: widget.existing?.number.toString() ?? '',
    );
    _seatsController = TextEditingController(
      text: widget.existing?.seats.toString() ?? '4',
    );
    _status = widget.existing?.status ?? table_model.TableStatus.available;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final number = int.parse(_numberController.text.trim());
    final seats = int.parse(_seatsController.text.trim());

    final table = table_model.Table(
      id: widget.existing?.id ?? 'table-$number',
      number: number,
      seats: seats,
      status: _status,
      section: widget.existing?.section,
    );

    Navigator.of(context).pop(table);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl * 1.5),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl * 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_restaurant,
                    color: AppColors.primaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Editar Mesa' : 'Nueva Mesa',
                    style: AppTypography.h2(color: AppColors.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _numberController,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: _inputDecoration('Número de Mesa'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _seatsController,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: _inputDecoration('Capacidad (comensales)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Capacidad inválida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<table_model.TableStatus>(
                      initialValue: _status,
                      dropdownColor: Colors.white,
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                      decoration: _inputDecoration('Estado'),
                      items: const [
                        DropdownMenuItem(
                          value: table_model.TableStatus.available,
                          child: Text('Disponible'),
                        ),
                        DropdownMenuItem(
                          value: table_model.TableStatus.occupied,
                          child: Text('Ocupada'),
                        ),
                        DropdownMenuItem(
                          value: table_model.TableStatus.reserved,
                          child: Text('Reservada'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    StitchPrimaryButton(
                      label: _isEditing ? 'Guardar Cambios' : 'Crear Mesa',
                      icon: _isEditing ? Icons.save : Icons.add,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';

enum DishHistoryPeriod {
  day,
  week,
  month,
  total,
}

class DishHistoryScreen extends ConsumerStatefulWidget {
  const DishHistoryScreen({super.key});

  @override
  ConsumerState<DishHistoryScreen> createState() => _DishHistoryScreenState();
}

class _DishHistoryScreenState extends ConsumerState<DishHistoryScreen> {
  DishHistoryPeriod _selectedPeriod = DishHistoryPeriod.day;
  String? _selectedWaiterId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ref.read(userServiceProvider).fetchUsers();
      if (mounted) setState(() => _users = users);
    } catch (_) {}
  }

  User? _findUser(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  String _getWaiterDisplayName(String waiterId) {
    if (waiterId.isEmpty) return 'No asignado';
    final user = _findUser(waiterId);
    if (user != null) return user.name;
    return waiterId;
  }

  bool _isDateInPeriod(DateTime date, DishHistoryPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case DishHistoryPeriod.day:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case DishHistoryPeriod.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return date.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      case DishHistoryPeriod.month:
        return date.year == now.year && date.month == now.month;
      case DishHistoryPeriod.total:
        return true;
    }
  }

  String _getPeriodLabel(DishHistoryPeriod period) {
    switch (period) {
      case DishHistoryPeriod.day:
        return 'Día (Hoy)';
      case DishHistoryPeriod.week:
        return 'Esta Semana';
      case DishHistoryPeriod.month:
        return 'Este Mes';
      case DishHistoryPeriod.total:
        return 'Total Histórico';
    }
  }

  Color _getItemStatusColor(oi.OrderStatus status) {
    switch (status) {
      case oi.OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case oi.OrderStatus.sent:
        return const Color(0xFF3B82F6);
      case oi.OrderStatus.preparing:
        return AppColors.statusCooking;
      case oi.OrderStatus.ready:
        return const Color(0xFF10B981);
      case oi.OrderStatus.served:
        return AppColors.primaryContainer;
    }
  }

  String _getItemStatusLabel(oi.OrderStatus status) {
    switch (status) {
      case oi.OrderStatus.pending:
        return 'Pendiente';
      case oi.OrderStatus.sent:
        return 'Enviado';
      case oi.OrderStatus.preparing:
        return 'En Preparación';
      case oi.OrderStatus.ready:
        return 'Listo';
      case oi.OrderStatus.served:
        return 'Servido';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final allOrdersAsync = ref.watch(allOrdersProvider);
    final allOrders = allOrdersAsync.value ?? [];
    final isDesktop = MediaQuery.of(context).size.width > 768;

    // Filter orders by period
    final periodOrders = allOrders.where((order) {
      return _isDateInPeriod(order.createdAt, _selectedPeriod);
    }).toList();

    // Flatten into dish items
    final List<_DishRecord> dishRecords = [];
    for (final order in periodOrders) {
      if (_selectedWaiterId != null && _selectedWaiterId!.isNotEmpty) {
        if (order.waiterId != _selectedWaiterId) continue;
      }

      for (final item in order.items) {
        final itemName = item.name ?? 'Plato';
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final matchName = itemName.toLowerCase().contains(q);
          final matchTable = order.tableId.toLowerCase().contains(q);
          final matchWaiter = order.waiterId.toLowerCase().contains(q);
          if (!matchName && !matchTable && !matchWaiter) continue;
        }

        dishRecords.add(_DishRecord(
          orderId: order.id,
          tableId: order.tableId.isEmpty ? 'S/A' : order.tableId,
          waiterId: order.waiterId,
          item: item,
          createdAt: order.createdAt,
        ));
      }
    }

    // Sort newest first
    dishRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Calculate metrics
    final totalDishesCount = dishRecords.fold<int>(0, (sum, r) => sum + r.item.quantity);
    final uniqueTables = dishRecords.map((r) => r.tableId).toSet().length;
    final uniqueWaiters = dishRecords.map((r) => r.waiterId).where((w) => w.isNotEmpty).toSet().length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StitchTopAppBar(
              title: 'Historial de Platos',
              showBack: true,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/menu');
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Registro Operativo de Platos', style: AppTypography.h1()),
                                const SizedBox(height: 4),
                                Text(
                                  'Auditoría y trazabilidad de platos servidos por mesa y personal.',
                                  style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Period Selector Tabs (Día, Semana, Mes, Total)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: DishHistoryPeriod.values.map((period) {
                                final isSelected = _selectedPeriod == period;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedPeriod = period),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryContainer
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                    child: Text(
                                      _getPeriodLabel(period),
                                      style: AppTypography.statusBadge(
                                        color: isSelected ? Colors.white : AppColors.onSurface,
                                        fontWeight:
                                            isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Quick Summary Cards (Without money values)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 650;
                            final cards = [
                              _buildMetricPill(
                                'TOTAL PLATOS',
                                '$totalDishesCount',
                                Icons.restaurant_menu,
                                AppColors.primaryContainer,
                              ),
                              _buildMetricPill(
                                'MESAS ATENDIDAS',
                                '$uniqueTables',
                                Icons.table_restaurant,
                                const Color(0xFF3B82F6),
                              ),
                              _buildMetricPill(
                                'PERSONAL / MESEROS',
                                '$uniqueWaiters',
                                Icons.groups,
                                const Color(0xFF10B981),
                              ),
                            ];

                            if (isWide) {
                              return Row(
                                children: cards.map((c) => Expanded(child: c)).toList(),
                              );
                            }
                            return Column(children: cards);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Filters Bar (Staff / Waiter & Search)
                        StitchCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Waiter / Staff Filter
                              SizedBox(
                                width: isDesktop ? 280 : double.infinity,
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _selectedWaiterId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Filtrar por Mesero / Personal',
                                    prefixIcon: const Icon(Icons.person, size: 20),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Todos los meseros y personal'),
                                    ),
                                    ..._users.map((u) {
                                      return DropdownMenuItem<String?>(
                                        value: u.id,
                                        child: Text(
                                          '${u.name} (${u.id})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) => setState(() => _selectedWaiterId = val),
                                ),
                              ),
                              // Search input
                              SizedBox(
                                width: isDesktop ? 300 : double.infinity,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    labelText: 'Buscar plato o mesa...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.lg),
                                    ),
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Dishes Table
                        StitchCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.xl),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'PLATO',
                                        style: AppTypography.labelCaps(
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        'CANT.',
                                        style: AppTypography.labelCaps(
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'MESA',
                                        style: AppTypography.labelCaps(
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'RESPONSABLE (ID)',
                                        style: AppTypography.labelCaps(
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'ESTADO',
                                        style: AppTypography.labelCaps(
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'HORA',
                                        style: AppTypography.labelCaps(
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Table Rows
                              if (dishRecords.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(36.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.restaurant,
                                            size: 40, color: Color(0xFF94A3B8)),
                                        SizedBox(height: 8),
                                        Text(
                                          'No se encontraron platos registrados en este periodo',
                                          style: TextStyle(color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...dishRecords.map((record) {
                                  final statusColor = _getItemStatusColor(record.item.status);
                                  final waiterName = _getWaiterDisplayName(record.waiterId);

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            // Dish name
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    record.item.name ?? 'Plato',
                                                    style: AppTypography.bodyMd(
                                                      color: AppColors.onSurface,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (record.item.notes != null &&
                                                      record.item.notes!.isNotEmpty)
                                                    Text(
                                                      'Nota: ${record.item.notes}',
                                                      style: AppTypography.statusBadge(
                                                        color: const Color(0xFF94A3B8),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            // Quantity
                                            Expanded(
                                              flex: 1,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryContainer
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(AppRadius.full),
                                                ),
                                                child: Text(
                                                  'x${record.item.quantity}',
                                                  textAlign: TextAlign.center,
                                                  style: AppTypography.statusBadge(
                                                    color: AppColors.primaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Table
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Mesa ${record.tableId}',
                                                style: AppTypography.bodyMd(
                                                  color: AppColors.onSurface,
                                                ),
                                              ),
                                            ),
                                            // Waiter / Staff with ID
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    waiterName,
                                                    style: AppTypography.bodyMd(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    record.waiterId.isEmpty
                                                        ? 'S/ID'
                                                        : record.waiterId,
                                                    style: AppTypography.statusBadge(
                                                      color: const Color(0xFF94A3B8),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Status
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(AppRadius.full),
                                                  ),
                                                  child: Text(
                                                    _getItemStatusLabel(record.item.status),
                                                    style: AppTypography.statusBadge(
                                                      color: statusColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Date / Time
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatDate(record.createdAt),
                                                style: AppTypography.bodyMd(
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    ],
                                  );
                                }),
                            ],
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
      ),
    );
  }

  Widget _buildMetricPill(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [AppShadows.card],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelCaps(color: const Color(0xFF94A3B8))),
              Text(value, style: AppTypography.h2()),
            ],
          ),
        ],
      ),
    );
  }
}

class _DishRecord {
  final String orderId;
  final String tableId;
  final String waiterId;
  final oi.OrderItem item;
  final DateTime createdAt;

  _DishRecord({
    required this.orderId,
    required this.tableId,
    required this.waiterId,
    required this.item,
    required this.createdAt,
  });
}

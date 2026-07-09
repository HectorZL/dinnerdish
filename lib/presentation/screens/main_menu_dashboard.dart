import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../router/route_guards.dart';
import '../theme/app_theme.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/table.dart' as table_model;

class MainMenuDashboardScreen extends ConsumerStatefulWidget {
  const MainMenuDashboardScreen({super.key});

  @override
  ConsumerState<MainMenuDashboardScreen> createState() =>
      _MainMenuDashboardScreenState();
}

class _MainMenuDashboardScreenState
    extends ConsumerState<MainMenuDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(currentUserProvider).value;
    final isLoggedIn = currentUser != null;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrders = activeOrdersAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            StitchTopAppBar(
              navLinks: isDesktop
                  ? [
                      const NavLink('Inicio', true),
                      const NavLink('Pedidos', false),
                      const NavLink('Mesas', false),
                      if (RouteGuard.canAccessAdmin(currentUser))
                        const NavLink('Menú', false),
                    ]
                  : null,
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Summary Section
                        _buildQuickSummary(activeOrders, ref),
                        const SizedBox(height: AppSpacing.lg),
                        // Bento Style Module Grid
                        _buildModuleGrid(isLoggedIn, currentUser),
                        const SizedBox(height: AppSpacing.xl),
                        // Recent Orders Table
                        _buildRecentOrders(activeOrders),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isDesktop ? StitchBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _handleBottomNavTap(index);
        },
      ) : null,
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/menu');
        break;
      case 1:
        context.go('/orders/tracking');
        break;
      case 2:
        context.go('/tables');
        break;
      case 3:
        context.go('/admin/reports');
        break;
      case 4:
        context.go('/admin/menu');
        break;
    }
  }

  Widget _buildQuickSummary(List<Order> activeOrders, WidgetRef ref) {
    final activeCount = activeOrders.length;
    final todayOrders = activeOrders.where((o) => o.createdAt.day == DateTime.now().day).toList();
    final revenue = todayOrders.fold<int>(0, (sum, o) => sum + o.totalCents) / 100;

    final tablesAsync = ref.watch(tablesProvider);
    final tables = tablesAsync.value ?? [];
    final totalTables = tables.length;
    final occupiedTables = tables.where((t) => t.status != table_model.TableStatus.available).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vista General', style: AppTypography.h2()),
                  Text(
                    'Métricas clave de la operación actual.',
                    style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => context.go('/orders/create'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'NUEVO PEDIDO',
                style: AppTypography.statusBadge(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                elevation: 8,
                shadowColor: AppColors.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: isWide ? 2.5 : 1.5,
              children: [
                _buildStatCard('PEDIDOS ACTIVOS', '$activeCount', '+${todayOrders.length} hoy', AppColors.primaryContainer),
                _buildStatCard('MESAS OCUPADAS', '$occupiedTables/$totalTables', null, AppColors.tertiaryContainer,
                    showProgress: true, progressValue: totalTables > 0 ? occupiedTables / totalTables : 0),
                _buildStatCard('FACTURACIÓN', '${revenue.toStringAsFixed(2)}€', null, AppColors.tertiary,
                    showIcon: Icons.trending_up),
                _buildStatCard('TIEMPO MEDIO', '12 min', null, AppColors.error,
                    showIcon: Icons.timer),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String? badge,
    Color accentColor, {
    bool showProgress = false,
    double progressValue = 0,
    IconData? showIcon,
  }) {
    return StitchCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTypography.labelCaps()),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AppTypography.h2()))),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(badge,
                      style: AppTypography.statusBadge(color: AppColors.primaryContainer)),
                ),
              if (showIcon != null)
                Icon(showIcon, color: accentColor, size: 24),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: AppSpacing.base),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: const Color(0xFFF1F5F9),
                color: accentColor,
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleGrid(bool isLoggedIn, dynamic currentUser) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 768;
        return Column(
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - 8 cols
                  Expanded(
                    flex: 8,
                    child: _buildOrdersModule(isLoggedIn, currentUser),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  // Right column - 4 cols
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _buildTablesModule(isLoggedIn, currentUser),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildOrdersModule(isLoggedIn, currentUser),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTablesModule(isLoggedIn, currentUser),
                  if (RouteGuard.canAccessAdmin(currentUser)) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildInventoryModule(isLoggedIn, currentUser),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAdminModule(isLoggedIn, currentUser),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessOrders(currentUser);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrders = activeOrdersAsync.value ?? [];
    
    final inKitchenOrders = activeOrders.where((o) => o.status == OrderStatus.prepping).length;
    final readyOrders = activeOrders.where((o) => o.status == OrderStatus.ready).length;

    return GestureDetector(
      onTap: canAccess ? () => context.go('/orders/create') : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl * 2), // rounded-2xl
          boxShadow: [AppShadows.card],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text('MÓDULO CRÍTICO',
                          style: AppTypography.labelCaps(
                              color: AppColors.primaryContainer)),

                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text('Gestión de Pedidos', style: AppTypography.h2()),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Supervisa las comandas en tiempo real, desde la entrada hasta el servicio.',
                        style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.receipt_long, color: AppColors.primaryContainer, size: 40),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.outdoor_grill, color: AppColors.primaryContainer, size: 20),
                        const SizedBox(width: AppSpacing.base),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EN COCINA',
                                style: AppTypography.statusBadge(
                                    color: const Color(0xFF94A3B8))),
                            Text('$inKitchenOrders Pedidos',
                                style: AppTypography.h3(color: AppColors.onSurface)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.tertiary, size: 20),
                        const SizedBox(width: AppSpacing.base),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('POR SERVIR',
                                style: AppTypography.statusBadge(
                                    color: const Color(0xFF94A3B8))),
                            Text('$readyOrders Listos',
                                style: AppTypography.h3(color: AppColors.onSurface)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessTables(currentUser);
    return GestureDetector(
      onTap: canAccess ? () => context.go('/tables') : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mapa de Mesas', style: AppTypography.h2(color: Colors.white)),
                Icon(Icons.table_restaurant, color: Colors.white.withValues(alpha: 0.8), size: 32),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _buildAvatar('JP'),
                _buildAvatar('MG'),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text('+3',
                        style: AppTypography.statusBadge(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              '3 Reservas para la próxima hora',
              style: AppTypography.bodyMd(color: Colors.white.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'Ver Plano',
                textAlign: TextAlign.center,
                style: AppTypography.statusBadge(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryContainer,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(initials,
            style: AppTypography.statusBadge(color: Colors.white).copyWith(fontSize: 10)),
      ),
    );
  }



  Widget _buildInventoryModule(bool isLoggedIn, dynamic currentUser) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        boxShadow: [AppShadows.card],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(Icons.inventory_2, color: AppColors.primaryContainer, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text('2 CRÍTICOS',
                    style: AppTypography.statusBadge(color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Inventario', style: AppTypography.h3()),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mermas, compras y stock de seguridad automatizado.',
            style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessAdmin(currentUser);
    return GestureDetector(
      onTap: canAccess ? () => context.go('/audit') : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFF131D21),
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Administración', style: AppTypography.h3(color: Colors.white)),
                    Text('Reportes y Configuración',
                        style: AppTypography.bodyMd(color: const Color(0xFF94A3B8))),
                  ],
                ),
                Icon(Icons.settings, color: const Color(0xFF94A3B8), size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rendimiento Mensual',
                    style: AppTypography.statusBadge(color: const Color(0xFF94A3B8))),
                Text('+12.4%',
                    style: AppTypography.statusBadge(color: AppColors.primaryContainer)),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.4, Colors.white24),
                const SizedBox(width: AppSpacing.base),
                _buildBar(0.6, Colors.white24),
                const SizedBox(width: AppSpacing.base),
                _buildBar(0.9, AppColors.primaryContainer),
                const SizedBox(width: AppSpacing.base),
                _buildBar(0.7, Colors.white24),
                const SizedBox(width: AppSpacing.base),
                _buildBar(0.5, Colors.white24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double heightFraction, Color color) {
    return Expanded(
      child: Container(
        height: 64 * heightFraction,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildRecentOrders(List<Order> activeOrders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Últimos Pedidos', style: AppTypography.h2()),
        const SizedBox(height: AppSpacing.md),
        StitchCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('MESA',
                          style: AppTypography.labelCaps(color: const Color(0xFF64748B))),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('ESTADO',
                          style: AppTypography.labelCaps(color: const Color(0xFF64748B))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('TOTAL',
                          style: AppTypography.labelCaps(color: const Color(0xFF64748B))),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('ACCIÓN',
                          style: AppTypography.labelCaps(color: const Color(0xFF64748B))),
                    ),
                  ],
                ),
              ),
              // Table Rows
              if (activeOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('No hay pedidos recientes', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                )
              else
                ...activeOrders.take(5).map((order) {
                  return Column(
                    children: [
                      _buildOrderRow(
                        'Mesa ${order.tableId.isEmpty ? 'S/A' : order.tableId}', 
                        'Salón', 
                        order.status.name, 
                        AppColors.primaryContainer, 
                        '${(order.totalCents / 100).toStringAsFixed(2)}€', 
                        Icons.visibility
                      ),
                      const Divider(height: 1, color: Color(0xFFF8FAFC)),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(
    String tableName,
    String location,
    String status,
    Color statusColor,
    String total,
    IconData actionIcon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tableName,
                    style: AppTypography.bodyMd(
                        color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
                Text(location,
                    style: AppTypography.statusBadge(
                        color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(status,
                      style: AppTypography.statusBadge(color: statusColor)),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(total,
                style: AppTypography.bodyMd(
                    color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Icon(actionIcon, color: AppColors.primaryContainer, size: 20),
          ),
        ],
      ),
    );
  }
}

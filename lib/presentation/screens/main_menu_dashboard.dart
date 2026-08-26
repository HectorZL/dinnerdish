import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../router/route_guards.dart';
import '../theme/app_theme.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/models/table.dart' as table_model;

class MainMenuDashboardScreen extends ConsumerStatefulWidget {
  const MainMenuDashboardScreen({super.key});

  @override
  ConsumerState<MainMenuDashboardScreen> createState() =>
      _MainMenuDashboardScreenState();
}

class _MainMenuDashboardScreenState
    extends ConsumerState<MainMenuDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isLoggedIn = currentUser != null;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrders = activeOrdersAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: (isLoggedIn && RouteGuard.canAccessAdmin(currentUser))
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                    ),
                    child: Text(
                      'SABOR Y HOGAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Inicio'),
                    onTap: () {
                      context.go('/menu');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Pedidos'),
                    onTap: () {
                      context.go('/orders/tracking');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: const Text('Cocina'),
                    onTap: () {
                      context.go('/kds');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.table_restaurant),
                    title: const Text('Mesas'),
                    onTap: () {
                      context.go('/tables');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('Menú'),
                    onTap: () {
                      context.go('/admin/menu');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Usuarios'),
                    onTap: () {
                      context.go('/admin/users');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            StitchTopAppBar(
              navLinks: isDesktop
                  ? [
                      const NavLink('Inicio', true, route: '/menu'),
                      const NavLink(
                        'Pedidos',
                        false,
                        route: '/orders/tracking',
                      ),
                      const NavLink('Mesas', false, route: '/tables'),
                      if (RouteGuard.canAccessAdmin(currentUser))
                        const NavLink('Menú', false, route: '/admin/menu'),
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
                        _buildQuickSummary(activeOrders, ref, currentUser),
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
      bottomNavigationBar:
          (!isDesktop &&
              !(isLoggedIn && RouteGuard.canAccessAdmin(currentUser)))
          ? StitchBottomNavBar(currentRoute: '/menu', currentUser: currentUser)
          : null,
    );
  }

  Widget _buildQuickSummary(
    List<Order> activeOrders,
    WidgetRef ref,
    dynamic currentUser,
  ) {
    final activeCount = activeOrders.length;
    final todayOrders = activeOrders
        .where((o) => o.createdAt.day == DateTime.now().day)
        .toList();
    final revenue =
        todayOrders.fold<int>(0, (sum, o) => sum + o.totalCents) / 100;
    final canViewRevenue = RouteGuard.canAccessPayment(
      currentUser,
      ref.watch(rolePermissionsProvider),
    );

    final tablesAsync = ref.watch(tablesProvider);
    final tables = tablesAsync.value ?? [];
    final totalTables = tables.length;
    final occupiedTables = tables
        .where((t) => t.status != table_model.TableStatus.available)
        .length;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
              crossAxisCount: isWide ? (canViewRevenue ? 3 : 2) : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: isWide ? 1.8 : 1.3,
              children: [
                _buildStatCard(
                  'PEDIDOS ACTIVOS',
                  '$activeCount',
                  '+${todayOrders.length} hoy',
                  AppColors.primaryContainer,
                  onTap: () => context.go('/orders/tracking'),
                ),
                _buildStatCard(
                  'MESAS OCUPADAS',
                  '$occupiedTables/$totalTables',
                  'Ver mesas',
                  AppColors.tertiaryContainer,
                  showProgress: true,
                  progressValue: totalTables > 0
                      ? occupiedTables / totalTables
                      : 0,
                  onTap: () => context.go('/tables?filter=occupied'),
                ),
                if (canViewRevenue)
                  _buildStatCard(
                    'FACTURACIÓN',
                    '${revenue.toStringAsFixed(2)}€',
                    null,
                    AppColors.tertiary,
                    showIcon: Icons.trending_up,
                  ),
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
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: StitchCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: AppTypography.labelCaps()),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: AppTypography.h2()),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.statusBadge(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
        ),
      ),
    );
  }

  Widget _buildModuleGrid(bool isLoggedIn, dynamic currentUser) {
    final modules = <Widget>[];

    if (RouteGuard.canAccessOrders(currentUser)) {
      modules.add(_buildOrdersModule(isLoggedIn, currentUser));
    }

    if (RouteGuard.canAccessKds(currentUser)) {
      modules.add(_buildKdsModule(isLoggedIn, currentUser));
    }

    if (RouteGuard.canAccessPayment(currentUser)) {
      modules.add(_buildCashierModule(isLoggedIn, currentUser));
    }

    if (RouteGuard.canAccessAdmin(currentUser)) {
      modules.add(_buildAdminModule(isLoggedIn, currentUser));
      modules.add(_buildReportModule(isLoggedIn, currentUser));
      modules.add(_buildUserManagementModule(isLoggedIn, currentUser));
    }

    final spacedModules = <Widget>[];
    for (int i = 0; i < modules.length; i++) {
      spacedModules.add(modules[i]);
      if (i < modules.length - 1) {
        spacedModules.add(const SizedBox(height: AppSpacing.lg));
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 768;
        return Column(
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 12, child: Column(children: spacedModules)),
                ],
              )
            else
              Column(children: spacedModules),
          ],
        );
      },
    );
  }

  Widget _buildOrdersModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessOrders(currentUser);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrders = activeOrdersAsync.value ?? [];

    final inKitchenOrders = activeOrders
        .where((o) => o.status == OrderStatus.prepping)
        .length;
    final readyOrders = activeOrders
        .where((o) => o.status == OrderStatus.ready)
        .length;

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Text(
                        'MÓDULO CRÍTICO',
                        style: AppTypography.labelCaps(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text('Gestión de Pedidos', style: AppTypography.h2()),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Supervisa las comandas en tiempo real, desde la entrada hasta el servicio.',
                        style: AppTypography.bodyMd(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
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
                        Icon(
                          Icons.outdoor_grill,
                          color: AppColors.primaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.base),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EN COCINA',
                                style: AppTypography.statusBadge(
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$inKitchenOrders Pedidos',
                                  style: AppTypography.h3(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                        Icon(
                          Icons.check_circle,
                          color: AppColors.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.base),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'POR SERVIR',
                                style: AppTypography.statusBadge(
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$readyOrders Listos',
                                  style: AppTypography.h3(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildKdsModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessKds(currentUser);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrders = activeOrdersAsync.value ?? [];

    final inKitchenOrders = activeOrders
        .where(
          (o) =>
              o.status == OrderStatus.sentToKitchen ||
              o.status == OrderStatus.prepping,
        )
        .length;

    return GestureDetector(
      onTap: canAccess ? () => context.go('/kds') : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFFACC15), // Yellow for kitchen
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFACC15).withValues(alpha: 0.3),
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
                Text(
                  'Pantalla KDS - Cocina',
                  style: AppTypography.h2(color: Colors.black87),
                ),
                const Icon(Icons.kitchen, color: Colors.black87, size: 32),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$inKitchenOrders pedidos pendientes de preparación',
              style: AppTypography.bodyMd(color: Colors.black54),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                'Entrar a Cocina',
                textAlign: TextAlign.center,
                style: AppTypography.statusBadge(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashierModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessPayment(currentUser);
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrders = activeOrdersAsync.value ?? [];

    final pendingPaymentOrders = activeOrders
        .where((o) => o.status == OrderStatus.ready)
        .length;

    return GestureDetector(
      onTap: canAccess ? () => context.go('/cashier/pending') : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981), // Green for money
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                Text(
                  'Caja y Cobros',
                  style: AppTypography.h2(color: Colors.white),
                ),
                const Icon(Icons.point_of_sale, color: Colors.white, size: 32),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$pendingPaymentOrders pedidos listos para cobro',
              style: AppTypography.bodyMd(color: Colors.white70),
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
                'Abrir Caja',
                textAlign: TextAlign.center,
                style: AppTypography.statusBadge(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessAdmin(currentUser);
    return GestureDetector(
      onTap: canAccess ? () => context.go('/admin/reports') : null,
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
                    Text(
                      'Administración',
                      style: AppTypography.h3(color: Colors.white),
                    ),
                    Text(
                      'Reportes y Configuración',
                      style: AppTypography.bodyMd(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.settings, color: const Color(0xFF94A3B8), size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rendimiento Mensual',
                  style: AppTypography.statusBadge(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  '+12.4%',
                  style: AppTypography.statusBadge(
                    color: AppColors.primaryContainer,
                  ),
                ),
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

  Widget _buildAdminModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessAdmin(currentUser);
    return GestureDetector(
      onTap: canAccess ? () => context.go('/admin/menu') : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 145, 54, 163),
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
                    Text(
                      'Administración',
                      style: AppTypography.h3(color: Colors.white),
                    ),
                    Text(
                      'Administrar menu',
                      style: AppTypography.bodyMd(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.settings, color: const Color(0xFF94A3B8), size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Añadir, editar y eliminar platos',
                  style: AppTypography.statusBadge(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementModule(bool isLoggedIn, dynamic currentUser) {
    final canAccess = isLoggedIn && RouteGuard.canAccessAdmin(currentUser);
    return GestureDetector(
      onTap: canAccess ? () => context.go('/admin/users') : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color.fromARGB(195, 192, 22, 22),
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
                    Text(
                      'Administración',
                      style: AppTypography.h3(color: Colors.white),
                    ),
                    Text(
                      'Administrar usuarios',
                      style: AppTypography.bodyMd(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.settings, color: const Color(0xFF94A3B8), size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Añadir, editar y eliminar usuarios',
                  style: AppTypography.statusBadge(
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
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
    // Flatten active orders into dish items
    final recentDishes = <_DishSummaryItem>[];
    for (final order in activeOrders) {
      for (final item in order.items) {
        recentDishes.add(
          _DishSummaryItem(
            orderId: order.id,
            tableName: order.tableId.isEmpty ? 'S/A' : 'Mesa ${order.tableId}',
            waiterId: order.waiterId,
            dishName: item.name ?? 'Plato',
            quantity: item.quantity,
            status: item.status,
            createdAt: order.createdAt,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actividad Reciente de Platos', style: AppTypography.h2()),
                Text(
                  'Seguimiento en tiempo real de platos en servicio.',
                  style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => context.go('/dishes/history'),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: Text(
                'REVISAR HISTORIAL DE PLATOS',
                style: AppTypography.statusBadge(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        StitchCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  children: [
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
                      flex: 4,
                      child: Text(
                        'PLATO / DETALLE',
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
              if (recentDishes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No hay actividad de platos reciente',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                )
              else
                ...recentDishes.take(6).map((dish) {
                  return Column(
                    children: [
                      _buildDishRow(dish),
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

  Widget _buildDishRow(_DishSummaryItem dish) {
    Color statusColor;
    String statusLabel;
    switch (dish.status) {
      case oi.OrderStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pendiente';
        break;
      case oi.OrderStatus.sent:
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'Enviado';
        break;
      case oi.OrderStatus.preparing:
        statusColor = AppColors.statusCooking;
        statusLabel = 'En Cocina';
        break;
      case oi.OrderStatus.ready:
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Listo';
        break;
      case oi.OrderStatus.served:
        statusColor = AppColors.primaryContainer;
        statusLabel = 'Servido';
        break;
    }

    final timeStr =
        '${dish.createdAt.hour.toString().padLeft(2, '0')}:${dish.createdAt.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => context.go('/orders/${dish.orderId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            // Mesa
            Expanded(
              flex: 2,
              child: Text(
                dish.tableName,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd(
                  color: AppColors.onSurface,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            // Plato & Cantidad
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'x${dish.quantity}',
                      style: AppTypography.statusBadge(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      dish.dishName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Responsable (ID)
            Expanded(
              flex: 3,
              child: Text(
                dish.waiterId.isEmpty ? 'S/ID' : dish.waiterId,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ),
            // Estado
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.statusBadge(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Hora
            Expanded(
              flex: 2,
              child: Text(
                timeStr,
                style: AppTypography.bodyMd(color: const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishSummaryItem {
  final String orderId;
  final String tableName;
  final String waiterId;
  final String dishName;
  final int quantity;
  final oi.OrderStatus status;
  final DateTime createdAt;

  _DishSummaryItem({
    required this.orderId,
    required this.tableName,
    required this.waiterId,
    required this.dishName,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/menu_item.dart';
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final allOrdersAsync = ref.watch(allOrdersProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final isMobile = !isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const StitchAdminSidebar(activeTab: 'Reportes'),
          Expanded(
            child: Column(
              children: [
                StitchTopAppBar(
                  navLinks: isDesktop
                      ? const [
                          NavLink('Inicio', false, route: '/menu'),
                          NavLink('Usuarios', false, route: '/admin/users'),
                          NavLink('Menú', false, route: '/admin/menu'),
                          NavLink('Reportes', true, route: '/admin/reports'),
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
                            const SizedBox(height: AppSpacing.xl),
                            _buildBentoGrid(allOrdersAsync.value ?? [], menuItemsAsync.value ?? []),
                            const SizedBox(height: 100),
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

  Widget _buildBottomNavBar(dynamic currentUser) {
    return StitchBottomNavBar(
      currentRoute: '/admin/reports',
      currentUser: currentUser,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            spacing: 10.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Panel de Reportes',
                  style: AppTypography.h2(color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Visualiza el rendimiento de tu negocio en tiempo real.',
                  style: AppTypography.bodyMd(color: AppColors.secondary)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text('Últimos 30 días',
                  style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE1BFB3)),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm+5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StitchPrimaryButton(
              label: 'Exportar PDF',
              icon: Icons.download,
              height: 50,
              width: 160,
              onPressed: () {},
            ),
          ],
        ),
            ],
          ),
        ),
        
      ],
    );
  }

  Widget _buildBentoGrid(List<Order> orders, List<MenuItem> menuItems) {
    double totalSales = 0;
    int billedCount = 0;
    Map<String, int> dishQuantities = {};
    Map<String, double> dishRevenue = {};

    for (var order in orders) {
      if (order.status == OrderStatus.closed || order.status == OrderStatus.billed) {
        billedCount++;
        for (var item in order.items) {
          totalSales += (item.priceCents * item.quantity / 100);
          dishQuantities[item.menuItemId] = (dishQuantities[item.menuItemId] ?? 0) + item.quantity;
          dishRevenue[item.menuItemId] = (dishRevenue[item.menuItemId] ?? 0) + (item.priceCents * item.quantity / 100);
        }
      }
    }
    
    double averageTicket = billedCount > 0 ? totalSales / billedCount : 0;
    var sortedEntries = dishQuantities.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top3 = sortedEntries.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Column(
          children: [
            // KPI Row
            Row(
              children: [
                _buildKpiCard(
                  'Ventas Totales',
                  '${totalSales.toStringAsFixed(2)}€',
                  '+0%',
                  Icons.payments,
                  const Color(0xFFFFF7ED),
                  AppColors.primaryContainer,
                  Colors.green,
                ),
                const SizedBox(width: AppSpacing.gutter),
                _buildKpiCard(
                  'Tickets Medios',
                  '${averageTicket.toStringAsFixed(2)}€',
                  '+0%',
                  Icons.receipt_long,
                  const Color(0xFFEFF6FF),
                  const Color(0xFF3B82F6),
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),

            // Main Charts Row
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildSalesChart()),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(flex: 6, child: _buildTopSellers(top3, dishRevenue, menuItems)),
                ],
              )
            else ...[
              _buildSalesChart(),
              const SizedBox(height: AppSpacing.gutter),
              _buildTopSellers(top3, dishRevenue, menuItems),
            ],
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(
    String label,
    String value,
    String trend,
    IconData icon,
    Color bgColor,
    Color iconColor,
    Color trendColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: const Color(0xFFF8FAFC)),
          boxShadow: [AppShadows.card],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label.toUpperCase(),
                    style: AppTypography.labelCaps(
                        color: AppColors.secondary)),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(icon, color: iconColor, size: 14),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Text(value,
                    style: AppTypography.h3(
                        color: AppColors.onBackground)),
                const SizedBox(width: AppSpacing.base),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 2),
                      Text(trend,
                          style: AppTypography.statusBadge(
                              color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Comparado con mes anterior',
                style: AppTypography.bodyMd(
                    color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFF8FAFC)),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Evolución Semanal',
                  style: AppTypography.h3(
                      color: AppColors.onSurface)),
              const Icon(Icons.more_horiz,
                  color: Color(0xFFCBD5E1)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChartBar('LUN', 0.6, 0.7),
                _buildChartBar('MAR', 0.75, 0.85),
                _buildChartBar('MIE', 0.5, 0.6),
                _buildChartBar('JUE', 0.9, 1.0),
                _buildChartBar('VIE', 0.65, 0.8),
                _buildChartBar('SAB', 0.8, 0.9),
                _buildChartBar('DOM', 0.4, 0.5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double bgHeight, double fillHeight) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: (bgHeight).clamp(0.0, 1.0) *
                      200, // relative fill
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer
                        .withValues(alpha: fillHeight),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(label,
              style: AppTypography.statusBadge(
                  color: AppColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildTopSellers(List<MapEntry<String, int>> topDishes, Map<String, double> revenues, List<MenuItem> menuItems) {
    int maxUnits = topDishes.isEmpty ? 1 : topDishes.first.value;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFF8FAFC)),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platos Estrella',
              style: AppTypography.h3(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.md),
          if (topDishes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No hay ventas registradas aún.', style: TextStyle(color: Colors.grey)),
            ),
          for (var entry in topDishes) ...[
            Builder(
              builder: (context) {
                final menuItem = menuItems.firstWhere((m) => m.id == entry.key, orElse: () => MenuItem(id: '', name: 'Desconocido', priceCents: 0, category: '', available: true, modifiers: []));
                return _buildTopSellerItem(
                  menuItem.name,
                  '${entry.value} unidades vendidas',
                  maxUnits > 0 ? entry.value / maxUnits : 0,
                  '${(revenues[entry.key] ?? 0).toStringAsFixed(2)}€',
                );
              }
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildTopSellerItem(
    String name,
    String units,
    double progress,
    String revenue,
  ) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.restaurant,
              color: Color(0xFF94A3B8)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTypography.bodyLg(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.xs),
              Text(units,
                  style: AppTypography.bodyMd(
                      color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: AppColors.primaryContainer,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(revenue,
            style: AppTypography.bodyLg(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryContainer)),
      ],
    );
  }


}

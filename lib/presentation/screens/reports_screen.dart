import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isDesktop = MediaQuery.of(context).size.width > 1024;
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
                          NavLink('Inicio', false),
                          NavLink('Pedidos', false),
                          NavLink('Mesas', false),
                          NavLink('Reportes', true),
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
                            _buildBentoGrid(),
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
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(Icons.analytics,
                        color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Principal',
                          style: AppTypography.bodyLg(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface)),
                      Text('Gestión Global',
                          style: AppTypography.bodyMd(
                              color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildNavItem(
                Icons.group_outlined, 'Usuarios', false, context),
            _buildNavItem(Icons.inventory_2_outlined, 'Inventario',
                false, context),
            _buildNavItem(Icons.calculate_outlined, 'Escandallo',
                false, context),
            _buildNavItem(
                Icons.bar_chart, 'Reportes', true, context),
            _buildNavItem(
                Icons.settings_outlined, 'Ajustes', false, context),
            const Spacer(),
            Text('Versión v1.0.4',
                style: AppTypography.labelCaps(
                    color: const Color(0xFF94A3B8))),
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
            case 'Inventario':
              context.go('/admin/inventory');
            case 'Escandallo':
              context.go('/admin/ingredient-assignment');
          }
        },
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
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

  Widget _buildBentoGrid() {
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
                  '12.450€',
                  '+12%',
                  Icons.payments,
                  const Color(0xFFFFF7ED),
                  AppColors.primaryContainer,
                  Colors.green,
                ),
                const SizedBox(width: AppSpacing.gutter),
                _buildKpiCard(
                  'Tickets Medios',
                  '42,50€',
                  '+3%',
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
                  Expanded(flex: 6, child: _buildTopSellers()),
                ],
              )
            else ...[
              _buildSalesChart(),
              const SizedBox(height: AppSpacing.gutter),
              _buildTopSellers(),
            ],
            const SizedBox(height: AppSpacing.gutter),

            // Inventory Heatmap
            _buildInventoryHeatmap(),
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

  Widget _buildTopSellers() {
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
          _buildTopSellerItem(
            'Poke Bowl Salmón',
            '245 unidades vendidas',
            0.85,
            '3.430€',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTopSellerItem(
            'Pizza Margarita Premium',
            '198 unidades vendidas',
            0.70,
            '2.376€',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTopSellerItem(
            'Hamburguesa Black Angus',
            '156 unidades vendidas',
            0.55,
            '2.184€',
          ),
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

  Widget _buildInventoryHeatmap() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consumo crítico de Ingredientes',
                      style: AppTypography.h3(
                          color: AppColors.onSurface)),
                  SizedBox(width: 300,
                  child: Text(
                      'Ingredientes con mayor rotación en las últimas 24 horas.',
                      style: AppTypography.bodyMd(
                          color: AppColors.secondary)),
                  ),
                               TextButton(
                onPressed: () => context.go('/admin/inventory'),
                child: Text('Ver Inventario Completo',
                    style: AppTypography.labelCaps(
                        color: AppColors.primaryContainer)),
              ),
                ],
                 
              ),
            ],
          ),        
          
          const SizedBox(height: AppSpacing.md), SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 10.0,
            children: [
              SizedBox(
                height: 200,
                width: 125,
                child: _buildHeatmapCard(
                'Salmón Noruego',
                'Quedan: 2.5 kg',
                0.15,
                AppColors.error,
                AppColors.errorContainer,
                Icons.warning,
                'Crítico',
              ),
              ),
              SizedBox(
                height: 200,
                width: 125,
                child: _buildHeatmapCard(
                'Aguacate Hass',
                'Quedan: 15 unidades',
                0.35,
                AppColors.statusCooking,
                const Color(0xFFFFF7ED),
                Icons.inventory_2,
                'Bajo',
              ),
              ),
              SizedBox(
                height: 200,
                width: 125,
                child: _buildHeatmapCard(
                'Harina de Trigo',
                'Quedan: 45 kg',
                0.80,
                AppColors.statusReady,
                const Color(0xFFF0FDF4),
                Icons.check_circle,
                'Óptimo',
              ),
              ),
              SizedBox(
                height: 200,
                width: 125,
                child: _buildHeatmapCard(
                'Queso Mozzarella',
                'Quedan: 12 kg',
                0.65,
                AppColors.statusReady,
                const Color(0xFFF0FDF4),
                Icons.check_circle,
                'Óptimo',
              ),
              ),

            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard(
    String name,
    String remaining,
    double progress,
    Color indicatorColor,
    Color bgColor,
    IconData icon,
    String badge,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
              color: indicatorColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: indicatorColor, size: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: 2),
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius:
                        BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(badge,
                      style: AppTypography.statusBadge(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(name,
                style: AppTypography.bodyLg(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground)),
            Text(remaining,
                style: AppTypography.bodyMd(
                    color: AppColors.secondary)),
            const SizedBox(height: AppSpacing.base),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                color: indicatorColor,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

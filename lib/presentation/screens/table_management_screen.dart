import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/models/table.dart' as table_model;
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';

class TableManagementScreen extends ConsumerStatefulWidget {
  const TableManagementScreen({super.key});

  @override
  ConsumerState<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends ConsumerState<TableManagementScreen> {
  int _selectedTableIndex = -1;

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1024;
    final bool isTablet = size.width > 768 && size.width <= 1024;
    final bool isMobile = !isDesktop && !isTablet;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar (Desktop / Tablet)
          if (!isMobile) _buildSidebar(isDesktop),

          // Main Canvas
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopAppBar(isMobile),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.containerPadding,
                            vertical: AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildToolbarLegend(isDesktop),
                            const SizedBox(height: AppSpacing.xl),
                            _buildTableGrid(tablesAsync),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isDesktop && _selectedTableIndex != -1) _buildDetailsSidebar(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu,
                      color: AppColors.primaryContainer),
                  onPressed: () {},
                ),
              if (isMobile) const SizedBox(width: AppSpacing.base),
              Text(
                'GastroGestion',
                style: AppTypography.h1(
                  color: AppColors.primaryContainer,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (!isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SALÓN PRINCIPAL',
                      style: AppTypography.labelCaps(
                          color: const Color(0xFF64748B)),
                    ),
                    Text(
                      '12/24 Mesas Libres',
                      style: AppTypography.bodyMd(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4),
                  ],
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDqi9W_iAlZGSRGBAPUtUY6V_Z0P-g4uKUgnAOui92UixNda83uNO4Ma8gx_jM7807GqxqYZA6TUfAjqS_5sAC3ZFA4aFbDM-I2gw1rBpYo_V8SBaiH0dy-UqF1rNf3PaR1nJMj6ulfCH4A5z7qLsRHQeUvk4qCryjj6XFTqzMy2IYvOTaYb67GQ_kx91JCcjKBk1PEraZZSGWs-9H6lskZ_dkinRCibJSYnQE9M5D5bIw-YOu_kHwqPQy-y4jXLfNAw7lYlYRWOxLX'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDesktop) {
    return SizedBox(
      width: isDesktop ? 320 : 280,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xl),
        child: Column(
          children: [
            // Profile
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
                    child: const Icon(Icons.person, color: Colors.white),
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
            const SizedBox(height: AppSpacing.xl),
            _buildNavItem(Icons.dashboard_outlined, 'Inicio', false, context),
            _buildNavItem(Icons.receipt_long_outlined, 'Pedidos', false, context),
            _buildNavItem(Icons.table_restaurant, 'Mesas', true, context),
            _buildNavItem(Icons.restaurant_menu_outlined, 'Menú', false, context),
            _buildNavItem(Icons.bar_chart_outlined, 'Reportes', false, context),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.md, bottom: AppSpacing.base),
                child: Text(
                  'ADMINISTRACIÓN',
                  style: AppTypography.labelCaps(
                      color: const Color(0xFF94A3B8)),
                ),
              ),
            ),
            _buildNavItem(Icons.group_outlined, 'Usuarios', false, context),
            _buildNavItem(
                Icons.inventory_2_outlined, 'Inventario', false, context),
            _buildNavItem(
                Icons.calculate_outlined, 'Escandallo', false, context),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('v1.0.4',
                    style: AppTypography.bodyMd(
                        color: const Color(0xFF94A3B8))),
                const Icon(Icons.settings_outlined,
                    color: Color(0xFF94A3B8), size: 16),
              ],
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          bottomLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
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
        title: Text(
          title,
          style: AppTypography.bodyMd(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? AppColors.primaryContainer
                : const Color(0xFF475569),
          ),
        ),
        onTap: () => _navigateTo(title, context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        hoverColor: const Color(0xFFF8FAFC),
      ),
    );
  }

  void _navigateTo(String title, BuildContext context) {
    switch (title) {
      case 'Inicio':
        context.go('/menu');
      case 'Pedidos':
        context.go('/orders/tracking');
      case 'Mesas':
        break;
      case 'Menú':
        context.go('/admin/menu');
      case 'Usuarios':
        context.go('/admin/users');
      case 'Inventario':
        context.go('/admin/inventory');
      case 'Escandallo':
        context.go('/admin/ingredient-assignment');
      case 'Reportes':
        context.go('/admin/reports');
    }
  }

  Widget _buildBottomNavBar() {
    return StitchBottomNavBar(
      currentIndex: 2,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/menu');
          case 1:
            context.go('/orders/tracking');
          case 3:
            context.go('/admin/reports');
          case 4:
            context.go('/admin/menu');
        }
      },
    );
  }

  Widget _buildToolbarLegend(bool isDesktop) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista de Salón',
                style: AppTypography.h2(color: AppColors.onBackground)),
            Text(
                'Gestiona la disposición y el estado de las mesas en tiempo real.',
                style: AppTypography.bodyMd(
                    color: const Color(0xFF64748B))),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: const Color(0xFFF8FAFC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem(AppColors.tertiaryContainer, 'LIBRE'),
              const SizedBox(width: AppSpacing.sm),
              _buildLegendItem(AppColors.primaryContainer, 'OCUPADA'),
              const SizedBox(width: AppSpacing.sm),
              _buildLegendItem(const Color(0xFF3B82F6), 'RESERVADA'),
              if (isDesktop) ...[
                const SizedBox(width: AppSpacing.md),
                StitchPrimaryButton(
                  label: 'Nueva Mesa',
                  icon: Icons.add,
                  width: 160,
                  onPressed: () {},
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.base),
        Text(label,
            style: AppTypography.statusBadge(
                color: const Color(0xFF475569))),
      ],
    );
  }

  Widget _buildTableGrid(AsyncValue<List<table_model.Table>> tablesAsync) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 600),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [AppShadows.card],
      ),
      child: tablesAsync.when(
        data: (tables) {
          return Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.xl,
            children: tables.asMap().entries.map((entry) {
              final index = entry.key;
              final table = entry.value;
              
              String statusText = '';
              Color statusColor = AppColors.primaryContainer;
              
              switch (table.status) {
                case table_model.TableStatus.available:
                  statusText = 'DISPONIBLE';
                  statusColor = AppColors.tertiaryContainer;
                  break;
                case table_model.TableStatus.occupied:
                  statusText = 'OCUPADA';
                  statusColor = AppColors.primaryContainer;
                  break;
                case table_model.TableStatus.reserved:
                  statusText = 'RESERVADA';
                  statusColor = const Color(0xFF3B82F6);
                  break;
              }

              return _buildTableCard(
                table.id,
                '${table.seats} Personas',
                statusText,
                statusColor,
                null,
                index,
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTableCard(String id, String capacity, String statusText,
      Color color, String? badgeTag, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTableIndex = _selectedTableIndex == index ? -1 : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.xl),
          border: Border.all(
              color: _selectedTableIndex == index
                  ? color
                  : color.withValues(alpha: 0.1),
              width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (badgeTag != null)
              Positioned(
                top: -12,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    badgeTag,
                    style: AppTypography.statusBadge(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 8),
                  ),
                  child: Center(
                    child: Text(id,
                        style: AppTypography.h2(color: color)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(capacity,
                    style: AppTypography.bodyMd(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155))),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  statusText,
                  style: AppTypography.statusBadge(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDetailsSidebar() {
    return Positioned(
      top: 100,
      right: 48,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mesa 01',
                    style: AppTypography.h3(
                        color: AppColors.onSurface)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: Text(
                    'OCUPADA',
                    style: AppTypography.statusBadge(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppSpacing.md)),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Color(0xFF94A3B8)),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Comensales',
                          style: AppTypography.labelCaps(
                              color: const Color(0xFF94A3B8))),
                      Text('4 Personas',
                          style: AppTypography.bodyMd(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppSpacing.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMANDA ACTUAL',
                      style: AppTypography.labelCaps(
                          color: const Color(0xFF94A3B8))),
                  const SizedBox(height: AppSpacing.sm),
                  _buildReceiptLine('2x Hamburguesa Gourmet', '32.00€'),
                  _buildReceiptLine(
                      '1x Ensalada César', '12.50€'),
                  _buildReceiptLine(
                      '1x Botella Ribera Duero', '24.00€'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL',
                          style: AppTypography.h3(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A))),
                      Text('68.50€',
                          style: AppTypography.h2(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryContainer)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl)),
                      elevation: 0,
                    ),
                    child: const Text('Imprimir'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl)),
                      elevation: 8,
                      shadowColor:
                          AppColors.primaryContainer.withValues(alpha: 0.3),
                    ),
                    child: const Text('Cerrar Caja'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptLine(String item, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item,
              style: AppTypography.bodyMd(
                  color: const Color(0xFF475569))),
          Text(price,
              style: AppTypography.bodyMd(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

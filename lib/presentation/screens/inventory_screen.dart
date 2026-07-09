import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
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
                            _buildOverview(),
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
      bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
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
                Icons.calculate_outlined, 'Escandallo', false, context),
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
            case 'Escandallo':
              context.go('/admin/ingredient-assignment');
            case 'Reportes':
              context.go('/admin/reports');
          }
        },
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
    );
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
          case 2:
            context.go('/tables');
          case 3:
            context.go('/admin/reports');
          case 4:
            context.go('/admin/menu');
        }
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestión de Inventario',
                  style: AppTypography.h1(color: AppColors.onBackground)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Supervisa el stock actual y controla los costes de tus insumos.',
                  style: AppTypography.bodyMd(color: AppColors.secondary)),
                          StitchPrimaryButton(
          label: 'Nuevo Ingrediente',
          icon: Icons.add,
          width: 200,
          onPressed: () {},
        ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildOverview() {
    return Row(
      children: [
        SizedBox(
          width: 360,
          height: 450,
          child:
        Column( 
          spacing: 10,
          children: [
          Flexible(
          flex:3,
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
                    children: [Container(
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
                  ]),

                const SizedBox(height: AppSpacing.base),
                Text('12',
                    style: AppTypography.h2(
                        color: AppColors.onBackground)),
                Text('Stock bajo alerta',
                    style: AppTypography.bodyMd(
                        color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ),
                Flexible(
          flex:3,
          child: Container(
            width: 360,
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
                const SizedBox(height: AppSpacing.sm),
                Text('4.250€',
                    style: AppTypography.h2(
                        color: AppColors.onBackground)),
                Text('Valor total inventario',
                    style: AppTypography.bodyMd(
                        color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        
        Flexible(
          flex: 2,
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
                    Text('Flujo de Abastecimiento',
                        style: AppTypography.bodyLg(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF334155))),
                    const Icon(Icons.more_horiz,
                        color: Color(0xFFCBD5E1)),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        Flexible(
                          flex: 65,
                          child: Container(
                              color: const Color(0xFF34D399)),
                        ),
                        Flexible(
                          flex: 20,
                          child: Container(
                              color: const Color(0xFFFBBF24)),
                        ),
                        Flexible(
                          flex: 15,
                          child:
                              Container(color: const Color(0xFFF87171)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Óptimo 65%',
                        style: AppTypography.labelCaps(
                            color: const Color(0xFF94A3B8))),
                    Text('Pendiente 20%',
                        style: AppTypography.labelCaps(
                            color: const Color(0xFF94A3B8))),
                    Text('Crítico 15%',
                        style: AppTypography.labelCaps(
                            color: const Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
        ),
        ]),
        )
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      spacing: 10,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar ingrediente por nombre o categoría...',
            hintStyle: AppTypography.bodyMd(
                color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search,
                color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm, horizontal: AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
        _buildFilterButton(Icons.filter_list, 'Categoría'),
        _buildFilterButton(Icons.sort, 'Precio'),],)
      ],
    );
  }

  Widget _buildFilterButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: AppTypography.statusBadge(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569))),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
    );
  }

  Widget _buildInventoryTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC)),
              columnSpacing: AppSpacing.lg,
              horizontalMargin: AppSpacing.md,
              columns: const [
                DataColumn(label: Text('Ingrediente',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 11))),
                DataColumn(label: Text('Stock Actual',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 11))),
                DataColumn(label: Text('Unidad',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 11))),
                DataColumn(label: Text('Coste Unit.',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 11))),
                DataColumn(label: Text('Estado',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 11))),
                DataColumn(label: Text('Acciones',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 11))),
              ],
              rows: [
                _buildInventoryRow('Tomate Pera', 'Vegetales', 4.2,
                    'Kilogramos', 1.25, 'Crítico', AppColors.error),
                _buildInventoryRow('Aceite de Oliva', 'Despensa', 15.0,
                    'Litros', 8.40, 'Stock Bajo', AppColors.statusCooking),
                _buildInventoryRow('Pasta Tagliatelle', 'Secos', 45.5,
                    'Kilogramos', 2.15, 'Óptimo', AppColors.statusReady),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  
                  width: 90,
                  child: Text('Mostrando 1-10 de 84 ingredientes',
                    style: AppTypography.bodyMd(
                        color: const Color(0xFF64748B))),
                ),
                Expanded(
                  flex: 2,
                  child:               Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: const Color(0xFF64748B)),
                        ),
                      child: TextButton(
                        onPressed: null,
                        child: Text('Anterior',
                            style: AppTypography.bodyMd(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8)))),
                    ),
                    SizedBox(
                      width: 5,
                      child:TextButton(
                        onPressed: null,
                        child: Text('1',
                            style: AppTypography.bodyMd(
                                fontWeight: FontWeight.bold))),
                    ),
                    SizedBox(
                      width: 5,
                      child:TextButton(
                        onPressed: null,
                        child: Text('2',
                            style: AppTypography.bodyMd(
                                color: const Color(0xFF64748B)))),
                    ),
                    SizedBox(
                      width: 5,
                      child:TextButton(
                        onPressed: null,
                        child: Text('3',
                            style: AppTypography.bodyMd(
                                color: const Color(0xFF64748B)))),
                    ),
                    Container(
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: const Color(0xFF64748B)),
                        ),
                      child:TextButton(
                        onPressed: null,
                        child: Text('Siguiente',
                            style: AppTypography.bodyMd(
                                fontSize: 10,
                                color: const Color(0xFF64748B)))),
                    ),
                  ],
                ),
                ),
 
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildInventoryRow(
    String name,
    String category,
    double stock,
    String unit,
    double cost,
    String status,
    Color statusColor,
  ) {
    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.inventory_2,
                  color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.bodyMd(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B))),
                Text(category,
                    style: AppTypography.bodyMd(
                        color: const Color(0xFF64748B))),
              ],
            ),
          ],
        )),
        DataCell(Center(
          child: Text(stock.toStringAsFixed(1),
              style: AppTypography.h3(
                  color: statusColor,
                  fontWeight: FontWeight.bold)),
        )),
        DataCell(Text(unit,
            style: AppTypography.bodyMd(
                color: const Color(0xFF475569)))),
        DataCell(Text('${cost.toStringAsFixed(2)}€',
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
                  style: AppTypography.statusBadge(
                      color: statusColor)),
            ],
          ),
        )),
        DataCell(IconButton(
          icon: const Icon(Icons.edit,
              size: 20, color: Color(0xFF94A3B8)),
          onPressed: () {},
        )),
      ],
    );
  }
}

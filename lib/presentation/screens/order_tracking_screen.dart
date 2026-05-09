import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final isMobile = !isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildTopAppBar(isDesktop),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: AppSpacing.xl),
                _buildFilters(),
                const SizedBox(height: AppSpacing.xl),
                _buildOrderGrid(isDesktop),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {context.go('/orders/create');},
              backgroundColor: AppColors.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTopAppBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [AppShadows.card],
      ),
      child: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu,
                        color: AppColors.primaryContainer),
                    onPressed: () {},
                  ),
                  const SizedBox(width: AppSpacing.base),
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
                  if (isDesktop) ...[
                    _buildTopNavLink('Inicio', false),
                    const SizedBox(width: AppSpacing.lg),
                    _buildTopNavLink('Pedidos', true),
                    const SizedBox(width: AppSpacing.lg),
                    _buildTopNavLink('Mesas', false),
                    const SizedBox(width: AppSpacing.lg),
                    _buildTopNavLink('Menú', false),
                    const SizedBox(width: AppSpacing.lg),
                    _buildTopNavLink('Reportes', false),
                    const SizedBox(width: AppSpacing.xl),
                  ],
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
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuD8d7ngkMgWVncC79zU-uEc8WKmqqRICRSvYOR6knzSglKle6fiCp9RNgHrioxh_JowosYBe7TwHJgYTM2pWDMoBmvSTArIS5HnuZa5AHWo2CvPgs8Oi4KryxJsTy7swqJbZolob3f55fPe_Y4ajiShyixlOf-1YXEgQzthJcW_Mehq5WAk1Rzx0qIvVT1VAxxsAl-nyqNHsuSPQKgKJT5FWBd_7oxotfbcaB65CnnCz10DJVbXp_WTwXT-Yho3VrxrTM2RrccHuLdy'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavLink(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'Inicio':
            context.go('/menu');
          case 'Pedidos':
            break;
          case 'Mesas':
            context.go('/tables');
          case 'Menú':
            context.go('/admin/menu');
          case 'Reportes':
            context.go('/admin/reports');
        }
      },
      child: Text(
        title,
        style: AppTypography.bodyMd(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          color: isActive
              ? AppColors.primaryContainer
              : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seguimiento en Tiempo Real',
              style: AppTypography.labelCaps(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Gestión de Pedidos',
              style: AppTypography.h1(color: AppColors.onBackground),
            ),
          ],
        ),
        if (!isDesktop) const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            SizedBox(
              width: isDesktop ? 260 : 240,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por mesa o pedido...',
                  hintStyle: AppTypography.bodyMd(
                      color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune, color: Color(0xFF475569)),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = [
      'Todos (24)',
      'Pendiente (4)',
      'En Cocina (8)',
      'Listo (10)',
      'Servido (2)'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final isActive = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: ChoiceChip(
              label: Text(
                filters[index],
                style: AppTypography.statusBadge(
                  color: isActive ? Colors.white : const Color(0xFF475569),
                ),
              ),
              selected: isActive,
              onSelected: (selected) {
                setState(() => _selectedFilterIndex = index);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                    color:
                        isActive ? Colors.transparent : const Color(0xFFF1F5F9)),
              ),
              elevation: isActive ? 4 : 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderGrid(bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.lg,
      mainAxisSpacing: AppSpacing.lg,
      childAspectRatio: isDesktop ? 1.1 : 1.2,
      children: [
        _buildOrderCard(
          table: 'Mesa 12',
          orderId: '#ORD-4921 • 12:45 PM',
          status: 'Pendiente',
          statusColor: AppColors.statusPending,
          bgColor: const Color(0xFFF1F5F9),
          items: [
            {'name': '2x Burger Especial', 'price': '32,00€'},
            {'name': '1x Patatas Bravas', 'price': '8,50€'},
          ],
          actions: [
            _buildActionBtn('Cancelar', Icons.close, false),
            _buildActionBtn('Cocina', Icons.restaurant, true),
          ],
        ),
        _buildOrderCard(
          table: 'Mesa 04',
          orderId: '#ORD-4918 • 12:30 PM',
          status: 'En Cocina',
          statusColor: AppColors.statusCooking,
          bgColor: const Color(0xFFFEF3C7),
          icon: Icons.outdoor_grill,
          warning: 'NOTA: Alergia frutos secos',
          items: [
            {'name': '1x Risotto de Setas', 'price': '18,00€'},
          ],
          progress: 0.65,
          timeText: 'Tiempo transcurrido: 12 min',
          actions: [
            _buildActionBtn('Marcar como Listo', Icons.check_circle, true),
          ],
        ),
        _buildOrderCard(
          table: 'Terraza 02',
          orderId: '#ORD-4912 • 12:15 PM',
          status: 'Listo',
          statusColor: AppColors.statusReady,
          bgColor: AppColors.statusReady,
          textColor: Colors.white,
          icon: Icons.notifications_active,
          items: [
            {'name': '3x Menú del Día', 'price': '45,00€'},
            {'name': '3x Cerveza Mahou', 'price': '7,50€'},
          ],
          actions: [
            _buildActionBtn(
                'Servir a Mesa', Icons.delivery_dining, true),
          ],
        ),
        _buildOrderCard(
          table: 'Mesa 08',
          orderId: '#ORD-4925 • 1:05 PM',
          status: 'En Cocina',
          statusColor: AppColors.statusCooking,
          bgColor: const Color(0xFFFEF3C7),
          icon: Icons.outdoor_grill,
          items: [
            {'name': '1x Solomillo al punto', 'price': '22,50€'},
          ],
          actions: [
            _buildActionBtn('Marcar como Listo', Icons.check_circle, true),
          ],
        ),
        _buildOrderCard(
          table: 'Mesa 15',
          orderId: '#ORD-4930 • 1:12 PM',
          status: 'Listo',
          statusColor: AppColors.statusReady,
          bgColor: AppColors.statusReady,
          textColor: Colors.white,
          icon: Icons.notifications_active,
          items: [
            {'name': '2x Ensalada César', 'price': '24,00€'},
          ],
          actions: [
            _buildActionBtn(
                'Servir a Mesa', Icons.delivery_dining, true),
          ],
        ),
        _buildOrderCard(
          table: 'Barra 03',
          orderId: '#ORD-4935 • 1:15 PM',
          status: 'Pendiente',
          statusColor: AppColors.statusPending,
          bgColor: const Color(0xFFF1F5F9),
          items: [
            {'name': '1x Tapa de Jamón', 'price': '12,00€'},
          ],
          actions: [
            _buildActionBtn('Cancelar', null, false),
            _buildActionBtn('A Cocina', null, true),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderCard({
    required String table,
    required String orderId,
    required String status,
    required Color statusColor,
    required Color bgColor,
    Color textColor = const Color(0xFF475569),
    IconData? icon,
    String? warning,
    required List<Map<String, String>> items,
    double? progress,
    String? timeText,
    required List<Widget> actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border(
          left: const BorderSide(color: Color(0xFFF8FAFC)),
          top: const BorderSide(color: Color(0xFFF8FAFC)),
          right: const BorderSide(color: Color(0xFFF8FAFC)),
          bottom: const BorderSide(color: Color(0xFFF8FAFC)),
        ),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.table_restaurant,
                            color: statusColor, size: 20),
                        const SizedBox(width: AppSpacing.base),
                        Text(table,
                            style: AppTypography.h3(
                                color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(orderId,
                        style: AppTypography.statusBadge(
                            color: const Color(0xFF94A3B8))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: textColor),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        status,
                        style: AppTypography.statusBadge(color: textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warning != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: Color(0xFFB45309)),
                          const SizedBox(width: AppSpacing.base),
                          Text(warning,
                              style: AppTypography.statusBadge(
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.base),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name']!,
                                style: AppTypography.bodyMd(
                                    color: const Color(0xFF475569))),
                            Text(item['price']!,
                                style: AppTypography.bodyMd(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A))),
                          ],
                        ),
                      )),
                  if (progress != null) ...[
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: statusColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(timeText ?? '',
                          style: AppTypography.statusBadge(
                              color: const Color(0xFF94A3B8))),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.md)),
            ),
            child: Row(
              children: actions
                  .map((a) => Expanded(
                      child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: a)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
      String text, IconData? icon, bool isPrimary) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? AppColors.primaryContainer
            : Colors.white,
        foregroundColor:
            isPrimary ? Colors.white : const Color(0xFF475569),
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: AppSpacing.base)],
          Text(text,
              style: AppTypography.statusBadge(
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return StitchBottomNavBar(
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/menu');
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
}

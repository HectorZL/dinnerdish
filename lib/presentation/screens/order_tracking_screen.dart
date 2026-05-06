import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF1FBFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildTopAppBar(isDesktop),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: 32),
                _buildFilters(),
                const SizedBox(height: 32),
                _buildOrderGrid(isDesktop),
                const SizedBox(height: 100), // Mobile FAB padding
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: !isDesktop ? _buildBottomNavBar() : null,
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFFF26522),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTopAppBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFFF26522)),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GastroGestion',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF26522),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isDesktop) ...[
                    _buildTopNavLink('Inicio', false),
                    const SizedBox(width: 24),
                    _buildTopNavLink('Pedidos', true),
                    const SizedBox(width: 24),
                    _buildTopNavLink('Mesas', false),
                    const SizedBox(width: 24),
                    _buildTopNavLink('Menú', false),
                    const SizedBox(width: 24),
                    _buildTopNavLink('Reportes', false),
                    const SizedBox(width: 32),
                  ],
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
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
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
        color: isActive ? const Color(0xFFF26522) : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seguimiento en Tiempo Real',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFA63B00),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gestión de Pedidos',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF131D21),
                height: 1.2,
              ),
            ),
          ],
        ),
        if (!isDesktop) const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: isDesktop ? 0 : 1,
              child: SizedBox(
                width: isDesktop ? 260 : null,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por mesa o pedido...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
    final filters = ['Todos (24)', 'Pendiente (4)', 'En Cocina (8)', 'Listo (10)', 'Servido (2)'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final isActive = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filters[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF475569),
                ),
              ),
              selected: isActive,
              onSelected: (selected) {
                setState(() => _selectedFilterIndex = index);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFA63B00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: isActive ? Colors.transparent : const Color(0xFFF1F5F9)),
              ),
              elevation: isActive ? 4 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: isDesktop ? 1.1 : 1.2,
      children: [
        _buildOrderCard(
          table: 'Mesa 12',
          orderId: '#ORD-4921 • 12:45 PM',
          status: 'Pendiente',
          statusColor: const Color(0xFF94A3B8), // slate-400
          bgColor: const Color(0xFFF1F5F9), // slate-100
          items: [
            {'name': '2x Burger Especial', 'price': '32,00€'},
            {'name': '1x Patatas Bravas', 'price': '8,50€'},
          ],
          actions: [
            _buildActionBtn('Cancelar', Icons.close, false),
            _buildActionBtn('Cocina', Icons.restaurant, true, color: const Color(0xFFA63B00)),
          ],
        ),
        _buildOrderCard(
          table: 'Mesa 04',
          orderId: '#ORD-4918 • 12:30 PM',
          status: 'En Cocina',
          statusColor: const Color(0xFFF59E0B), // amber-500
          bgColor: const Color(0xFFFEF3C7), // amber-100
          icon: Icons.outdoor_grill, // replacement for skillet
          warning: 'NOTA: Alergia frutos secos',
          items: [
            {'name': '1x Risotto de Setas', 'price': '18,00€'},
          ],
          progress: 0.65,
          timeText: 'Tiempo transcurrido: 12 min',
          actions: [
            _buildActionBtn('Marcar como Listo', Icons.check_circle, true, color: const Color(0xFFA63B00)),
          ],
        ),
        _buildOrderCard(
          table: 'Terraza 02',
          orderId: '#ORD-4912 • 12:15 PM',
          status: 'Listo',
          statusColor: const Color(0xFF10B981), // emerald-500
          bgColor: const Color(0xFF10B981),
          textColor: Colors.white,
          icon: Icons.notifications_active,
          items: [
            {'name': '3x Menú del Día', 'price': '45,00€'},
            {'name': '3x Cerveza Mahou', 'price': '7,50€'},
          ],
          actions: [
            _buildActionBtn('Servir a Mesa', Icons.delivery_dining, true, color: const Color(0xFF10B981)),
          ],
        ),
        _buildOrderCard(
          table: 'Mesa 08',
          orderId: '#ORD-4925 • 1:05 PM',
          status: 'En Cocina',
          statusColor: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFEF3C7),
          icon: Icons.outdoor_grill,
          items: [
            {'name': '1x Solomillo al punto', 'price': '22,50€'},
          ],
          actions: [
            _buildActionBtn('Marcar como Listo', Icons.check_circle, true, color: const Color(0xFFA63B00)),
          ],
        ),
        _buildOrderCard(
          table: 'Mesa 15',
          orderId: '#ORD-4930 • 1:12 PM',
          status: 'Listo',
          statusColor: const Color(0xFF10B981),
          bgColor: const Color(0xFF10B981),
          textColor: Colors.white,
          icon: Icons.notifications_active,
          items: [
            {'name': '2x Ensalada César', 'price': '24,00€'},
          ],
          actions: [
            _buildActionBtn('Servir a Mesa', Icons.delivery_dining, true, color: const Color(0xFF10B981)),
          ],
        ),
        _buildOrderCard(
          table: 'Barra 03',
          orderId: '#ORD-4935 • 1:15 PM',
          status: 'Pendiente',
          statusColor: const Color(0xFF94A3B8),
          bgColor: const Color(0xFFF1F5F9),
          items: [
            {'name': '1x Tapa de Jamón', 'price': '12,00€'},
          ],
          actions: [
            _buildActionBtn('Cancelar', null, false),
            _buildActionBtn('A Cocina', null, true, color: const Color(0xFFA63B00)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
          top: const BorderSide(color: Color(0xFFF8FAFC)),
          right: const BorderSide(color: Color(0xFFF8FAFC)),
          bottom: const BorderSide(color: Color(0xFFF8FAFC)),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.table_restaurant, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Text(table,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(orderId,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: textColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warning != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          Text(warning,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['name']!,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF475569))),
                            Text(item['price']!,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          ],
                        ),
                      )),
                  if (progress != null) ...[
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: statusColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(timeText ?? '',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8))),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: actions.map((a) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: a))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String text, IconData? icon, bool isPrimary, {Color? color}) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? (color ?? const Color(0xFFA63B00)) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF475569),
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), offset: const Offset(0, -4), blurRadius: 16),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.dashboard_outlined, 'Inicio', false),
          _buildBottomNavItem(Icons.receipt_long, 'Pedidos', true),
          _buildBottomNavItem(Icons.table_restaurant_outlined, 'Mesas', false),
          _buildBottomNavItem(Icons.bar_chart_outlined, 'Reportes', false), // New
          _buildBottomNavItem(Icons.restaurant_menu_outlined, 'Menú', false),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFF7ED) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isActive ? const Color(0xFFF26522) : const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFFF26522) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

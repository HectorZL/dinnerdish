import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  int _selectedTableIndex = -1; // 0 for Mesa 01 just to show the details panel

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1024;
    final bool isTablet = size.width > 768 && size.width <= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FBFF),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar (Desktop / Tablet)
          if (isDesktop || isTablet)
            SizedBox(
              width: 280,
              child: _buildSidebar(),
            ),

          // Main Canvas
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // TopAppBar
                    _buildTopAppBar(isDesktop || isTablet),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildToolbarLegend(),
                            const SizedBox(height: 32),
                            _buildTableGrid(),
                            const SizedBox(height: 80), // bottom padding for mobile
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating Details Sidebar (Desktop)
                if (isDesktop && _selectedTableIndex != -1)
                  Positioned(
                    top: 100,
                    right: 48,
                    child: _buildDetailsSidebar(),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet) ? _buildBottomNavBar() : null,
      floatingActionButton: (!isDesktop && !isTablet)
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFFF26522),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTopAppBar(bool hasSidebar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!hasSidebar) ...[
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFFF26522)),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
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
              if (hasSidebar)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SALÓN PRINCIPAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '12/24 Mesas Libres',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF26522),
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 16),
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

  Widget _buildSidebar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          // Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF26522),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Principal',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                    Text('Gestión Global',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Nav Links
          _buildNavItem(Icons.dashboard_outlined, 'Inicio', false),
          _buildNavItem(Icons.receipt_long_outlined, 'Pedidos', false),
          _buildNavItem(Icons.table_restaurant, 'Mesas', true), // Active
          _buildNavItem(Icons.restaurant_menu_outlined, 'Menú', false),
          _buildNavItem(Icons.bar_chart_outlined, 'Reportes', false), // New Reportes button

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                'ADMINISTRACIÓN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          _buildNavItem(Icons.group_outlined, 'Usuarios', false),
          _buildNavItem(Icons.inventory_2_outlined, 'Inventario', false),
          _buildNavItem(Icons.calculate_outlined, 'Escandallo', false),

          const Spacer(),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('v1.0.4',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
              const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8), size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF7ED) : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: isActive ? const Border(right: BorderSide(color: Color(0xFFF26522), width: 4)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? const Color(0xFFF26522) : const Color(0xFF475569)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFFF26522) : const Color(0xFF475569),
          ),
        ),
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: const Color(0xFFF8FAFC),
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
          _buildBottomNavItem(Icons.receipt_long_outlined, 'Pedidos', false),
          _buildBottomNavItem(Icons.table_restaurant, 'Mesas', true),
          _buildBottomNavItem(Icons.bar_chart_outlined, 'Reportes', false),
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

  Widget _buildToolbarLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista de Salón',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF131D21))),
            Text('Gestiona la disposición y el estado de las mesas en tiempo real.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF64748B))),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF8FAFC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegendItem(const Color(0xFF00A484), 'LIBRE'),
              const SizedBox(width: 12),
              _buildLegendItem(const Color(0xFFF26522), 'OCUPADA'),
              const SizedBox(width: 12),
              _buildLegendItem(const Color(0xFF3B82F6), 'RESERVADA'),
              if (MediaQuery.of(context).size.width > 768) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Mesa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26522),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    elevation: 8,
                    shadowColor: const Color(0xFFF26522).withValues(alpha: 0.3),
                  ),
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
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildTableGrid() {
    // Custom painting for background dots would ideally be a CustomPaint
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 600),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        // Dotted grid background simulation (a very light shade)
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 32,
        children: [
          _buildTableCard('01', '4 Personas', 'SOPA, FILETE, VINO', const Color(0xFFF26522), '35 MIN', 0),
          _buildTableCard('02', '2 Personas', 'DISPONIBLE', const Color(0xFF00A484), null, 1),
          _buildTableCard('03', '6 Personas', 'RESERVADA (GARCÍA)', const Color(0xFF3B82F6), '20:30', 2),
          _buildTableCard('04', '4 Personas', 'DISPONIBLE', const Color(0xFF00A484), null, 3),
          _buildTableCard('05', '2 Personas', 'CUENTA PEDIDA', const Color(0xFFF26522), '12 MIN', 4),
          // Large Table
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00A484), width: 4),
                  ),
                  child: Center(
                    child: Text('T6',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF00A484))),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Mesa Imperial',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                    Text('12 Personas Max.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('OPTIMAL STOCK',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF00A484))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildTableCard('07', '4 Personas', 'DISPONIBLE', const Color(0xFF00A484), null, 6),
          _buildTableCard('08', '2 Personas', 'DISPONIBLE', const Color(0xFF00A484), null, 7),
          _buildTableCard('09', '4 Personas', 'RESERVADA (SOTO)', const Color(0xFF3B82F6), '21:00', 8),
          _buildTableCard('10', '2 Personas', 'DISPONIBLE', const Color(0xFF00A484), null, 9),

          // Bar Zone
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Text('ZONA DE BARRA',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: const Color(0xFF94A3B8))),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildBarStool('B1', const Color(0xFFF26522)),
                    _buildBarStool('B2', const Color(0xFF00A484)),
                    _buildBarStool('B3', const Color(0xFF00A484)),
                    _buildBarStool('B4', const Color(0xFFF26522)),
                    _buildBarStool('B5', const Color(0xFF00A484)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarStool(String id, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Text(id,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
      ),
    );
  }

  Widget _buildTableCard(String id, String capacity, String statusText, Color color, String? badgeTag, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTableIndex = _selectedTableIndex == index ? -1 : index;
        });
      },
      child: Container(
        width: 160,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _selectedTableIndex == index ? color : color.withValues(alpha: 0.1), width: 2),
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
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeTag,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
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
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(capacity,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSidebar() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
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
              Text('Mesa 01', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'OCUPADA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF26522),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.group, color: Color(0xFF94A3B8)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comensales',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                    Text('4 Personas',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMANDA ACTUAL',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 12),
                _buildReceiptLine('2x Hamburguesa Gourmet', '32.00€'),
                _buildReceiptLine('1x Ensalada César', '12.50€'),
                _buildReceiptLine('1x Botella Ribera Duero', '24.00€'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: Color(0xFFE2E8F0)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                    Text('68.50€',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFF26522))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Imprimir'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26522),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    shadowColor: const Color(0xFFF26522).withValues(alpha: 0.3),
                  ),
                  child: const Text('Cerrar Caja'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLine(String item, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569))),
          Text(price,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

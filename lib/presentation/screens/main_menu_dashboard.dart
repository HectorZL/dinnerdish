import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainMenuDashboardScreen extends StatefulWidget {
  const MainMenuDashboardScreen({super.key});

  @override
  State<MainMenuDashboardScreen> createState() => _MainMenuDashboardScreenState();
}

class _MainMenuDashboardScreenState extends State<MainMenuDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111714),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.015,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Menu Options',
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.015,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    icon: Icons.groups,
                    title: 'Manage Staff',
                    onTap: () {},
                  ),
                  _buildMenuCard(
                    icon: Icons.receipt_long,
                    title: 'View Orders',
                    onTap: () {},
                  ),
                  _buildMenuCard(
                    icon: Icons.soup_kitchen,
                    title: 'Kitchen Orders',
                    onTap: () {},
                  ),
                  _buildMenuCard(
                    icon: Icons.payments,
                    title: 'Cashier',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF29382F), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF1C2620).withOpacity(0.9),
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF38E07B),
          unselectedItemColor: const Color(0xFF9EB7A8),
          selectedLabelStyle: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.015,
          ),
          unselectedLabelStyle: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.015,
          ),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Dishes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF38E07B).withOpacity(0.1),
        highlightColor: const Color(0xFF38E07B).withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF1C2620),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3D5245)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF38E07B),
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

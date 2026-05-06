import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'presentation/screens/create_order_screen.dart';
import 'presentation/screens/main_menu_dashboard.dart';
import 'presentation/screens/order_tracking_screen.dart';
import 'presentation/screens/table_management_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FBFF),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -250,
            right: -250,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: const Color(0xFFF26522).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF00A484).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: IntrinsicHeight(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 640),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Flex(
                      direction: isDesktop ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Branding Side (Only visible on Desktop)
                      if (isDesktop)
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF26522),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Background Image
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: Image.network(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBX3IkcN7Z4dxxcZa1RRNw2jVS2F3w6fpRVDa5MnDs3dfeXlPeMH7R1mf-CdORhKoEN0Fmhyh-No5p8Ba4JEqRpgVtAiRMCE38GEV-bbRYkyHxnmCNmqeDqGAtERsFtxdyP_ivR6b3jBXZyNZVlEgAsV5U4bydPoM7_OTX74-jJAKXW024jcnkikcuXNuXjFd7k-aiZYdJd_pNWoOlJ59IVERtpXGWItu9rV68am_07IN0fRFYtz6EOk7qKmCNw2UzMTywy4ZjhAZsZ',
                                      fit: BoxFit.cover,
                                      colorBlendMode: BlendMode.overlay,
                                    ),
                                  ),
                                ),
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.restaurant, color: Colors.white, size: 36),
                                              const SizedBox(width: 8),
                                              Text(
                                                'GastroGestion',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 32),
                                          Text(
                                            'Control total de su restaurante en un solo lugar.',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Gestione pedidos, inventario y personal con la eficiencia de un sistema diseñado para la alta cocina.',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 16,
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildFeatureBadge('100%', 'EFICIENCIA'),
                                          const SizedBox(width: 16),
                                          _buildFeatureBadge('24/7', 'SOPORTE'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Login Form Side
                      isDesktop
                          ? Expanded(
                              flex: 1,
                              child: _buildFormSide(isDesktop, context),
                            )
                          : _buildFormSide(isDesktop, context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildFormSide(bool isDesktop, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 64.0 : 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                              // Mobile Header
                              if (!isDesktop) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.restaurant, color: Color(0xFFF26522), size: 28),
                                    const SizedBox(width: 4),
                                    Text(
                                      'GastroGestion',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFF26522),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                              ],

                              Text(
                                'Bienvenido',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF131D21),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ingrese sus credenciales para acceder al panel.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF586062),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Username
                              Text(
                                'USUARIO',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF594138),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF586062)),
                                  hintText: 'nombre.apellido',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF586062).withOpacity(0.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE1BFB3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE1BFB3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFF26522), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CONTRASEÑA',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF594138),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        '¿Olvidó su contraseña?',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFF26522),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF586062)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF586062),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  hintText: '••••••••',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF586062).withOpacity(0.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE1BFB3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFE1BFB3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFFF26522), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Remember me
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: const Color(0xFFF26522),
                                      side: const BorderSide(color: Color(0xFFE1BFB3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recordar mi sesión',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF586062),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Login Button
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF26522),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: const Color(0xFFF26522).withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Iniciar Sesión',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Footer links
                              Container(
                                padding: const EdgeInsets.only(top: 24),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Color(0xFFE4F0F4)),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '¿No tiene una cuenta corporativa?',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF586062),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF594138),
                                        side: const BorderSide(color: Color(0xFFE1BFB3)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Text(
                                        'CONTACTAR CON SOPORTE',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),
                              // Debug navigation for testing screens
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Test Screens (Debug)',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const MainMenuDashboardScreen()),
                                        );
                                      },
                                      child: const Text('Dashboard'),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                                        );
                                      },
                                      child: const Text('Create Order'),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const OrderTrackingScreen()),
                                        );
                                      },
                                      child: const Text('Order Tracking'),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const TableManagementScreen()),
                                        );
                                      },
                                      child: const Text('Table Management'),
                                    ),
                                  ],
                                ),
                              ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

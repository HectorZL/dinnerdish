import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/user.dart';
import 'providers/providers.dart';

// ─── Design Tokens ────────────────────────────
const _orange = Color(0xFFF26522);
const _orangeDark = Color(0xFFA63B00);
const _ink = Color(0xFF0F1518); // pure dark for text
const _muted = Color(0xFF40484B); // darker grey for contrast
const _white = Colors.white;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Animations — pre-initialized to "already done" so build() is always safe
  AnimationController? _fadeCtrl;
  AnimationController? _slideCtrl;
  Animation<double> _fadeAnim = const AlwaysStoppedAnimation(1.0);
  Animation<Offset> _slideAnim = const AlwaysStoppedAnimation(Offset.zero);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl!, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl!, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeCtrl?.forward();
        _slideCtrl?.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl?.dispose();
    _slideCtrl?.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showError('Ingrese correo y contraseña');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).login(username, password);
      if (!mounted) return;
      context.go('/menu');
    } catch (e) {
      if (!mounted) return;
      _showError('Credenciales incorrectas');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTestUserLogin(User user) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).loginWithTestUser(user);
      if (!mounted) return;
      context.go('/menu');
    } catch (e) {
      if (!mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            color: _white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _orangeDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 860;

    return Scaffold(
      backgroundColor: _white,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ─── DESKTOP: two-column ─────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: orange branding panel
        Expanded(flex: 5, child: _buildBrandingPanel()),
        // Right: form on light bg
        Expanded(
          flex: 4,
          child: Container(
            color: _white,
            child: _buildFormPanel(isDesktop: true),
          ),
        ),
      ],
    );
  }

  // ─── MOBILE: pure white, logo on top ──────────────
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo — big and clean on white
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 4),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(child: _buildLogo(size: 110)),
              ),
            ),
            // Thin divider after logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: const Color(0xFFEEEEEE), thickness: 1),
            ),
            const SizedBox(height: 8),
            // Form directly on white — no card needed
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildFormPanel(isDesktop: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BRANDING PANEL (orange) ─────────────────
  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF26522), Color(0xFFD94F0A), Color(0xFFAD3800)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Light orb top-right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_white.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          // Dark orb bottom-left
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Subtle grid
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(lineColor: _white.withValues(alpha: 0.06)),
            ),
          ),
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(size: 60, onDark: true),
                    const Spacer(),
                    // Big headline
                    Text(
                      'Gestiona tu\nrestaurante\ncon precision.',
                      style: GoogleFonts.plusJakartaSans(
                        color: _white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pedidos, cocina, caja y personal\nen un solo sistema operativo.',
                      style: GoogleFonts.plusJakartaSans(
                        color: _white.withValues(alpha: 0.82),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Feature pills
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildPill(Icons.bolt_outlined, 'Tiempo real'),
                        _buildPill(Icons.shield_outlined, 'Roles y accesos'),
                        _buildPill(Icons.bar_chart_outlined, 'Reportes'),
                        _buildPill(Icons.kitchen_outlined, 'KDS integrado'),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'SABOR Y HOGAR v1.0.4',
                      style: GoogleFonts.plusJakartaSans(
                        color: _white.withValues(alpha: 0.45),
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({double size = 36, bool onDark = false}) {
    // logoHeight uses the size as height directly; width scales with aspect ratio
    return SizedBox(
      height: size,
      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: _white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FORM PANEL ──────────────────────────────
  Widget _buildFormPanel({required bool isDesktop}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 56 : 28,
        vertical: isDesktop ? 0 : 36,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: isDesktop ? MediaQuery.of(context).size.height : 0,
        ),
        child: Column(
          mainAxisAlignment: isDesktop
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop) const SizedBox(height: 80),
            // Big title — replaces "Bienvenido"
            Text(
              'Iniciar sesion',
              style: GoogleFonts.plusJakartaSans(
                color: _ink,
                fontSize: isDesktop ? 32 : 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 36),

            // ── DINNERHOME EMAIL ──
            _buildLabel('Correo de Dinnerhome'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _usernameController,
              hint: 'nombre@dinner.com',
              prefix: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // ── PASSWORD ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Contrasena'),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Olvide mi contrasena',
                      style: GoogleFonts.plusJakartaSans(
                        color: _orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _passwordController,
              hint: '••••••••',
              prefix: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _muted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),

            // ── REMEMBER ME ──
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _rememberMe ? _orange : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _rememberMe ? _orange : const Color(0xFFD0D7DE),
                        width: 1.5,
                      ),
                    ),
                    child: _rememberMe
                        ? const Icon(Icons.check, size: 13, color: _white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Recordar mi sesion',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF3B434B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── LOGIN BUTTON ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  disabledBackgroundColor: _orange.withValues(alpha: 0.5),
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Iniciar Sesion',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── SUPPORT LINK ──
            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: _muted,
                      ),
                      children: [
                        const TextSpan(text: 'Sin acceso corporativo? '),
                        TextSpan(
                          text: 'Contactar soporte',
                          style: GoogleFonts.plusJakartaSans(
                            color: _orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),
            // ── DIVIDER ──
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFEAECF0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ACCESO RAPIDO',
                    style: GoogleFonts.plusJakartaSans(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFEAECF0))),
              ],
            ),
            const SizedBox(height: 16),

            // ── QUICK ACCESS ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                _buildTestCard(
                  label: 'Mesero',
                  name: 'Juan Perez',
                  icon: Icons.person_outline_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  user: const User(
                    id: 'user-mesero-1',
                    username: 'mesero',
                    name: 'Juan Perez',
                    role: Role.mesero,
                    token: 'mock-token-mesero',
                  ),
                ),
                _buildTestCard(
                  label: 'Cajero',
                  name: 'Maria Garcia',
                  icon: Icons.point_of_sale_outlined,
                  accentColor: const Color(0xFF10B981),
                  user: const User(
                    id: 'user-cajero-1',
                    username: 'cajero',
                    name: 'Maria Garcia',
                    role: Role.cajero,
                    token: 'mock-token-cajero',
                  ),
                ),
                _buildTestCard(
                  label: 'Chef',
                  name: 'Carlos Lopez',
                  icon: Icons.soup_kitchen_outlined,
                  accentColor: const Color(0xFF3B82F6),
                  user: const User(
                    id: 'user-cocinero-1',
                    username: 'cocinero',
                    name: 'Carlos Lopez',
                    role: Role.cocinero,
                    token: 'mock-token-cocinero',
                  ),
                ),
                _buildTestCard(
                  label: 'Admin',
                  name: 'Ana Martinez',
                  icon: Icons.admin_panel_settings_outlined,
                  accentColor: _orange,
                  user: const User(
                    id: 'user-admin-1',
                    username: 'admin',
                    name: 'Ana Martinez',
                    role: Role.admin,
                    token: 'mock-token-admin',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF3B434B),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(
        color: _ink,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(prefix, color: _muted, size: 20),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFFD0D7DE),
          fontSize: 15,
        ),
        filled: true,
        fillColor: const Color(0xFFF6F8FA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _orange, width: 2),
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required String label,
    required String name,
    required IconData icon,
    required Color accentColor,
    required User user,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTestUserLogin(user),
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Subtle Grid Background ──────────────────
class _GridPainter extends CustomPainter {
  final Color lineColor;
  const _GridPainter({this.lineColor = const Color(0x08FFFFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.lineColor != lineColor;
}

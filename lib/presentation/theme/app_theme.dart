import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/router/route_guards.dart';

// ──────────────────────────────────────────────
// Stitch Design System — Shared Constants
// ──────────────────────────────────────────────

// ── Color Palette ─────────────────────────────
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF1FBFF);
  static const Color surface = Color(0xFFF1FBFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEAF5FA);
  static const Color surfaceContainer = Color(0xFFE4F0F4);
  static const Color surfaceContainerHigh = Color(0xFFDFEAEF);
  static const Color surfaceContainerHighest = Color(0xFFD9E4E9);
  static const Color surfaceDim = Color(0xFFD1DCE0);
  static const Color surfaceBright = Color(0xFFF1FBFF);
  static const Color surfaceVariant = Color(0xFFD9E4E9);

  static const Color onSurface = Color(0xFF131D21);
  static const Color onSurfaceVariant = Color(0xFF594138);
  static const Color onBackground = Color(0xFF131D21);

  static const Color primaryContainer = Color(0xFFF26522);
  static const Color primary = Color(0xFFA63B00);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFFFDBCE);
  static const Color primaryFixedDim = Color(0xFFFFB599);

  static const Color tertiaryContainer = Color(0xFF00A484);
  static const Color tertiary = Color(0xFF006B55);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF586062);
  static const Color secondaryContainer = Color(0xFFDAE1E3);

  static const Color outline = Color(0xFF8D7166);
  static const Color outlineVariant = Color(0xFFE1BFB3);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // Semantic status colors
  static const Color statusPending = Color(0xFF94A3B8);
  static const Color statusCooking = Color(0xFFF59E0B);
  static const Color statusReady = Color(0xFF10B981);
  static const Color statusPaid = Color(0xFF006B55);
}

// ── Typography ────────────────────────────────
class AppTypography {
  AppTypography._();

  static TextStyle h1({
    Color color = AppColors.onBackground,
    FontWeight? fontWeight,
    double? fontSize,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize ?? 32,
        fontWeight: fontWeight ?? FontWeight.w700,
        height: 1.2,
        color: color,
      );

  static TextStyle h2({
    Color color = AppColors.onBackground,
    FontWeight? fontWeight,
    double? fontSize,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize ?? 24,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle h3({
    Color color = AppColors.onBackground,
    FontWeight? fontWeight,
    double? fontSize,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize ?? 20,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle bodyLg({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodyMd({
    Color color = AppColors.onSurfaceVariant,
    FontWeight? fontWeight,
    double? fontSize,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle labelCaps({
    Color color = AppColors.secondary,
    FontWeight? fontWeight,
    double? fontSize,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize ?? 12,
        fontWeight: fontWeight ?? FontWeight.w700,
        letterSpacing: 0.6, // 0.05em ≈ 0.6px
        height: 1.0,
        color: color,
      );

  static TextStyle statusBadge({
    Color color = AppColors.onSurface,
    FontWeight? fontWeight,
    double? fontSize,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fontSize ?? 12,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: 1.0,
        color: color,
      );
}

// ── Spacing ───────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double base = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double gutter = 20;
  static const double lg = 24;
  static const double containerPadding = 24;
  static const double xl = 32;
}

// ── Border Radius ─────────────────────────────
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double lg = 8;
  static const double xl = 12;
  static const double full = 9999;
}

// ── Shadows ───────────────────────────────────
class AppShadows {
  AppShadows._();

  static BoxShadow card = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow cta = BoxShadow(
    color: AppColors.primaryContainer.withValues(alpha: 0.3),
    blurRadius: 32,
    offset: const Offset(0, 12),
  );

  static BoxShadow bottomNav = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 16,
    offset: const Offset(0, -4),
  );
}

// ── Reusable Widget Builders ──────────────────

/// TopAppBar matching the Stitch pattern: white/80 backdrop blur, orange title, profile avatar.
class StitchTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final List<NavLink>? navLinks;

  const StitchTopAppBar({
    super.key,
    this.title = 'GastroGestion',
    this.actions,
    this.showBack = false,
    this.onBack,
    this.navLinks,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [AppShadows.card],
      ),
      child: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF131D21)),
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    if (showBack) const SizedBox(width: 8),
                    if (!showBack)
                      IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.primaryContainer),
                        onPressed: () {},
                      ),
                    if (!showBack) const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryContainer,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (navLinks != null && isDesktop) ...[
                    ...navLinks!.map((link) => Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: InkWell(
                            onTap: link.route != null ? () => context.go(link.route!) : null,
                            child: Text(
                              link.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: link.isActive ? FontWeight.bold : FontWeight.w600,
                                color: link.isActive
                                    ? AppColors.primaryContainer
                                    : const Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )),
                  ],
                  if (actions != null) ...actions!,
                  Consumer(
                    builder: (context, ref, child) {
                      return PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await ref.read(currentUserProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          } else if (value == 'profile') {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Perfil'),
                                content: const Text('Detalles del usuario irán aquí.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cerrar'),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Color(0xFF64748B), size: 20),
                                SizedBox(width: 8),
                                Text('Detalles del Usuario'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Salir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavLink {
  final String label;
  final bool isActive;
  final String? route;
  const NavLink(this.label, this.isActive, {this.route});
}

class StitchAdminSidebar extends StatelessWidget {
  final String activeTab;

  const StitchAdminSidebar({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Principal',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h3(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold)),
                        Text('Gestión Global • v1.0.4',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd(
                                color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildNavItem(context, Icons.group_outlined, 'Usuarios', activeTab == 'Usuarios'),
            _buildNavItem(context, Icons.restaurant_menu_outlined, 'Menú', activeTab == 'Menú'),
            _buildNavItem(context, Icons.bar_chart_outlined, 'Reportes', activeTab == 'Reportes'),
            _buildNavItem(context, Icons.history, 'Auditoría', activeTab == 'Auditoría'),
            _buildNavItem(context, Icons.settings_outlined, 'Ajustes', activeTab == 'Ajustes'),
            const Spacer(),
            Text('Versión v1.0.4',
                style: AppTypography.labelCaps(
                    color: const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, bool isActive) {
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
          if (isActive) return;
          switch (title) {
            case 'Usuarios':
              context.go('/admin/users');
            case 'Menú':
              context.go('/admin/menu');
            case 'Reportes':
              context.go('/admin/reports');
            case 'Auditoría':
              context.go('/audit');
          }
        },
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
    );
  }
}

/// Bottom Navigation Bar matching Stitch mobile pattern.
class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  _NavItem(this.icon, this.label, this.route);
}

class StitchBottomNavBar extends StatelessWidget {
  final String currentRoute;
  final dynamic currentUser;

  const StitchBottomNavBar({
    super.key,
    required this.currentRoute,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(Icons.dashboard_outlined, 'Inicio', '/menu'),
    ];

    if (RouteGuard.canAccessOrders(currentUser)) {
      items.add(_NavItem(Icons.receipt_long_outlined, 'Pedidos', '/orders/tracking'));
    }
    if (RouteGuard.canAccessTables(currentUser)) {
      items.add(_NavItem(Icons.table_restaurant_outlined, 'Mesas', '/tables'));
    }
    if (RouteGuard.canAccessKds(currentUser)) {
      items.add(_NavItem(Icons.kitchen_outlined, 'Cocina', '/kds'));
    }
    if (RouteGuard.canAccessPayment(currentUser)) {
      items.add(_NavItem(Icons.point_of_sale_outlined, 'Caja', '/cashier/pending'));
    }
    if (currentUser != null && currentUser.role.toString() == 'Role.admin') {
      items.add(_NavItem(Icons.bar_chart_outlined, 'Reportes', '/admin/reports'));
      items.add(_NavItem(Icons.restaurant_menu_outlined, 'Menú', '/admin/menu'));
    }

    // Limit to max 5 items on mobile to keep the bar clean
    final displayItems = items.take(5).toList();

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [AppShadows.bottomNav],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: displayItems
            .map((item) => Expanded(
                  child: _buildItem(
                      context, item.icon, item.label, item.route),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String label, String route) {
    bool isActive = currentRoute == route;
    if (route != '/menu' && currentRoute.startsWith(route)) {
        isActive = true;
    }
    if (route == '/orders/tracking' && currentRoute.startsWith('/orders/')) {
        isActive = true;
    }
    if (route == '/cashier/pending' && currentRoute.startsWith('/cashier/')) {
        isActive = true;
    }

    return GestureDetector(
      onTap: () {
        if (!isActive) context.go(route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
                horizontal: isActive ? 18 : 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryContainer.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive
                  ? AppColors.primaryContainer
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? AppColors.primaryContainer
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard card container used across Stitch screens.
class StitchCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  const StitchCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor ?? const Color(0xFFF1F5F9)),
        boxShadow: [AppShadows.card],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

/// Primary CTA Button matching Stitch pattern.
class StitchPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;

  const StitchPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 50,
      width: width ?? double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
        label: Text(
          isLoading ? 'Procesando...' : label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryContainer.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          elevation: 8,
          shadowColor: AppColors.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

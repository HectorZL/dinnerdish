import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
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
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                StitchTopAppBar(
                  navLinks: isDesktop
                      ? const [
                          NavLink('Inicio', false),
                          NavLink('Usuarios', true),
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
                            _buildStats(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildUserGrid(),
                            const SizedBox(height: AppSpacing.lg),
                            _buildRoleDistribution(),
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
                          style: AppTypography.h3(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.bold)),
                      Text('Gestión Global • v1.0.4',
                          style: AppTypography.bodyMd(
                              color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildNavItem(Icons.group, 'Usuarios', true, context),
            _buildNavItem(
                Icons.inventory_2_outlined, 'Inventario', false, context),
            _buildNavItem(
                Icons.calculate_outlined, 'Escandallo', false, context),
            _buildNavItem(Icons.bar_chart_outlined, 'Reportes', false, context),
            _buildNavItem(
                Icons.settings_outlined, 'Ajustes', false, context),
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
            case 'Inventario':
              context.go('/admin/inventory');
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

  Widget _buildBottomNavBar(dynamic currentUser) {
    return StitchBottomNavBar(
      currentRoute: '/admin/users',
      currentUser: currentUser,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestión de Personal',
                  style: AppTypography.h1(color: AppColors.onBackground)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Control de acceso y roles para los empleados de tu restaurante.',
                  style: AppTypography.bodyMd(color: AppColors.secondary)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.manage_accounts, size: 20),
          label: Text('Configurar Roles',
              style: AppTypography.statusBadge(
                  fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.onSurfaceVariant,
            side: const BorderSide(color: Color(0xFFE1BFB3)),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl)),
            elevation: 1,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StitchPrimaryButton(
          label: 'Nuevo Usuario',
          icon: Icons.person_add,
          width: 180,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatCard(
            Icons.groups, 'Total Usuarios', '24', const Color(0xFF3B82F6)),
        const SizedBox(width: AppSpacing.md),
        _buildStatCard(Icons.verified_user, 'Activos ahora', '8',
            const Color(0xFF10B981)),
        const SizedBox(width: AppSpacing.md),
        _buildStatCard(Icons.lock_open, 'Roles Definidos', '5',
            AppColors.primaryContainer),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [AppShadows.card],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.bodyMd(
                        color: const Color(0xFF64748B))),
                Text(value,
                    style: AppTypography.h1(
                        fontSize: 28, color: AppColors.onBackground)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.base),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.2,
          children: [
            _buildUserCard(
              'Carlos Méndez',
              'carlos.m@gastrogestion.com',
              'Admin',
              AppColors.primaryContainer,
              null,
              'Hoy, 09:15 AM',
            ),
            _buildUserCard(
              'Lucía Ferrero',
              'lucia.f@gastrogestion.com',
              'Sala',
              const Color(0xFF3B82F6),
              null,
              'Ayer, 11:30 PM',
            ),
            _buildUserCard(
              'Jorge Ruíz',
              'jruiz@gastrogestion.com',
              'Cocina',
              const Color(0xFF10B981),
              null,
              'Hoy, 06:45 AM',
            ),
            _buildUserCard(
              'Elena Blanco',
              'elena.b@gastrogestion.com',
              'Caja',
              const Color(0xFF8B5CF6),
              null,
              'Hace 3 días',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserCard(
    String name,
    String email,
    String role,
    Color roleColor,
    String? imageUrl,
    String lastLogin,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [AppShadows.card],
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                ),
                child: Center(
                  child: Icon(Icons.person,
                      color: roleColor, size: 24),
                ),
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
                    Text(email,
                        style: AppTypography.bodyMd(
                            color: AppColors.secondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(role,
                    style: AppTypography.statusBadge(
                        color: roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          const Divider(color: Color(0xFFF8FAFC)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ÚLTIMA SESIÓN',
                      style: AppTypography.labelCaps(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10)),
                  Text(lastLogin,
                      style: AppTypography.bodyMd(
                          fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDistribution() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribución de Roles',
              style: AppTypography.h2(color: AppColors.onBackground)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildRoleBadge('Administradores', '4', AppColors.primaryContainer),
              const SizedBox(width: AppSpacing.sm),
              _buildRoleBadge(
                  'Personal de Sala', '12', const Color(0xFF3B82F6)),
              const SizedBox(width: AppSpacing.sm),
              _buildRoleBadge(
                  'Personal de Cocina', '6', const Color(0xFF10B981)),
              const SizedBox(width: AppSpacing.sm),
              _buildRoleBadge(
                  'Gestión de Caja', '2', const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.bodyMd(
                    color: const Color(0xFF475569))),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(count,
                    style: AppTypography.statusBadge(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

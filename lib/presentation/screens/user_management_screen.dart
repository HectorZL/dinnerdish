import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isMobile = !isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const StitchAdminSidebar(activeTab: 'Usuarios'),
          Expanded(
            child: Column(
              children: [
                StitchTopAppBar(
                  navLinks: isDesktop
                      ? const [
                          NavLink('Inicio', false, route: '/menu'),
                          NavLink('Usuarios', true, route: '/admin/users'),
                          NavLink('Menu', false, route: '/admin/menu'),
                          NavLink('Reportes', false, route: '/admin/reports'),
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
                            _buildHeader(isMobile),
                            const SizedBox(height: AppSpacing.lg),
                            _buildStats(isMobile),
                            const SizedBox(height: AppSpacing.xl),
                            _buildSectionTitle('Equipo del Restaurante'),
                            const SizedBox(height: AppSpacing.md),
                            _buildUserList(isDesktop),
                            const SizedBox(height: AppSpacing.xl),
                            _buildRoleDistribution(isMobile),
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
      bottomNavigationBar: isMobile
          ? StitchBottomNavBar(
              currentRoute: '/admin/users', currentUser: currentUser)
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.h3()),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestion de Personal',
            style: AppTypography.h1(color: AppColors.onBackground)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Control de acceso y roles para los empleados de tu restaurante.',
          style: AppTypography.bodyMd(color: AppColors.secondary),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleColumn,
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.manage_accounts, size: 18),
                  label: const Text('Configurar Roles'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: const BorderSide(color: Color(0xFFE1BFB3)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StitchPrimaryButton(
                  label: 'Nuevo Usuario',
                  icon: Icons.person_add,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleColumn),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.manage_accounts, size: 18),
          label: const Text('Configurar Roles'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
            side: const BorderSide(color: Color(0xFFE1BFB3)),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl)),
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

  Widget _buildStats(bool isMobile) {
    final cards = [
      _buildStatCard(Icons.groups, 'Total Usuarios', '24',
          const Color(0xFF3B82F6), 'Registrados'),
      _buildStatCard(Icons.verified_user, 'Activos Ahora', '8',
          const Color(0xFF10B981), 'En turno'),
      _buildStatCard(Icons.lock_open, 'Roles Definidos', '5',
          AppColors.primaryContainer, 'Permisos'),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: cards[1]),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [AppShadows.card],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.bodyMd(color: const Color(0xFF64748B))),
              Text(value, style: AppTypography.h2(color: AppColors.onBackground)),
              Text(sub,
                  style:
                      AppTypography.labelCaps(color: color, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(bool isDesktop) {
    final users = [
      _UserData('Carlos Mendez', 'carlos.m@sabor-y-hogar.com', 'Admin',
          AppColors.primaryContainer, 'Hoy, 09:15 AM', true),
      _UserData('Lucia Ferrero', 'lucia.f@sabor-y-hogar.com', 'Sala',
          const Color(0xFF3B82F6), 'Ayer, 11:30 PM', true),
      _UserData('Jorge Ruiz', 'jruiz@sabor-y-hogar.com', 'Cocina',
          const Color(0xFF10B981), 'Hoy, 06:45 AM', true),
      _UserData('Elena Blanco', 'elena.b@sabor-y-hogar.com', 'Caja',
          const Color(0xFF8B5CF6), 'Hace 3 dias', false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [AppShadows.card],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 52 + AppSpacing.md),
                Expanded(
                  flex: 4,
                  child: Text('NOMBRE',
                      style: AppTypography.labelCaps(
                          color: const Color(0xFF94A3B8))),
                ),
                if (isDesktop)
                  Expanded(
                    flex: 4,
                    child: Text('EMAIL',
                        style: AppTypography.labelCaps(
                            color: const Color(0xFF94A3B8))),
                  ),
                Expanded(
                  flex: 2,
                  child: Text('ROL',
                      style: AppTypography.labelCaps(
                          color: const Color(0xFF94A3B8))),
                ),
                if (isDesktop)
                  Expanded(
                    flex: 3,
                    child: Text('ULTIMA SESION',
                        style: AppTypography.labelCaps(
                            color: const Color(0xFF94A3B8))),
                  ),
                Expanded(
                  flex: 2,
                  child: Text('ESTADO',
                      style: AppTypography.labelCaps(
                          color: const Color(0xFF94A3B8))),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ),
          // Rows
          ...users.asMap().entries.map((entry) {
            final i = entry.key;
            final u = entry.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildUserRow(u, isDesktop),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserRow(_UserData user, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with initial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: user.roleColor.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                user.name[0].toUpperCase(),
                style: AppTypography.h3(color: user.roleColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLg(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
                if (!isDesktop)
                  Text(user.email,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd(
                          color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          // Email desktop
          if (isDesktop)
            Expanded(
              flex: 4,
              child: Text(user.email,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTypography.bodyMd(color: const Color(0xFF64748B))),
            ),
          // Role
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: user.roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(user.role,
                    style: AppTypography.statusBadge(
                        color: user.roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          // Last login desktop
          if (isDesktop)
            Expanded(
              flex: 3,
              child: Text(user.lastLogin,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTypography.bodyMd(color: const Color(0xFF64748B))),
            ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd(
                      color: user.isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _iconBtn(Icons.edit_outlined, const Color(0xFF64748B), () {}),
                _iconBtn(Icons.delete_outline, AppColors.error, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildRoleDistribution(bool isMobile) {
    final roles = [
      _RoleData('Administradores', '4', AppColors.primaryContainer),
      _RoleData('Personal de Sala', '12', const Color(0xFF3B82F6)),
      _RoleData('Personal de Cocina', '6', const Color(0xFF10B981)),
      _RoleData('Gestion de Caja', '2', const Color(0xFF8B5CF6)),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [AppShadows.card],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Distribucion de Roles', style: AppTypography.h3()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isMobile)
            Column(
              children: roles
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildRoleRow(r),
                      ))
                  .toList(),
            )
          else
            Row(
              children: roles
                  .expand((r) => [
                        Expanded(child: _buildRoleCard(r)),
                        if (r != roles.last)
                          const SizedBox(width: AppSpacing.sm),
                      ])
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleRow(_RoleData role) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: role.color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(role.label,
              style: AppTypography.bodyMd(color: const Color(0xFF475569))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: role.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(role.count,
              style: AppTypography.statusBadge(
                  color: role.color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRoleCard(_RoleData role) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: role.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    BoxDecoration(color: role.color, shape: BoxShape.circle),
                child: Center(
                  child: Text(role.count,
                      style: AppTypography.statusBadge(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              Icon(Icons.chevron_right, color: role.color, size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(role.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _UserData {
  final String name;
  final String email;
  final String role;
  final Color roleColor;
  final String lastLogin;
  final bool isActive;

  const _UserData(this.name, this.email, this.role, this.roleColor,
      this.lastLogin, this.isActive);
}

class _RoleData {
  final String label;
  final String count;
  final Color color;

  const _RoleData(this.label, this.count, this.color);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/role_permissions.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final users = await userService.fetchUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error loading users: $e\n$st');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _createUser(User user) async {
    try {
      final userService = ref.read(userServiceProvider);
      await userService.createUser(user);
      await _loadData();
    } catch (e, st) {
      debugPrint('Error creating user: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear: $e')));
    }
  }

  Future<void> _updateUser(String id, User user) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == id && (user.role != Role.admin || !user.isActive)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes quitar tus propios privilegios de administrador ni desactivarte.',
          ),
        ),
      );
      return;
    }
    try {
      final userService = ref.read(userServiceProvider);
      await userService.updateUser(id, user);
      await _loadData();
    } catch (e, st) {
      debugPrint('Error updating user: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  Future<void> _deleteUser(String id) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser?.id == id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminar tu propia cuenta.')),
      );
      return;
    }
    try {
      final userService = ref.read(userServiceProvider);
      await userService.deleteUser(id);
      await _loadData();
    } catch (e, st) {
      debugPrint('Error deleting user: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  void _showRoleConfiguration() {
    final configuredPermissions = ref.read(rolePermissionsProvider);
    final draft = <Role, Set<AppPermission>>{
      for (final role in Role.values)
        role: Set<AppPermission>.from(
          configuredPermissions.permissionsFor(role),
        ),
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: const Text('Permisos por rol'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Los administradores conservan acceso total para impedir que el sistema quede bloqueado.',
                ),
                const SizedBox(height: 12),
                ...Role.values.map(
                  (role) => ExpansionTile(
                    initiallyExpanded: role != Role.admin,
                    title: Text(_getRoleLabel(role)),
                    subtitle: role == Role.admin
                        ? const Text('Acceso total protegido')
                        : Text('${draft[role]!.length} permiso(s) activo(s)'),
                    children: AppPermission.values.map((permission) {
                      final isAdmin = role == Role.admin;
                      return CheckboxListTile(
                        dense: true,
                        title: Text(_permissionLabel(permission)),
                        value: isAdmin || draft[role]!.contains(permission),
                        onChanged: isAdmin
                            ? null
                            : (selected) {
                                setDialogState(() {
                                  if (selected ?? false) {
                                    draft[role]!.add(permission);
                                  } else {
                                    draft[role]!.remove(permission);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final notifier = ref.read(rolePermissionsProvider.notifier);
                for (final role in Role.values.where(
                  (role) => role != Role.admin,
                )) {
                  await notifier.setPermissions(role, draft[role]!);
                }
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permisos actualizados')),
                  );
                }
              },
              child: const Text('Guardar permisos'),
            ),
          ],
        ),
      ),
    );
  }

  String _permissionLabel(AppPermission permission) {
    switch (permission) {
      case AppPermission.manageOrders:
        return 'Gestionar pedidos';
      case AppPermission.manageTables:
        return 'Gestionar mesas';
      case AppPermission.useKitchenDisplay:
        return 'Usar monitor de cocina';
      case AppPermission.processPayments:
        return 'Procesar pagos y caja';
      case AppPermission.manageMenu:
        return 'Gestionar menú';
      case AppPermission.manageUsers:
        return 'Gestionar usuarios y permisos';
      case AppPermission.viewReports:
        return 'Ver reportes';
      case AppPermission.viewAudit:
        return 'Ver auditoría';
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(onSave: (user) => _createUser(user)),
    );
  }

  void _showEditDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => _UserFormDialog(
        existingUser: user,
        onSave: (updated) => _updateUser(user.id, updated),
      ),
    );
  }

  Future<bool> _confirmDelete(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Text(
          'Eliminar Usuario',
          style: AppTypography.h2(color: AppColors.onSurface),
        ),
        content: Text(
          '¿Estás seguro de eliminar a "${user.name}"?',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppTypography.statusBadge(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: AppTypography.statusBadge(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _getRoleLabel(Role role) {
    switch (role) {
      case Role.admin:
        return 'Admin';
      case Role.mesero:
        return 'Sala';
      case Role.cocinero:
        return 'Cocina';
      case Role.cajero:
        return 'Caja';
    }
  }

  Color _getRoleColor(Role role) {
    switch (role) {
      case Role.admin:
        return AppColors.primaryContainer;
      case Role.mesero:
        return const Color(0xFF3B82F6);
      case Role.cocinero:
        return const Color(0xFF10B981);
      case Role.cajero:
        return const Color(0xFF8B5CF6);
    }
  }

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
                Expanded(child: _buildBody(isDesktop, isMobile, currentUser)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? StitchBottomNavBar(
              currentRoute: '/admin/users',
              currentUser: currentUser,
            )
          : null,
    );
  }

  Widget _buildBody(bool isDesktop, bool isMobile, User? currentUser) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
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
        Text(
          'Gestion de Personal',
          style: AppTypography.h1(color: AppColors.onBackground),
        ),
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
                  onPressed: _showRoleConfiguration,
                  icon: const Icon(Icons.manage_accounts, size: 18),
                  label: const Text('Configurar Roles'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: const BorderSide(color: Color(0xFFE1BFB3)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StitchPrimaryButton(
                  label: 'Nuevo Usuario',
                  icon: Icons.person_add,
                  onPressed: _showCreateDialog,
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
          onPressed: _showRoleConfiguration,
          icon: const Icon(Icons.manage_accounts, size: 18),
          label: const Text('Configurar Roles'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
            side: const BorderSide(color: Color(0xFFE1BFB3)),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StitchPrimaryButton(
          label: 'Nuevo Usuario',
          icon: Icons.person_add,
          width: 180,
          onPressed: _showCreateDialog,
        ),
      ],
    );
  }

  Widget _buildStats(bool isMobile) {
    final totalCount = _users.length.toString();
    final activeCount = _users.where((u) => u.isActive).length.toString();
    final rolesCount = Role.values.length.toString();

    final cards = [
      _buildStatCard(
        Icons.groups,
        'Total Usuarios',
        totalCount,
        const Color(0xFF3B82F6),
        'Registrados',
      ),
      _buildStatCard(
        Icons.verified_user,
        'Activos Ahora',
        activeCount,
        const Color(0xFF10B981),
        'En turno',
      ),
      _buildStatCard(
        Icons.lock_open,
        'Roles Definidos',
        rolesCount,
        AppColors.primaryContainer,
        'Permisos',
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: c,
              ),
            )
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
    IconData icon,
    String label,
    String value,
    Color color,
    String sub,
  ) {
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
              Text(
                label,
                style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
              ),
              Text(
                value,
                style: AppTypography.h2(color: AppColors.onBackground),
              ),
              Text(
                sub,
                style: AppTypography.labelCaps(color: color, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(bool isDesktop) {
    if (_users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [AppShadows.card],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay usuarios registrados',
              style: AppTypography.h3(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

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
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 52 + AppSpacing.md),
                Expanded(
                  flex: 4,
                  child: Text(
                    'NOMBRE',
                    style: AppTypography.labelCaps(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (isDesktop)
                  Expanded(
                    flex: 4,
                    child: Text(
                      'EMAIL',
                      style: AppTypography.labelCaps(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ROL',
                    style: AppTypography.labelCaps(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (isDesktop)
                  Expanded(
                    flex: 3,
                    child: Text(
                      'ULTIMA SESION',
                      style: AppTypography.labelCaps(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ESTADO',
                    style: AppTypography.labelCaps(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 80),
              ],
            ),
          ),
          // Rows
          ..._users.asMap().entries.map((entry) {
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

  Widget _buildUserRow(User user, bool isDesktop) {
    final roleColor = _getRoleColor(user.role);
    final roleLabel = _getRoleLabel(user.role);
    final emailLabel = user.email ?? '';
    final lastLoginLabel = user.lastLogin ?? 'Nunca';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with initial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                style: AppTypography.h3(color: roleColor),
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
                Text(
                  user.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLg(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (!isDesktop)
                  Text(
                    emailLabel,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd(color: const Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          // Email desktop
          if (isDesktop)
            Expanded(
              flex: 4,
              child: Text(
                emailLabel,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
              ),
            ),
          // Role
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  roleLabel,
                  style: AppTypography.statusBadge(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Last login desktop
          if (isDesktop)
            Expanded(
              flex: 3,
              child: Text(
                lastLoginLabel,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
              ),
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
                _iconBtn(
                  Icons.edit_outlined,
                  const Color(0xFF64748B),
                  () => _showEditDialog(user),
                ),
                _iconBtn(Icons.delete_outline, AppColors.error, () async {
                  final confirmed = await _confirmDelete(user);
                  if (confirmed) {
                    _deleteUser(user.id);
                  }
                }),
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
    final adminCount = _users
        .where((u) => u.role == Role.admin)
        .length
        .toString();
    final meseroCount = _users
        .where((u) => u.role == Role.mesero)
        .length
        .toString();
    final cocineroCount = _users
        .where((u) => u.role == Role.cocinero)
        .length
        .toString();
    final cajeroCount = _users
        .where((u) => u.role == Role.cajero)
        .length
        .toString();

    final roles = [
      _RoleData('Administradores', adminCount, AppColors.primaryContainer),
      _RoleData('Personal de Sala', meseroCount, const Color(0xFF3B82F6)),
      _RoleData('Personal de Cocina', cocineroCount, const Color(0xFF10B981)),
      _RoleData('Gestion de Caja', cajeroCount, const Color(0xFF8B5CF6)),
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
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildRoleRow(r),
                    ),
                  )
                  .toList(),
            )
          else
            Row(
              children: roles
                  .expand(
                    (r) => [
                      Expanded(child: _buildRoleCard(r)),
                      if (r != roles.last) const SizedBox(width: AppSpacing.sm),
                    ],
                  )
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
          decoration: BoxDecoration(shape: BoxShape.circle, color: role.color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            role.label,
            style: AppTypography.bodyMd(color: const Color(0xFF475569)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: role.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            role.count,
            style: AppTypography.statusBadge(
              color: role.color,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                decoration: BoxDecoration(
                  color: role.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    role.count,
                    style: AppTypography.statusBadge(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: role.color, size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            role.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd(
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleData {
  final String label;
  final String count;
  final Color color;

  const _RoleData(this.label, this.count, this.color);
}

// ────────────────────────────────────────────────────────────
// Create/Edit User Dialog
// ────────────────────────────────────────────────────────────

class _UserFormDialog extends StatefulWidget {
  final User? existingUser;
  final ValueChanged<User> onSave;

  const _UserFormDialog({this.existingUser, required this.onSave});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late Role _role;
  late bool _isActive;

  bool get _isEditing => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    final user = widget.existingUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _role = user?.role ?? Role.mesero;
    _isActive = user?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : widget.existingUser?.password;

    final user = User(
      id:
          widget.existingUser?.id ??
          'user-${DateTime.now().millisecondsSinceEpoch}',
      username: _usernameController.text.trim(),
      name: _nameController.text.trim(),
      role: _role,
      email: _emailController.text.trim(),
      isActive: _isActive,
      lastLogin: widget.existingUser?.lastLogin ?? 'Nunca',
      token: widget.existingUser?.token,
      password: password,
    );

    widget.onSave(user);
    Navigator.of(context).pop();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF594138),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF26522), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  String _getRoleLabel(Role role) {
    switch (role) {
      case Role.admin:
        return 'Admin';
      case Role.mesero:
        return 'Sala';
      case Role.cocinero:
        return 'Cocina';
      case Role.cajero:
        return 'Caja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl * 1.5),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl * 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.manage_accounts : Icons.person_add_alt_1,
                    color: AppColors.primaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                    style: AppTypography.h2(color: AppColors.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Datos de Cuenta',
                                style: AppTypography.h3(
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _nameController,
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                ),
                                decoration: _inputDecoration('Nombre completo'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _usernameController,
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                ),
                                decoration: _inputDecoration(
                                  'Nombre de usuario (Login)',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _emailController,
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                ),
                                decoration: _inputDecoration(
                                  'Correo electrónico',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Requerido';
                                  if (!v.contains('@'))
                                    return 'Email no válido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _passwordController,
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                ),
                                decoration: _inputDecoration(
                                  _isEditing
                                      ? 'Nueva contraseña (opcional)'
                                      : 'Contraseña',
                                ),
                                obscureText: true,
                                validator: (v) {
                                  if (!_isEditing &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Requerido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              DropdownButtonFormField<Role>(
                                value: _role,
                                dropdownColor: Colors.white,
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurface,
                                ),
                                decoration: _inputDecoration('Rol'),
                                items: Role.values
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(_getRoleLabel(r)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _role = v);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Text(
                                    'Usuario activo',
                                    style: AppTypography.bodyMd(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _isActive,
                                    onChanged: (v) =>
                                        setState(() => _isActive = v),
                                    activeColor: AppColors.primaryContainer,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      StitchPrimaryButton(
                        label: _isEditing ? 'Guardar Cambios' : 'Crear Usuario',
                        icon: _isEditing ? Icons.save : Icons.add,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

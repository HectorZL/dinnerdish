import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/table.dart' as table_model;
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/router/route_guards.dart';
import '../theme/app_theme.dart';

class TableManagementScreen extends ConsumerStatefulWidget {
  const TableManagementScreen({super.key});

  @override
  ConsumerState<TableManagementScreen> createState() =>
      _TableManagementScreenState();
}

class _TableManagementScreenState extends ConsumerState<TableManagementScreen> {
  Future<void> _showTableForm({table_model.Table? existing}) async {
    final table = await showDialog<table_model.Table>(
      context: context,
      builder: (_) => _TableFormDialog(existing: existing),
    );
    if (table == null) return;

    try {
      final service = ref.read(tableServiceProvider);
      if (existing == null) {
        await service.createTable(table);
      } else {
        await service.updateTable(existing.id, table);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la mesa: $error')),
      );
    }
  }

  void _openTable(
    table_model.Table table,
    List<Order> activeOrders,
    bool canManage,
  ) {
    if (canManage) {
      _showTableForm(existing: table);
      return;
    }
    if (table.status != table_model.TableStatus.occupied) return;
    final order = activeOrders
        .where((item) => item.tableId == table.id)
        .cast<Order?>()
        .firstWhere((item) => item != null, orElse: () => null);
    if (order != null) context.go('/orders/${order.id}');
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);
    final activeOrders = ref.watch(activeOrdersProvider).value ?? <Order>[];
    final currentUser = ref.watch(currentUserProvider).value;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final canManage = RouteGuard.canAccessAdmin(
      currentUser,
      ref.watch(rolePermissionsProvider),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: !isDesktop && canManage
          ? FloatingActionButton.extended(
              onPressed: _showTableForm,
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva mesa'),
            )
          : null,
      body: Column(
        children: [
          StitchTopAppBar(
            title: 'Mesas',
            showBack: true,
            onBack: () => context.go('/menu'),
            navLinks: isDesktop
                ? [
                    const NavLink('Inicio', false, route: '/menu'),
                    const NavLink('Pedidos', false, route: '/orders/tracking'),
                    const NavLink('Mesas', true, route: '/tables'),
                    if (canManage)
                      const NavLink('Menú', false, route: '/admin/menu'),
                  ]
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(canManage),
                      const SizedBox(height: AppSpacing.lg),
                      _buildLegend(),
                      const SizedBox(height: AppSpacing.lg),
                      tablesAsync.when(
                        data: (tables) =>
                            _buildTableGrid(tables, activeOrders, canManage),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => Center(
                          child: Text(
                            'No se pudieron cargar las mesas: $error',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? StitchBottomNavBar(
              currentRoute: '/tables',
              currentUser: currentUser,
            )
          : null,
    );
  }

  Widget _buildHeader(bool canManage) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.md,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista de salón', style: AppTypography.h2()),
            const SizedBox(height: AppSpacing.xs),
            Text(
              canManage
                  ? 'Crea mesas, ajusta su capacidad y cambia su estado.'
                  : 'Consulta la capacidad y disponibilidad de las mesas.',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        if (canManage)
          SizedBox(
            width: 170,
            child: StitchPrimaryButton(
              label: 'Nueva mesa',
              icon: Icons.add,
              onPressed: _showTableForm,
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _LegendItem(color: AppColors.tertiaryContainer, label: 'Disponible'),
        const _LegendItem(color: AppColors.primaryContainer, label: 'Ocupada'),
        const _LegendItem(color: Color(0xFF3B82F6), label: 'Reservada'),
      ],
    );
  }

  Widget _buildTableGrid(
    List<table_model.Table> tables,
    List<Order> activeOrders,
    bool canManage,
  ) {
    if (tables.isEmpty) {
      return StitchCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.table_restaurant_outlined,
                size: 48,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('No hay mesas configuradas', style: AppTypography.h3()),
              if (canManage) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: 180,
                  child: StitchPrimaryButton(
                    label: 'Crear mesa',
                    icon: Icons.add,
                    onPressed: _showTableForm,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return StitchCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: tables
            .map(
              (table) => _TableCard(
                table: table,
                canManage: canManage,
                onTap: () => _openTable(table, activeOrders, canManage),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.statusBadge()),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  final table_model.Table table;
  final bool canManage;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.canManage,
    required this.onTap,
  });

  Color get _statusColor {
    switch (table.status) {
      case table_model.TableStatus.available:
        return AppColors.tertiaryContainer;
      case table_model.TableStatus.occupied:
        return AppColors.primaryContainer;
      case table_model.TableStatus.reserved:
        return const Color(0xFF3B82F6);
    }
  }

  String get _statusLabel {
    switch (table.status) {
      case table_model.TableStatus.available:
        return 'Disponible';
      case table_model.TableStatus.occupied:
        return 'Ocupada';
      case table_model.TableStatus.reserved:
        return 'Reservada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Mesa ${table.number}, ${table.seats} personas, $_statusLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            width: 156,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    canManage ? Icons.edit_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: _statusColor,
                  ),
                ),
                Container(
                  width: 78,
                  height: 78,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor.withValues(alpha: 0.1),
                    border: Border.all(color: _statusColor, width: 6),
                  ),
                  child: Text(
                    table.number.toString().padLeft(2, '0'),
                    style: AppTypography.h2(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${table.seats} personas',
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _statusLabel.toUpperCase(),
                  style: AppTypography.statusBadge(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
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

class _TableFormDialog extends StatefulWidget {
  final table_model.Table? existing;

  const _TableFormDialog({this.existing});

  @override
  State<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<_TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _seatsController;
  late table_model.TableStatus _status;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: widget.existing?.number.toString() ?? '',
    );
    _seatsController = TextEditingController(
      text: widget.existing?.seats.toString() ?? '4',
    );
    _status = widget.existing?.status ?? table_model.TableStatus.available;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final number = int.parse(_numberController.text.trim());
    final seats = int.parse(_seatsController.text.trim());
    final id = widget.existing?.id ?? number.toString().padLeft(2, '0');
    Navigator.of(context).pop(
      table_model.Table(
        id: id,
        number: number,
        seats: seats,
        status: _status,
        section: widget.existing?.section,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primaryContainer, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(
          color: AppColors.primaryContainer,
          width: 2,
        ),
      ),
    );
  }

  String _statusLabel(table_model.TableStatus status) {
    switch (status) {
      case table_model.TableStatus.available:
        return 'Disponible';
      case table_model.TableStatus.occupied:
        return 'Ocupada';
      case table_model.TableStatus.reserved:
        return 'Reservada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl * 1.5),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl * 1.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note : Icons.add_circle_outline,
                    color: AppColors.primaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Editar mesa' : 'Nueva mesa',
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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Configuración de la mesa',
                      style: AppTypography.h3(
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Número de mesa', Icons.tag),
                      validator: (value) {
                        final number = int.tryParse(value?.trim() ?? '');
                        return number == null || number <= 0
                            ? 'Ingresa un número válido'
                            : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _seatsController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        'Capacidad (personas)',
                        Icons.group_outlined,
                      ),
                      validator: (value) {
                        final seats = int.tryParse(value?.trim() ?? '');
                        return seats == null || seats <= 0
                            ? 'Ingresa una capacidad válida'
                            : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<table_model.TableStatus>(
                      initialValue: _status,
                      decoration: _inputDecoration(
                        'Estado',
                        Icons.event_available_outlined,
                      ),
                      items: table_model.TableStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                          )
                          .toList(),
                      onChanged: (status) {
                        if (status != null) setState(() => _status = status);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.xl * 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                    label: Text(_isEditing ? 'Guardar cambios' : 'Crear mesa'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

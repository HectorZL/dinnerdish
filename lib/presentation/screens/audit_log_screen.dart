import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  final String? initialUserId;
  const AuditLogScreen({this.initialUserId, super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  List<AuditEntry> _entries = [];
  List<User> _users = [];
  String? _selectedUserId;
  String _selectedActionFilter = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.initialUserId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auditService = ref.read(auditServiceProvider);
      final entries = await auditService.list(limit: 300);
      List<User> users = [];
      try {
        users = await ref.read(userServiceProvider).fetchUsers();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _entries = entries;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  User? _findUser(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  String _getUserDisplayName(String userId) {
    final user = _findUser(userId);
    if (user != null) {
      return '${user.name} ($userId)';
    }
    return userId;
  }

  List<AuditEntry> get _filteredEntries {
    return _entries.where((entry) {
      if (_selectedUserId != null && _selectedUserId!.isNotEmpty) {
        if (entry.userId != _selectedUserId) return false;
      }
      if (_selectedActionFilter != 'all') {
        if (!entry.action.toLowerCase().contains(_selectedActionFilter.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Color _actionColor(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('kitchen') || lower.contains('cocina')) {
      return AppColors.statusCooking;
    }
    if (lower.contains('payment') || lower.contains('pago') || lower.contains('cash')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('item_added') || lower.contains('created')) {
      return AppColors.primaryContainer;
    }
    if (lower.contains('removed') || lower.contains('delete') || lower.contains('cancel')) {
      return AppColors.error;
    }
    if (lower.contains('status') || lower.contains('ready')) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFF8B5CF6);
  }

  IconData _actionIcon(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('kitchen')) return Icons.kitchen;
    if (lower.contains('payment') || lower.contains('cash')) return Icons.payments;
    if (lower.contains('item_added')) return Icons.add_circle;
    if (lower.contains('removed')) return Icons.remove_circle;
    if (lower.contains('created')) return Icons.receipt_long;
    if (lower.contains('status')) return Icons.sync;
    if (lower.contains('table')) return Icons.table_restaurant;
    return Icons.history;
  }

  String _humanAction(String action) {
    switch (action) {
      case 'order.created':
        return 'Creó comanda';
      case 'order.item_added':
        return 'Agregó plato / item';
      case 'order.item_updated':
        return 'Modificó plato / item';
      case 'order.item_removed':
        return 'Eliminó plato / item';
      case 'order.sent_to_kitchen':
        return 'Envió comanda a cocina';
      case 'order.status_updated':
        return 'Actualizó estado de comanda';
      case 'order.item_status_updated':
        return 'Actualizó estado de plato';
      case 'order.table_updated':
        return 'Cambió mesa de comanda';
      case 'order.cashier_additional_added':
        return 'Agregó adicional en caja';
      default:
        return action.replaceAll('_', ' ').replaceAll('.', ' • ').toUpperCase();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StitchTopAppBar(
              title: 'Registro de Auditoría Personal',
              showBack: true,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/menu');
                }
              },
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primaryContainer),
                  tooltip: 'Actualizar',
                  onPressed: _loadData,
                ),
                const SizedBox(width: 8),
              ],
            ),
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.white,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // User / Waiter Filter
                  SizedBox(
                    width: isDesktop ? 280 : double.infinity,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedUserId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por Personal / Mesero',
                        prefixIcon: const Icon(Icons.person_search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los miembros del personal'),
                        ),
                        ..._users.map((u) {
                          final rolesStr = u.roles.map((r) => r.name).join(',');
                          return DropdownMenuItem<String?>(
                            value: u.id,
                            child: Text(
                              '${u.name} ($rolesStr)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedUserId = val);
                      },
                    ),
                  ),
                  // Action Category Filter
                  SizedBox(
                    width: isDesktop ? 220 : double.infinity,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedActionFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Acción',
                        prefixIcon: const Icon(Icons.filter_list, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todas las acciones')),
                        DropdownMenuItem(value: 'item', child: Text('Platos e Items')),
                        DropdownMenuItem(value: 'kitchen', child: Text('Cocina')),
                        DropdownMenuItem(value: 'status', child: Text('Estados')),
                        DropdownMenuItem(value: 'payment', child: Text('Pagos y Caja')),
                        DropdownMenuItem(value: 'table', child: Text('Mesas')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedActionFilter = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedUserId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: AppColors.primaryContainer.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    const Icon(Icons.badge, color: AppColors.primaryContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Auditoría personal: ${_getUserDisplayName(_selectedUserId!)} • ${filtered.length} registro(s)',
                        style: AppTypography.bodyMd(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Quitar filtro de usuario',
                      onPressed: () => setState(() => _selectedUserId = null),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: $_errorMessage',
                                  style: AppTypography.bodyMd(color: AppColors.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_outlined,
                                      size: 54, color: AppColors.outline.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay registros de auditoría que coincidan',
                                    style: AppTypography.h3(color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: filtered.length,
                              separatorBuilder: (ctx, idx) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final entry = filtered[idx];
                                return _buildEntryCard(entry);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(AuditEntry entry) {
    final color = _actionColor(entry.action);
    final user = _findUser(entry.userId);
    final userName = user?.name ?? entry.userId;
    final meta = entry.metadata ?? {};
    final dishName = meta['name'] ?? meta['items'] ?? meta['additionalName'];
    final tableId = meta['tableId'];
    final orderId = meta['orderId'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEntryDetail(entry),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: StitchCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  _actionIcon(entry.action),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _humanAction(entry.action),
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(entry.timestamp),
                          style: AppTypography.statusBadge(color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Responsible Staff Info
                    Row(
                      children: [
                        Icon(Icons.person_pin, size: 14, color: AppColors.primaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          'Responsable: ',
                          style: AppTypography.statusBadge(color: const Color(0xFF64748B)),
                        ),
                        Text(
                          '$userName (ID: ${entry.userId})',
                          style: AppTypography.statusBadge(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (dishName != null || tableId != null || orderId != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (tableId != null && tableId.toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                'Mesa $tableId',
                                style: AppTypography.statusBadge(color: AppColors.onSurface),
                              ),
                            ),
                          if (dishName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '$dishName ${meta['quantity'] != null ? '(x${meta['quantity']})' : ''}'.trim(),
                                style: AppTypography.statusBadge(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (orderId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'Comanda: $orderId',
                                style: AppTypography.statusBadge(color: const Color(0xFF64748B)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryDetail(AuditEntry entry) {
    final user = _findUser(entry.userId);
    final userName = user != null ? '${user.name} (${entry.userId})' : entry.userId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Text(
          _humanAction(entry.action),
          style: AppTypography.h2(color: AppColors.onSurface),
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('ID Registro', entry.id),
              _detailRow('Personal', userName),
              _detailRow('Fecha y Hora', entry.timestamp.toIso8601String()),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Datos de la Operación:',
                style: AppTypography.bodyMd(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  entry.metadata?.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n') ??
                      'Sin metadata adicional',
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cerrar',
              style: AppTypography.statusBadge(color: AppColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTypography.statusBadge(color: AppColors.onSurfaceVariant)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMd(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

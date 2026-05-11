import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import '../theme/app_theme.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  List<AuditEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auditService = ref.read(auditServiceProvider);
      final entries = await auditService.list(limit: 200);
      if (mounted) {
        setState(() {
          _entries = entries;
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

  Color _actionColor(String action) {
    switch (action) {
      case 'send_to_kitchen':
        return AppColors.statusCooking;
      case 'request_payment':
        return AppColors.primaryContainer;
      case 'add_item':
        return AppColors.statusReady;
      case 'remove_item':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'send_to_kitchen':
        return Icons.kitchen;
      case 'request_payment':
        return Icons.payments;
      case 'add_item':
        return Icons.add_circle;
      case 'remove_item':
        return Icons.remove_circle;
      case 'create_order':
        return Icons.receipt;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StitchTopAppBar(
              title: 'Registro de Auditoría',
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
                  icon: const Icon(Icons.refresh,
                      color: AppColors.primaryContainer),
                  onPressed: _loadEntries,
                ),
                const SizedBox(width: 8),
              ],
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
                                  style: AppTypography.bodyMd(
                                      color: AppColors.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadEntries,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primaryContainer,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _entries.isEmpty
                          ? const Center(
                              child: Text(
                                  'No hay registros de auditoría'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: _entries.length,
                              separatorBuilder: (ctx, idx) =>
                                  const Divider(
                                      height: 1,
                                      color: Color(0xFFF1F5F9)),
                              itemBuilder: (ctx, idx) {
                                final entry = _entries[idx];
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEntryDetail(entry),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: StitchCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _actionColor(entry.action).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(
                  _actionIcon(entry.action),
                  color: _actionColor(entry.action),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.action.replaceAll('_', ' ').toUpperCase(),
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.userId} • ${_formatDate(entry.timestamp)}',
                      style: AppTypography.statusBadge(
                          color: AppColors.outline),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showEntryDetail(AuditEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Text(
          entry.action.replaceAll('_', ' '),
          style: AppTypography.h2(color: AppColors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ID', entry.id),
            _detailRow('Usuario', entry.userId),
            _detailRow('Fecha', entry.timestamp.toIso8601String()),
            const SizedBox(height: AppSpacing.sm),
            const Text('Metadata:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              entry.metadata
                      ?.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join('\n') ??
                  'N/A',
              style: const TextStyle(
                  fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cerrar',
              style: AppTypography.statusBadge(
                  color: AppColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: AppTypography.statusBadge(
                      color: AppColors.onSurfaceVariant)
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


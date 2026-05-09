import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/payment_transaction.dart';
import '../theme/app_theme.dart';

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  List<PaymentTransaction> _pendingRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final requests = paymentService.watchPendingRequests();
      if (!mounted) return;
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
              showBack: true,
              onBack: () => context.go('/menu'),
              title: 'Facturación',
              navLinks: const [
                NavLink('Facturación', true),
                NavLink('Pedidos', false),
                NavLink('Mesas', false),
              ],
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: AppColors.error.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTypography.bodyMd(
                    color: AppColors.onSurface.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPendingRequests,
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

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64,
              color: AppColors.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay solicitudes de pago pendientes',
              style: AppTypography.bodyMd(
                  color: AppColors.outline.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryContainer,
      onRefresh: _loadPendingRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _pendingRequests.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(PaymentTransaction request) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/orders/${request.orderId}/payment'),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: StitchCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orden #${request.orderId}',
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurface).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.outline.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Solicitado por: ${request.processedBy}',
                          style: AppTypography.statusBadge(
                              color: AppColors.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.outline.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(request.createdAt),
                          style: AppTypography.statusBadge(
                              color: AppColors.outline),
                        ),
                      ],
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

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

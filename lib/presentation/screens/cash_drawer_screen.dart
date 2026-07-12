import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/cash_drawer_session.dart';
import '../theme/app_theme.dart';

class CashDrawerScreen extends ConsumerStatefulWidget {
  const CashDrawerScreen({super.key});

  @override
  ConsumerState<CashDrawerScreen> createState() => _CashDrawerScreenState();
}

class _CashDrawerScreenState extends ConsumerState<CashDrawerScreen> {
  CashDrawerSession? _currentSession;
  List<CashDrawerSession> _sessionHistory = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cashDrawerService = ref.read(cashDrawerServiceProvider);
      final current = await cashDrawerService.getCurrentSession();
      final history = await cashDrawerService.getSessionHistory();
      if (!mounted) return;
      setState(() {
        _currentSession = current;
        _sessionHistory = history;
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

  Future<void> _openDrawer() async {
    if (_isProcessing || _currentSession != null) return;

    setState(() => _isProcessing = true);

    try {
      final cashDrawerService = ref.read(cashDrawerServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      final session = await cashDrawerService.openDrawer(cashierId: currentUser.id);
      if (!mounted) return;
      setState(() {
        _currentSession = session;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caja abierta: Sesión #${session.id}'),
          backgroundColor: AppColors.statusReady,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _closeDrawer() async {
    if (_isProcessing || _currentSession == null) return;

    final actualAmount = await _showAmountDialog(
      title: 'Cerrar Caja',
      message: 'Ingrese el monto real en caja:',
    );

    if (actualAmount == null) return;

    setState(() => _isProcessing = true);

    try {
      final cashDrawerService = ref.read(cashDrawerServiceProvider);
      final session = await cashDrawerService.closeDrawer(
        sessionId: _currentSession!.id,
        actualBalanceCents: actualAmount,
      );
      if (!mounted) return;
      setState(() {
        _currentSession = session;
        _isProcessing = false;
      });

      _showCloseResult(session);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar caja: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  void _showCloseResult(CashDrawerSession session) {
    final diff = session.differenceCents;
    final diffAbs = diff.abs();
    final diffText = '\$${(diffAbs / 100).toStringAsFixed(2)}';
    final isPositive = diff >= 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle : Icons.warning,
              color: isPositive ? AppColors.statusReady : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Caja Cerrada',
              style: AppTypography.h2(color: AppColors.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('Esperado',
                '\$${(session.expectedBalanceCents / 100).toStringAsFixed(2)}'),
            const SizedBox(height: AppSpacing.base),
            _buildResultRow('Real',
                '\$${(session.actualBalanceCents / 100).toStringAsFixed(2)}'),
            const SizedBox(height: AppSpacing.base),
            _buildResultRow(
              'Diferencia',
              '${isPositive ? '+' : '-'}$diffText',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Aceptar',
              style: AppTypography.statusBadge(
                  color: AppColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMd(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
        Text(value,
            style: AppTypography.bodyMd(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _reconcile() async {
    if (_isProcessing || _currentSession == null) return;

    final actualAmount = await _showAmountDialog(
      title: 'Conciliar Caja',
      message: 'Ingrese el monto final para conciliar:',
    );

    if (actualAmount == null) return;

    setState(() => _isProcessing = true);

    try {
      final cashDrawerService = ref.read(cashDrawerServiceProvider);
      final reconciled = await cashDrawerService.reconcile(
        sessionId: _currentSession!.id,
        actualBalanceCents: actualAmount,
      );
      if (!mounted) return;
      setState(() {
        _currentSession = reconciled;
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Caja reconciliada. Diferencia: \$${(reconciled.differenceCents / 100).toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.statusReady,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al conciliar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<int?> _showAmountDialog({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl * 2),
        ),
        title: Text(
          title,
          style: AppTypography.h2(color: AppColors.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTypography.bodyMd(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: AppTypography.bodyMd(color: AppColors.onSurface),
                hintText: '0.00',
                hintStyle: AppTypography.bodyMd(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(
                    color: AppColors.primaryContainer,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              style: AppTypography.bodyMd(color: AppColors.onSurface),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Cancelar',
              style: AppTypography.statusBadge(
                  color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = (double.tryParse(controller.text) ?? 0) * 100;
              controller.dispose();
              Navigator.of(ctx).pop(amount.round());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Confirmar',
              style: AppTypography.statusBadge(
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return result;
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
              title: 'Caja',
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

    if (_currentSession == null && _sessionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.point_of_sale_outlined,
              size: 64,
              color: AppColors.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay sesiones de caja',
              style: AppTypography.bodyMd(
                  color: AppColors.outline.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            _buildOpenButton(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryContainer,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_currentSession != null) ...[
            _buildSessionCard(_currentSession!),
            const SizedBox(height: AppSpacing.md),
            _buildActionButtons(),
          ] else ...[
            _buildNoSessionCard(),
            const SizedBox(height: AppSpacing.md),
            _buildOpenButton(),
          ],
          if (_sessionHistory.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Historial de Sesiones',
              style: AppTypography.h2(),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._sessionHistory.map((s) => _buildHistoryItem(s)),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionCard(CashDrawerSession session) {
    final statusColor = switch (session.status) {
      CashDrawerStatus.open => AppColors.statusReady,
      CashDrawerStatus.closed => Colors.orange,
      CashDrawerStatus.reconciled => Colors.blue,
    };

    final statusLabel = switch (session.status) {
      CashDrawerStatus.open => 'Abierta',
      CashDrawerStatus.closed => 'Cerrada',
      CashDrawerStatus.reconciled => 'Reconciliada',
    };

    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sesión #${session.id}',
                style: AppTypography.h3(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.statusBadge(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBalanceRow(
            'Saldo Inicial', session.startingBalanceCents),
          const SizedBox(height: AppSpacing.base),
          _buildBalanceRow(
            'Saldo Esperado', session.expectedBalanceCents),
          const SizedBox(height: AppSpacing.base),
          _buildBalanceRow(
            'Saldo Actual', session.actualBalanceCents),
          if (session.status != CashDrawerStatus.open) ...[
            const Divider(
                height: 24, color: Color(0xFFF1F5F9)),
            _buildBalanceRow(
              'Diferencia',
              session.differenceCents,
              isDifference: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, int cents,
      {bool isDifference = false}) {
    final value = '\$${(cents / 100).toStringAsFixed(2)}';
    final color = isDifference
        ? (cents >= 0 ? AppColors.statusReady : AppColors.error)
        : AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMd(
                  color: AppColors.onSurfaceVariant)),
          Text(
            isDifference && cents >= 0 ? '+$value' : value,
            style: AppTypography.bodyMd(
                color: color,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final session = _currentSession;
    if (session == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (session.status == CashDrawerStatus.open)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _closeDrawer,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                _isProcessing ? 'Cerrando...' : 'Cerrar Caja',
                style: AppTypography.statusBadge(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.orange.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
        if (session.status == CashDrawerStatus.closed) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _reconcile,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified),
              label: Text(
                _isProcessing ? 'Conciliando...' : 'Conciliar',
                style: AppTypography.statusBadge(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blue.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoSessionCard() {
    return StitchCard(
      child: Column(
        children: [
          Icon(
            Icons.point_of_sale,
            size: 48,
            color: AppColors.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hay sesión de caja abierta',
            style: AppTypography.bodyMd(
                color: AppColors.outline.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _openDrawer,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_open),
        label: Text(
          _isProcessing ? 'Abriendo...' : 'Abrir Caja',
          style: AppTypography.statusBadge(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.statusReady,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.statusReady.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(CashDrawerSession session) {
    final statusLabel = switch (session.status) {
      CashDrawerStatus.open => 'Abierta',
      CashDrawerStatus.closed => 'Cerrada',
      CashDrawerStatus.reconciled => 'Reconciliada',
    };

    final statusColor = switch (session.status) {
      CashDrawerStatus.open => AppColors.statusReady,
      CashDrawerStatus.closed => Colors.orange,
      CashDrawerStatus.reconciled => Colors.blue,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StitchCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesión #${session.id}',
                    style: AppTypography.bodyMd(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.openedAt.day}/${session.openedAt.month}/${session.openedAt.year}',
                    style: AppTypography.statusBadge(
                        color: AppColors.outline),
                  ),
                ],
              ),
            ),
            Text(
              '\$${(session.actualBalanceCents / 100).toStringAsFixed(2)}',
              style: AppTypography.bodyMd(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                statusLabel,
                style: AppTypography.statusBadge(color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


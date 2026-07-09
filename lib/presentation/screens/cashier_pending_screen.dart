import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/order.dart';
import '../theme/app_theme.dart';

/// Screen for cashier to see pending-payment orders (status = ready),
/// confirming they have been physically delivered and need billing.
class CashierPendingScreen extends ConsumerWidget {
  const CashierPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    final readyOrders = activeOrdersAsync.value
            ?.where((o) => o.status == OrderStatus.ready)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StitchTopAppBar(
              title: 'Pendientes de Cobro',
              showBack: true,
              onBack: () => context.go('/cashier/payments'),
            ),
            // Header count badge
            Container(
              width: double.infinity,
              color: AppColors.primaryFixed,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      size: 16, color: AppColors.primaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    '${readyOrders.length} orden(es) lista(s) para cobrar',
                    style: AppTypography.statusBadge(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: activeOrdersAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : readyOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_empty,
                                size: 64,
                                color: AppColors.outline.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sin órdenes pendientes',
                                style: AppTypography.bodyMd(
                                    color: AppColors.outline
                                        .withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aquí aparecerán las órdenes que la cocina marque como listas',
                                style: AppTypography.statusBadge(
                                    color: AppColors.outline
                                        .withValues(alpha: 0.4)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: readyOrders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final order = readyOrders[index];
                            return _PendingOrderCard(order: order);
                          },
                        ),
            ),
            if (currentUser != null)
              StitchBottomNavBar(
                currentRoute: '/cashier/pending',
                currentUser: currentUser,
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  final Order order;

  const _PendingOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final totalFormatted =
        '\$${(order.totalCents / 100).toStringAsFixed(2)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/orders/${order.id}/payment'),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: StitchCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(
                      Icons.table_restaurant,
                      color: Color(0xFFFACC15),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mesa ${order.tableId}',
                              style: AppTypography.bodyMd(
                                      color: AppColors.onSurface)
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.statusReady
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✓ LISTA',
                                style: AppTypography.statusBadge(
                                    color: AppColors.statusReady),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.items.length} plato(s)',
                          style: AppTypography.statusBadge(
                              color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        totalFormatted,
                        style: AppTypography.bodyMd(
                                color: AppColors.primaryContainer)
                            .copyWith(
                                fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'total',
                        style: AppTypography.statusBadge(
                            color: AppColors.outline),
                      ),
                    ],
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(height: 1, color: AppColors.outline.withValues(alpha: 0.1)),
                const SizedBox(height: AppSpacing.sm),
                ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: AppTypography.statusBadge(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.name ?? item.menuItemId,
                              style: AppTypography.statusBadge(
                                  color: AppColors.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 3)
                  Text(
                    '+ ${order.items.length - 3} más...',
                    style: AppTypography.statusBadge(
                        color: AppColors.outline.withValues(alpha: 0.6)),
                  ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.go('/orders/${order.id}/payment'),
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  label: const Text('Cobrar ahora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

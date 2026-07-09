import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/order.dart';
import '../theme/app_theme.dart';

class CashierScreen extends ConsumerWidget {
  const CashierScreen({super.key});

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
              showBack: true,
              onBack: () => context.go('/menu'),
              title: 'Facturación',
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
                                Icons.check_circle_outline,
                                size: 64,
                                color: AppColors.outline.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay órdenes listas para cobrar',
                                style: AppTypography.bodyMd(
                                    color: AppColors.outline.withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Las órdenes aparecerán aquí cuando la cocina las marque como listas',
                                style: AppTypography.statusBadge(
                                    color: AppColors.outline.withValues(alpha: 0.4)),
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
                            return _ReadyOrderCard(order: order);
                          },
                        ),
            ),
            if (currentUser != null)
              StitchBottomNavBar(
                currentRoute: '/cashier/payments',
                currentUser: currentUser,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadyOrderCard extends StatelessWidget {
  final Order order;

  const _ReadyOrderCard({required this.order});

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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.statusReady.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.statusReady,
                  size: 24,
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
                          style: AppTypography.bodyMd(color: AppColors.onSurface)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.statusReady.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LISTA',
                            style: AppTypography.statusBadge(
                                color: AppColors.statusReady),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} plato(s) · $totalFormatted',
                      style: AppTypography.statusBadge(color: AppColors.outline),
                    ),
                    if (order.readyAt != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.outline.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lista: ${_formatTime(order.readyAt!)}',
                            style: AppTypography.statusBadge(
                                color: AppColors.outline),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.point_of_sale,
                color: AppColors.statusReady,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

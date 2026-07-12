import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/order_item.dart' as oi;
import 'package:dinnerhome/widgets/kds_ticket.dart';
import '../theme/app_theme.dart';

class KdsScreen extends ConsumerStatefulWidget {
  const KdsScreen({super.key});

  @override
  ConsumerState<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends ConsumerState<KdsScreen> {
  String? _getCurrentUserId() {
    return ref.read(currentUserProvider).value?.id;
  }

  Future<void> _markAsPrepping(Order order) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión')),
      );
      return;
    }

    try {
      final orderService = ref.read(orderServiceProvider);
      await orderService.updateStatus(
        orderId: order.id,
        status: OrderStatus.prepping,
        byUserId: userId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markAsReady(Order order) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión')),
      );
      return;
    }

    try {
      final orderService = ref.read(orderServiceProvider);
      // F3-01: Marcar cada ítem pendiente como listo para que el auto-promote funcione correctamente.
      // Esto evita el bypass de la lógica de ítems individuales.
      final pendingItems = order.items
          .where((item) =>
              item.status != oi.OrderStatus.ready &&
              item.status != oi.OrderStatus.served)
          .toList();

      for (final item in pendingItems) {
        await orderService.updateItemStatus(
          orderId: order.id,
          itemId: item.id,
          status: oi.OrderStatus.ready,
          byUserId: userId,
        );
      }
      // Si no había ítems pendientes, forzar la transición directamente
      if (pendingItems.isEmpty) {
        await orderService.updateStatus(
          orderId: order.id,
          status: OrderStatus.ready,
          byUserId: userId,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markItemAsReady(Order order, String itemId) async {
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión')),
      );
      return;
    }

    try {
      final orderService = ref.read(orderServiceProvider);
      // Asumiendo que has importado 'package:dinnerhome/models/order_item.dart' as oi
      // Pero mejor usamos dynamic o si podemos usamos OrderStatus desde order_item
      await orderService.updateItemStatus(
        orderId: order.id,
        itemId: itemId,
        status: oi.OrderStatus.ready, // Esto requiere importar order_item como oi
        byUserId: userId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final activeOrders = activeOrdersAsync.value ?? [];
    
    final pendingTickets = activeOrders.where((o) => o.status == OrderStatus.sentToKitchen).toList();
    final preppingTickets = activeOrders.where((o) => o.status == OrderStatus.prepping).toList();
    final readyTickets = activeOrders.where((o) => o.status == OrderStatus.ready).toList();

    final hasTickets = pendingTickets.isNotEmpty || preppingTickets.isNotEmpty || readyTickets.isNotEmpty;
    final isConnected = !activeOrdersAsync.hasError;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            StitchTopAppBar(
              title: 'Monitor de Cocina',
              showBack: true,
              onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/menu');
                  }
                },
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: isConnected ? AppColors.statusReady : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? 'Conectado' : 'Desconectado',
                        style: AppTypography.statusBadge(
                          color: isConnected ? AppColors.statusReady : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: !hasTickets
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 64,
                              color: AppColors.outline.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Esperando órdenes...',
                            style: AppTypography.bodyMd(
                                color: AppColors.outline.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    )
                  : DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            color: Colors.white,
                            child: TabBar(
                              indicatorColor: AppColors.primaryContainer,
                              labelColor: AppColors.primaryContainer,
                              unselectedLabelColor: const Color(0xFF94A3B8),
                              labelStyle: AppTypography.statusBadge(),
                              unselectedLabelStyle: AppTypography.statusBadge(
                                  color: const Color(0xFF94A3B8)),
                              tabs: [
                                Tab(
                                    text:
                                        'Pendientes (${pendingTickets.length})'),
                                Tab(
                                    text:
                                        'Preparando (${preppingTickets.length})'),
                                Tab(
                                    text:
                                        'Listos (${readyTickets.length})'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildTicketGrid(pendingTickets,
                                    isPending: true),
                                _buildTicketGrid(preppingTickets),
                                _buildTicketGrid(readyTickets,
                                    isReady: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketGrid(List<Order> tickets,
      {bool isPending = false, bool isReady = false}) {
    if (tickets.isEmpty) {
      return Center(
        child: Text('Sin tickets',
            style: AppTypography.bodyMd(
                color: AppColors.outline.withValues(alpha: 0.5))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);

        if (crossAxisCount == 1) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: tickets.length,
            itemBuilder: (ctx, idx) {
              final order = tickets[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: KdsTicket(
                  order: order,
                  shrinkWrap: true,
                  onMarkPrepping: isPending ? () => _markAsPrepping(order) : null,
                  onMarkReady: !isPending && !isReady
                      ? () => _markAsReady(order)
                      : null,
                  onItemMarkReady: !isPending && !isReady
                      ? (itemId) => _markItemAsReady(order, itemId)
                      : null,
                ),
              );
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.sm),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: tickets.length,
          itemBuilder: (ctx, idx) {
            final order = tickets[idx];
            return KdsTicket(
              order: order,
              shrinkWrap: false,
              onMarkPrepping: isPending ? () => _markAsPrepping(order) : null,
              onMarkReady: !isPending && !isReady
                  ? () => _markAsReady(order)
                  : null,
              onItemMarkReady: !isPending && !isReady
                  ? (itemId) => _markItemAsReady(order, itemId)
                  : null,
            );
          },
        );
      },
    );
  }
}

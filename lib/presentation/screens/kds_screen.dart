import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/widgets/kds_ticket.dart';
import '../theme/app_theme.dart';

class KdsScreen extends ConsumerStatefulWidget {
  const KdsScreen({super.key});

  @override
  ConsumerState<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends ConsumerState<KdsScreen> {
  final List<Order> _pendingTickets = [];
  final List<Order> _preppingTickets = [];
  final List<Order> _readyTickets = [];
  StreamSubscription? _subscription;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _subscribeToOrders();
  }

  void _subscribeToOrders() {
    final socketService = ref.read(socketServiceProvider);
    _subscription = socketService.orderEvents.listen((event) {
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _sortTicket(event.order);
      });
    });
  }

  void _sortTicket(Order order) {
    _pendingTickets.removeWhere((o) => o.id == order.id);
    _preppingTickets.removeWhere((o) => o.id == order.id);
    _readyTickets.removeWhere((o) => o.id == order.id);

    switch (order.status) {
      case OrderStatus.sentToKitchen:
        _pendingTickets.add(order);
      case OrderStatus.prepping:
        _preppingTickets.add(order);
      case OrderStatus.ready:
        _readyTickets.add(order);
      default:
        break;
    }
  }

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
      await orderService.updateStatus(
        orderId: order.id,
        status: OrderStatus.ready,
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
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTickets = _pendingTickets.isNotEmpty ||
        _preppingTickets.isNotEmpty ||
        _readyTickets.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            StitchTopAppBar(
              showBack: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: _isConnected ? AppColors.statusReady : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected ? 'Conectado' : 'Desconectado',
                        style: AppTypography.statusBadge(
                          color: _isConnected ? AppColors.statusReady : AppColors.error,
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
                                        'Pendientes (${_pendingTickets.length})'),
                                Tab(
                                    text:
                                        'Preparando (${_preppingTickets.length})'),
                                Tab(
                                    text:
                                        'Listos (${_readyTickets.length})'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildTicketGrid(_pendingTickets,
                                    isPending: true),
                                _buildTicketGrid(_preppingTickets),
                                _buildTicketGrid(_readyTickets,
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
              onMarkPrepping: isPending ? () => _markAsPrepping(order) : null,
              onMarkReady: !isPending && !isReady
                  ? () => _markAsReady(order)
                  : null,
            );
          },
        );
      },
    );
  }
}

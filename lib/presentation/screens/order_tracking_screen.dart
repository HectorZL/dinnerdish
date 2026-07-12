import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/providers/providers.dart';
import '../theme/app_theme.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeOrdersAsync = ref.watch(activeOrdersProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final isMobile = !isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            StitchTopAppBar(
              title: 'Gestión de Pedidos',
              showBack: false,
              onBack: () => context.go('/menu'),
              navLinks: isDesktop
                  ? [
                      const NavLink('Inicio', false),
                      const NavLink('Pedidos', true),
                      const NavLink('Mesas', false),
                    ]
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerPadding,
                    vertical: AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDesktop),
                        const SizedBox(height: AppSpacing.xl),
                        _buildFilters(activeOrdersAsync),
                        const SizedBox(height: AppSpacing.xl),
                        _buildOrderGrid(isDesktop, activeOrdersAsync, menuItemsAsync.value ?? []),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isMobile && currentUser != null)
              StitchBottomNavBar(
                currentRoute: '/orders/tracking',
                currentUser: currentUser,
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(bool isDesktop) {
    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seguimiento en Tiempo Real',
              style: AppTypography.labelCaps(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Gestión de Pedidos',
              style: AppTypography.h1(color: AppColors.onBackground),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(AsyncValue<List<Order>> activeOrdersAsync) {
    final orders = activeOrdersAsync.value ?? [];
    int allCount = orders.length;
    int pendingCount = orders.where((o) => o.status == OrderStatus.sentToKitchen).length;
    int preppingCount = orders.where((o) => o.status == OrderStatus.prepping).length;
    int readyCount = orders.where((o) => o.status == OrderStatus.ready).length;
    int billedCount = orders.where((o) => o.status == OrderStatus.billed).length;

    final filters = [
      'Todos ($allCount)',
      'Pendiente ($pendingCount)',
      'En Cocina ($preppingCount)',
      'Listo ($readyCount)',
      'Por cobrar ($billedCount)'
    ];
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.sm,
      children: List.generate(filters.length, (index) {
        final isActive = _selectedFilterIndex == index;
        return ChoiceChip(
          label: Text(
            filters[index],
            style: AppTypography.statusBadge(
              color: isActive ? Colors.white : const Color(0xFF475569),
            ),
          ),
          selected: isActive,
          onSelected: (selected) {
            setState(() => _selectedFilterIndex = index);
          },
          backgroundColor: Colors.white,
          selectedColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color:
                    isActive ? Colors.transparent : const Color(0xFFF1F5F9)),
          ),
          elevation: isActive ? 4 : 0,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        );
      }),
    );
  }
  Widget _buildOrderGrid(bool isDesktop, AsyncValue<List<Order>> activeOrdersAsync, List<MenuItem> menuItems) {
    return activeOrdersAsync.when(
      data: (orders) {
        final filteredOrders = orders.where((order) {
          if (_selectedFilterIndex == 0) return true;
          if (_selectedFilterIndex == 1) return order.status == OrderStatus.sentToKitchen;
          if (_selectedFilterIndex == 2) return order.status == OrderStatus.prepping;
          if (_selectedFilterIndex == 3) return order.status == OrderStatus.ready;
          if (_selectedFilterIndex == 4) return order.status == OrderStatus.billed;
          return true;
        }).toList();

        if (filteredOrders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('No hay pedidos que coincidan con el filtro.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 1,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
            childAspectRatio: isDesktop ? 1.1 : 1.2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            String statusText = '';
            Color statusColor = AppColors.primaryContainer;
            Color bgColor = const Color(0xFFFFF7ED); // default orange-ish background

            switch (order.status) {
              case OrderStatus.draft:
                statusText = 'Borrador';
                statusColor = Colors.grey;
                bgColor = const Color(0xFFF1F5F9);
                break;
              case OrderStatus.closed:
                statusText = 'Cerrado';
                statusColor = Colors.grey;
                bgColor = const Color(0xFFF1F5F9);
                break;
              case OrderStatus.sentToKitchen:
                statusText = 'Pendiente';
                statusColor = AppColors.statusPending;
                bgColor = const Color(0xFFF1F5F9); // slate background
                break;
              case OrderStatus.prepping:
                statusText = 'En Cocina';
                statusColor = AppColors.statusCooking;
                bgColor = const Color(0xFFFFF7ED); // orange background
                break;
              case OrderStatus.ready:
                statusText = 'Listo';
                statusColor = AppColors.statusReady;
                bgColor = const Color(0xFFF0FDF4); // green background
                break;
              case OrderStatus.billed:
                statusText = 'Servido';
                statusColor = AppColors.tertiaryContainer;
                bgColor = const Color(0xFFF8FAFC); // default slate
                break;
            }

            final items = order.items.map((item) {
              final menuItem = menuItems.firstWhere((m) => m.id == item.menuItemId, orElse: () => MenuItem(id: '', name: 'Artículo ${item.menuItemId}', priceCents: item.priceCents, category: '', available: true, modifiers: []));
              return {
                'name': '${item.quantity}x ${menuItem.name}',
                'price': '${(item.priceCents * item.quantity / 100).toStringAsFixed(2)}€'
              };
            }).toList();

            return _buildOrderCard(
              table: 'Mesa ${order.tableId}',
              orderId: '#ORD-${order.id.substring(0, 4).toUpperCase()}',
              status: statusText,
              statusColor: statusColor,
              bgColor: bgColor,
              items: items,
              actions: [
                if (order.status == OrderStatus.sentToKitchen)
                  _buildActionBtn('Editar', Icons.edit, false, onTap: () => context.go('/orders/${order.id}/edit')),
                if (order.status == OrderStatus.sentToKitchen)
                  _buildActionBtn(
                    'Cancelar', Icons.close, false,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancelar pedido'),
                          content: const Text('\u00bfEstás seguro? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('No'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Sí, cancelar', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await ref.read(orderServiceProvider).updateStatus(
                            orderId: order.id,
                            status: OrderStatus.closed,
                            byUserId: ref.read(currentUserProvider).value?.id ?? 'user',
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al cancelar: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                if (order.status == OrderStatus.ready)
                  _buildActionBtn('Servir', Icons.check, true, onTap: () => ref.read(orderServiceProvider).updateStatus(orderId: order.id, status: OrderStatus.billed, byUserId: ref.read(currentUserProvider).value?.id ?? 'user')),
                if (order.status == OrderStatus.billed)
                  _buildActionBtn('Cobrar', Icons.payment, true, onTap: () => context.go('/orders/pay/${order.id}')),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildOrderCard({
    required String table,
    required String orderId,
    required String status,
    required Color statusColor,
    required Color bgColor,
    Color textColor = const Color(0xFF475569),
    IconData? icon,
    String? warning,
    required List<Map<String, String>> items,
    double? progress,
    String? timeText,
    required List<Widget> actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border(
          left: const BorderSide(color: Color(0xFFF8FAFC)),
          top: const BorderSide(color: Color(0xFFF8FAFC)),
          right: const BorderSide(color: Color(0xFFF8FAFC)),
          bottom: const BorderSide(color: Color(0xFFF8FAFC)),
        ),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.table_restaurant,
                              color: statusColor, size: 20),
                          const SizedBox(width: AppSpacing.base),
                          Flexible(
                            child: Text(table,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.h3(
                                    color: const Color(0xFF0F172A))),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(orderId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.statusBadge(
                              color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: textColor),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        status,
                        style: AppTypography.statusBadge(color: textColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF8FAFC)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (warning != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: Color(0xFFB45309)),
                          const SizedBox(width: AppSpacing.base),
                          Text(warning,
                              style: AppTypography.statusBadge(
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.base),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['name']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMd(
                                    color: const Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(item['price']!,
                                style: AppTypography.bodyMd(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A))),
                          ],
                        ),
                      )),
                  if (progress != null) ...[
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: statusColor,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(timeText ?? '',
                          style: AppTypography.statusBadge(
                              color: const Color(0xFF94A3B8))),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.md)),
            ),
            child: Row(
              children: actions
                  .map((a) => Expanded(
                      child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: a)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
      String text, IconData? icon, bool isPrimary, {VoidCallback? onTap}) {
    return ElevatedButton(
      onPressed: onTap ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? AppColors.primaryContainer
            : Colors.white,
        foregroundColor:
            isPrimary ? Colors.white : const Color(0xFF475569),
        elevation: isPrimary ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: AppSpacing.base)],
            Text(text,
                style: AppTypography.statusBadge(
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

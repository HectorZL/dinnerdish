import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTimeRange _range;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 29)),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Future<void> _selectRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Selecciona el periodo del reporte',
    );
    if (selected != null) setState(() => _range = selected);
  }

  List<Order> _filterOrders(List<Order> orders) => orders.where((order) {
    final created = order.createdAt;
    return !created.isBefore(_range.start) &&
        created.isBefore(_range.end.add(const Duration(days: 1)));
  }).toList();

  _ReportMetrics _metrics(List<Order> orders, List<MenuItem> menuItems) {
    final salesOrders = orders
        .where(
          (order) =>
              order.status == OrderStatus.billed ||
              order.status == OrderStatus.closed,
        )
        .toList();
    final quantities = <String, int>{};
    final revenue = <String, int>{};
    var totalCents = 0;
    for (final order in salesOrders) {
      totalCents += order.totalCents;
      for (final item in order.items) {
        quantities[item.menuItemId] =
            (quantities[item.menuItemId] ?? 0) + item.quantity;
        revenue[item.menuItemId] =
            (revenue[item.menuItemId] ?? 0) + item.priceCents * item.quantity;
      }
    }
    final names = {for (final item in menuItems) item.id: item.name};
    final sellers = quantities.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return _ReportMetrics(
      totalCents: totalCents,
      orderCount: salesOrders.length,
      itemQuantities: quantities,
      itemRevenue: revenue,
      itemNames: names,
      topSellers: sellers.take(5).toList(),
    );
  }

  Future<void> _exportPdf(List<Order> orders, List<MenuItem> menuItems) async {
    setState(() => _isExporting = true);
    try {
      final metrics = _metrics(orders, menuItems);
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              'Reporte de Sabor y Hogar',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Periodo: ${_formatDate(_range.start)} – ${_formatDate(_range.end)}',
            ),
            pw.SizedBox(height: 18),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ventas: ${_formatMoney(metrics.totalCents)}'),
                pw.Text('Pedidos: ${metrics.orderCount}'),
                pw.Text(
                  'Ticket medio: ${_formatMoney(metrics.averageTicketCents)}',
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Text(
              'Platos más vendidos',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Plato', 'Unidades', 'Ingresos'],
              data: metrics.topSellers
                  .map(
                    (entry) => [
                      metrics.itemNames[entry.key] ?? 'Artículo eliminado',
                      entry.value.toString(),
                      _formatMoney(metrics.itemRevenue[entry.key] ?? 0),
                    ],
                  )
                  .toList(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.orange200,
              ),
            ),
          ],
        ),
      );
      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename:
            'reporte_${_range.start.toIso8601String().substring(0, 10)}_${_range.end.toIso8601String().substring(0, 10)}.pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar el reporte: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _formatMoney(int cents) => '${(cents / 100).toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) {
    final orders = _filterOrders(
      ref.watch(allOrdersProvider).value ?? const [],
    );
    final menuItems = ref.watch(menuItemsProvider).value ?? const [];
    final metrics = _metrics(orders, menuItems);
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop) const StitchAdminSidebar(activeTab: 'Reportes'),
          Expanded(
            child: Column(
              children: [
                StitchTopAppBar(
                  navLinks: isDesktop
                      ? const [
                          NavLink('Inicio', false, route: '/menu'),
                          NavLink('Usuarios', false, route: '/admin/users'),
                          NavLink('Menú', false, route: '/admin/menu'),
                          NavLink('Reportes', true, route: '/admin/reports'),
                        ]
                      : null,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.containerPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(orders, menuItems),
                            const SizedBox(height: AppSpacing.xl),
                            _buildMetrics(metrics),
                            const SizedBox(height: AppSpacing.lg),
                            _buildTopSellers(metrics),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : StitchBottomNavBar(
              currentRoute: '/admin/reports',
              currentUser: currentUser,
            ),
    );
  }

  Widget _buildHeader(List<Order> orders, List<MenuItem> menuItems) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Panel de Reportes', style: AppTypography.h2()),
              Text(
                'Rendimiento del negocio en el periodo seleccionado.',
                style: AppTypography.bodyMd(color: AppColors.secondary),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _selectRange,
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            '${_formatDate(_range.start)} – ${_formatDate(_range.end)}',
          ),
        ),
        StitchPrimaryButton(
          width: 180,
          label: 'Exportar PDF',
          icon: Icons.picture_as_pdf,
          isLoading: _isExporting,
          onPressed: _isExporting ? null : () => _exportPdf(orders, menuItems),
        ),
      ],
    );
  }

  Widget _buildMetrics(_ReportMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _metricCard(
            'Ventas totales',
            _formatMoney(metrics.totalCents),
            Icons.payments,
          ),
          _metricCard(
            'Pedidos cobrados',
            metrics.orderCount.toString(),
            Icons.receipt_long,
          ),
          _metricCard(
            'Ticket medio',
            _formatMoney(metrics.averageTicketCents),
            Icons.analytics,
          ),
        ];
        if (constraints.maxWidth < 650) return Column(children: cards);
        return Row(
          children: cards.map((card) => Expanded(child: card)).toList(),
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon) => Container(
    margin: const EdgeInsets.all(4),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: [AppShadows.card],
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primaryContainer),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.bodyMd()),
            Text(value, style: AppTypography.h3()),
          ],
        ),
      ],
    ),
  );

  Widget _buildTopSellers(_ReportMetrics metrics) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: [AppShadows.card],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Platos más vendidos', style: AppTypography.h3()),
        const SizedBox(height: AppSpacing.md),
        if (metrics.topSellers.isEmpty)
          const Text('No hay ventas en este periodo.')
        else
          ...metrics.topSellers.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(entry.value.toString())),
              title: Text(metrics.itemNames[entry.key] ?? 'Artículo eliminado'),
              subtitle: Text('${entry.value} unidades'),
              trailing: Text(_formatMoney(metrics.itemRevenue[entry.key] ?? 0)),
            ),
          ),
      ],
    ),
  );
}

class _ReportMetrics {
  final int totalCents;
  final int orderCount;
  final Map<String, int> itemQuantities;
  final Map<String, int> itemRevenue;
  final Map<String, String> itemNames;
  final List<MapEntry<String, int>> topSellers;

  const _ReportMetrics({
    required this.totalCents,
    required this.orderCount,
    required this.itemQuantities,
    required this.itemRevenue,
    required this.itemNames,
    required this.topSellers,
  });

  int get averageTicketCents => orderCount == 0 ? 0 : totalCents ~/ orderCount;
}

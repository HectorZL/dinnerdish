import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IngredientAssignmentScreen extends StatefulWidget {
  const IngredientAssignmentScreen({super.key});

  @override
  State<IngredientAssignmentScreen> createState() =>
      _IngredientAssignmentScreenState();
}

class _IngredientAssignmentScreenState
    extends State<IngredientAssignmentScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildHeader(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryStats(),
                  const SizedBox(height: AppSpacing.md),
                  _buildIngredientsSection(),
                  const SizedBox(height: AppSpacing.md),
                  _buildAdditionalCosts(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFFEC5B13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Color(0xFF221610)),
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Escandallo de Plato',
                      style: AppTypography.bodyLg(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF221610))),
                  Text('Configuración de receta e inventario',
                      style: AppTypography.bodyMd(
                          color: const Color(0xFF6B7280))),
                ],
              ),
            ),
            StitchPrimaryButton(
              label: 'Guardar Cambios',
              width: 160,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            const Color(0xFF221610).withValues(alpha: 0.8),
          ],
        ),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black26,
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: const Color(0xFFEC5B13),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text('CATEGORÍA: PIZZAS ARTESANALES',
                style: AppTypography.statusBadge(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: AppSpacing.base),
          Text('Pizza Margherita Especial',
              style: AppTypography.h1(
                  color: Colors.white, fontSize: 28)),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              const Icon(Icons.payments,
                  size: 16, color: Colors.white70),
              const SizedBox(width: AppSpacing.xs),
              Text('Costo Sugerido: \$12.50',
                  style: AppTypography.bodyMd(
                      color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.inventory_2,
                  size: 16, color: Colors.white70),
              const SizedBox(width: AppSpacing.xs),
              Text('Stock Posible: 42 raciones',
                  style: AppTypography.bodyMd(
                      color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COSTO TOTAL RECETA',
                    style: AppTypography.labelCaps(
                        color: const Color(0xFF6B7280))),
                Text('\$4.82',
                    style: AppTypography.h1(
                        color: const Color(0xFF221610))),
                Row(
                  children: [
                    const Icon(Icons.trending_down,
                        size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: AppSpacing.xs),
                    Text('-5% vs mes anterior',
                        style: AppTypography.bodyMd(
                            color: const Color(0xFF16A34A),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MARGEN BRUTO',
                    style: AppTypography.labelCaps(
                        color: const Color(0xFF6B7280))),
                Text('61.4%',
                    style: AppTypography.h1(
                        color: const Color(0xFF221610))),
                const SizedBox(height: AppSpacing.base),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.61,
                    backgroundColor: const Color(0xFFF3F4F6),
                    color: const Color(0xFFEC5B13),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ingredientes & Cantidades',
                style: AppTypography.h3(
                    color: const Color(0xFF221610))),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle, size: 18),
              label: Text('Añadir Ingrediente',
                  style: AppTypography.bodyMd(
                      color: const Color(0xFFEC5B13),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildIngredientItem(
          icon: Icons.bakery_dining,
          name: 'Harina de Trigo 00',
          sku: 'SKU: INV-HAR-001 | \$1.20 / kg',
          quantity: '250',
          unit: 'gr',
          cost: '\$0.30',
          warning: 'Stock bajo en almacén (12kg restantes)',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildIngredientItem(
          icon: Icons.egg,
          name: 'Queso Mozzarella Fresh',
          sku: 'SKU: INV-LAC-042 | \$8.50 / kg',
          quantity: '150',
          unit: 'gr',
          cost: '\$1.27',
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildIngredientItem(
          icon: Icons.local_dining,
          name: 'Salsa de Tomate San Marzano',
          sku: 'SKU: INV-CON-015 | \$4.20 / L',
          quantity: '100',
          unit: 'ml',
          cost: '\$0.42',
        ),
      ],
    );
  }

  Widget _buildIngredientItem({
    required IconData icon,
    required String name,
    required String sku,
    required String quantity,
    required String unit,
    required String cost,
    String? warning,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4)
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Icon(icon,
                              color: const Color(0xFFEC5B13),
                              size: 24),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: AppTypography.bodyLg(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF221610))),
                            Text(sku,
                                style: AppTypography.bodyMd(
                                    color: const Color(0xFF6B7280))),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Color(0xFF9CA3AF)),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(color: Color(0xFFF9FAFB)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('CANTIDAD ($unit)',
                              style: AppTypography.labelCaps(
                                  color: const Color(0xFF9CA3AF))),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              InkWell(
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F6F6),
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.lg),
                                  ),
                                  child: const Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: Color(0xFF6B7280)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(quantity,
                                  style: AppTypography.h3(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          const Color(0xFF221610))),
                              const SizedBox(width: AppSpacing.sm),
                              InkWell(
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F6F6),
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.lg),
                                  ),
                                  child: const Icon(Icons.add,
                                      size: 16,
                                      color: Color(0xFF6B7280)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('COSTO PORCIÓN',
                              style: AppTypography.labelCaps(
                                  color: const Color(0xFF9CA3AF))),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.lg),
                            ),
                            child: Text(cost,
                                style: AppTypography.bodyLg(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color(0xFF221610))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (warning != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                border: Border(
                    top: BorderSide(color: Color(0xFFFFEDD5))),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: Color(0xFFC2410C)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(warning,
                          style: AppTypography.bodyMd(
                              color: const Color(0xFFC2410C),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('Reabastecer',
                        style: AppTypography.statusBadge(
                            color: const Color(0xFFEC5B13))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalCosts() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Costos Operativos Adicionales',
              style: AppTypography.bodyLg(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF221610))),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mano de Obra (est.)',
                  style: AppTypography.bodyMd(
                      color: const Color(0xFF6B7280))),
              Text('\$2.10',
                  style: AppTypography.bodyLg(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF221610))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Packaging / Caja Pizza',
                  style: AppTypography.bodyMd(
                      color: const Color(0xFF6B7280))),
              Text('\$0.75',
                  style: AppTypography.bodyLg(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF221610))),
            ],
          ),
          const Divider(color: Color(0xFFF3F4F6)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Costo Final Ajustado',
                  style: AppTypography.bodyLg(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF221610))),
              Text('\$7.67',
                  style: AppTypography.h2(
                      color: const Color(0xFFEC5B13))),
            ],
          ),
        ],
      ),
    );
  }
}

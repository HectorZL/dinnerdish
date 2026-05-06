import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Favoritos', 'Entradas', 'Fuertes', 'Bebidas', 'Postres'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Adapted for Web/Desktop
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchAndCategories(),
                Expanded(
                  child: _buildDishList(),
                ),
                _buildOrderSummary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa 05 - Nuevo Pedido',
                    style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111827)),
                  ),
                  Text(
                    'Mesero: Juan Pérez',
                    style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEC5B13).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'EN PROCESO',
                style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFEC5B13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndCategories() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar plato o código...',
              hintStyle: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEC5B13)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isActive = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedCategoryIndex = index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? const Color(0xFFEC5B13) : const Color(0xFFF3F4F6),
                      foregroundColor: isActive ? Colors.white : const Color(0xFF4B5563),
                      elevation: isActive ? 2 : 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      _categories[index],
                      style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'PLATOS SUGERIDOS',
            style: GoogleFonts.publicSans(
                fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280), letterSpacing: 1),
          ),
        ),
        _buildDishCard(
          title: 'Bowl Mediterráneo',
          price: '\$12.50',
          desc: 'Mix de verdes, quinua, pollo grillé y aderezo cítrico.',
          image:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuD6HREAVrazqkVWn8MzPcvxfOvKPtn9XX8XJu7ZAPVBNTjbwqOmrXB-mbgoflgJmxQ12g-o6C3usYmtoErwrLWPht_kWZVplNvec47S-XwzzdBtFujtveNhw485PSPMoK6szCNIaHuEADB89fAjscNhyOmdD9wsxVGvzDMlbcFHtiYhmsCb3sk2AuQmuHQ2EUd0DHXDMCQWP212VJVDhtBaMxdygk1UoHXqf_f4pXZynF2myzIXZelDbjM92xF6BoIUY4Nnxp8X-7pS',
          quantity: 1,
          hasVariants: true,
        ),
        const SizedBox(height: 12),
        _buildDishCard(
          title: 'Pizza Artesanal',
          price: '\$15.00',
          desc: 'Masa madre, 33cm, ingredientes a elección.',
          image:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAo_FaUQx_OGj63dMFaKdmKxgqGb2remZy_-pDU4G6k2jlqDwDFfPutnLqT2JROEmeEpEc3ioUEarqYGabrJwgW9FCpGnnIFdJpcruLVWLxAp49U3jhHUYSuCsaLHFTL5qag7qyCFM8CF74FlcJrfNMynZkeQLOaxCczs_8mlstwI9rSV8W5YkP_dyKUt4OmOF98t8WQrDmKJpo0x6hffqkVPBKccpv_TrbpWNRK4GqA4qatDbQGxN1K3BNfPckOq8wsr6PE7VULFzV',
          quantity: 0,
          showVariantsInline: true,
        ),
        const SizedBox(height: 12),
        _buildDishCard(
          title: 'Limonada Hierbabuena',
          price: '\$4.50',
          desc: 'Natural, 400ml, con hielo frappé.',
          image:
              'https://lh3.googleusercontent.com/aida-public/AB6AXuD_QOpGd3Ly_TCzNZuk1Qpu-mA4Umd7MvFiU31jRaUoTrH35K0D-cWUj_-UqDrUsU-xl5xHtHmNPxVsqLY_MzlA4BESHE8J2MX-QzCIWrzyFzppaVFslfhE1YxJfPh9RbO2WwiWfX9plCxFElRKCtkBIM766SLFIhgPzGZoloxrA_UAGjYRwP-l2ZwkI37AmRFN1XejFC1Xkd-NoMlTWQNki5qP1NGV3hqNeNkPmIB7u24JCsrSBnWoLhDCHqaOmpXTBZhnkyE47C41',
          quantity: 2,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDishCard({
    required String title,
    required String price,
    required String desc,
    required String image,
    required int quantity,
    bool hasVariants = false,
    bool showVariantsInline = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: showVariantsInline ? const Color(0xFFEC5B13).withValues(alpha: 0.3) : const Color(0xFFF3F4F6)),
        boxShadow: showVariantsInline
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(image, width: 96, height: 96, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(title,
                                style: GoogleFonts.publicSans(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                          ),
                          Text(price,
                              style: GoogleFonts.publicSans(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFEC5B13))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(desc,
                          style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF6B7280)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildCounterBtn(Icons.remove, quantity > 0, false),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.publicSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: quantity > 0 ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                              _buildCounterBtn(Icons.add, true, quantity > 0),
                            ],
                          ),
                          if (hasVariants)
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Variantes',
                                style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEC5B13),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showVariantsInline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TÉRMINO DE MASA',
                    style: GoogleFonts.publicSans(
                        fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF), letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildVariantBtn('Delgada', true),
                      _buildVariantBtn('Gruesa', false),
                      _buildVariantBtn('Rellena (+\$2)', false),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, bool enabled, bool isPrimary) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary ? const Color(0xFFEC5B13) : Colors.white,
        border: Border.all(color: isPrimary ? const Color(0xFFEC5B13) : const Color(0xFFE5E7EB)),
        boxShadow: isPrimary
            ? [BoxShadow(color: const Color(0xFFEC5B13).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () {} : null,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            size: 18,
            color: isPrimary ? Colors.white : (enabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantBtn(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEC5B13).withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? const Color(0xFFEC5B13) : const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: GoogleFonts.publicSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFFEC5B13) : const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESUMEN DEL PEDIDO',
                        style: GoogleFonts.publicSans(
                            fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF9CA3AF), letterSpacing: 1)),
                    Text('3 Ítems seleccionados',
                        style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                  ],
                ),
                Text('\$21.50',
                    style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.description_outlined, size: 20),
                    label: const Text('Nota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.restaurant, size: 20),
                    label: const Text('Enviar a Cocina'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC5B13),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      shadowColor: const Color(0xFFEC5B13).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

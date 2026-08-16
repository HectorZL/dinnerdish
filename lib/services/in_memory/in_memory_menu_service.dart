import 'package:dinnerhome/exceptions/menu_exception.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/menu_item_variation.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:dinnerhome/services/menu_service.dart';

class InMemoryMenuService implements MenuService {
  final List<MenuItem> _menu = [
    MenuItem(
      id: 'item-1',
      name: 'Pasta Carbonara',
      priceCents: 1200,
      modifiers: [
        Modifier(id: 'mod-1', name: 'Sin queso', priceCents: 0),
        Modifier(id: 'mod-2', name: 'Extra queso', priceCents: 200),
        Modifier(id: 'mod-3', name: 'Sin cebolla', priceCents: 0),
      ],
      available: true,
      category: 'Platos Principales',
      stock: 0,
      additionalIds: const ['additional-rice', 'additional-avocado'],
      variations: [
        MenuItemVariation(
          id: 'var-1-1',
          name: 'Normal',
          priceCents: 1200,
          stock: 15,
        ),
        MenuItemVariation(
          id: 'var-1-2',
          name: 'Familiar',
          priceCents: 2200,
          stock: 5,
        ),
      ],
    ),
    MenuItem(
      id: 'item-2',
      name: 'Ensalada César',
      priceCents: 850,
      modifiers: [
        Modifier(id: 'mod-4', name: 'Sin crutones', priceCents: 0),
        Modifier(id: 'mod-5', name: 'Extra pollo', priceCents: 350),
      ],
      available: true,
      category: 'Entrantes',
      stock: 20,
      variations: [],
    ),
    MenuItem(
      id: 'item-3',
      name: 'Lomo Saltado',
      priceCents: 1800,
      modifiers: [
        Modifier(id: 'mod-6', name: 'Sin ají', priceCents: 0),
        Modifier(id: 'mod-7', name: 'Arroz extra', priceCents: 300),
      ],
      available: true,
      category: 'Platos Principales',
      stock: 12,
      variations: [],
    ),
    MenuItem(
      id: 'item-4',
      name: 'Ceviche Mixto',
      priceCents: 2200,
      modifiers: [],
      available: true,
      category: 'Entrantes',
      stock: 8,
      variations: [],
    ),
    MenuItem(
      id: 'item-5',
      name: 'Sopa del Día',
      priceCents: 600,
      modifiers: [],
      available: true,
      category: 'Entrantes',
      stock: 10,
      variations: [],
    ),
  ];

  @override
  Future<List<MenuItem>> fetchMenu() async => _menu;

  @override
  Future<MenuItem?> getMenuItem(String id) async {
    try {
      return _menu.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MenuItem> createMenuItem(MenuItem item) async {
    _menu.add(item);
    return item;
  }

  @override
  Future<MenuItem> updateMenuItem(String id, MenuItem item) async {
    final index = _menu.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw MenuItemNotFoundException(id);
    }
    _menu[index] = item;
    return item;
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    final index = _menu.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw MenuItemNotFoundException(id);
    }
    _menu.removeAt(index);
  }

  @override
  Future<List<String>> getCategories() async {
    final categories = _menu.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }

  @override
  Future<void> adjustStock(
    String itemId,
    String? variationId,
    int quantityChange,
  ) async {
    final index = _menu.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw MenuItemNotFoundException(itemId);
    }

    final item = _menu[index];
    if (variationId != null) {
      final variationIndex = item.variations.indexWhere(
        (variation) => variation.id == variationId,
      );
      if (variationIndex == -1) {
        throw MenuItemVariationNotFoundException(itemId, variationId);
      }

      final variations = List<MenuItemVariation>.from(item.variations);
      final variation = variations[variationIndex];
      final newStock = variation.stock + quantityChange;
      if (newStock < 0) {
        throw StockAdjustmentNegativeException();
      }
      variations[variationIndex] = variation.copyWith(stock: newStock);
      _menu[index] = item.copyWith(variations: variations);
      return;
    }

    final newStock = item.stock + quantityChange;
    if (newStock < 0) {
      throw StockAdjustmentNegativeException();
    }
    _menu[index] = item.copyWith(stock: newStock);
  }
}

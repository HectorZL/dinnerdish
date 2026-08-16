import 'package:hive/hive.dart';
import 'package:dinnerhome/exceptions/menu_exception.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/menu_item_variation.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:dinnerhome/services/menu_service.dart';

/// Persistent MenuService backed by the versioned menu Hive box.
///
/// The service stores complete MenuItem aggregates under their stable ids. The
/// MenuItem and MenuItemVariation adapters remain responsible for their
/// existing field indexes; this service does not re-encode or merge stocks.
class HiveMenuService implements MenuService {
  static const boxName = 'menu_items_v1';

  final Box<MenuItem>? _providedBox;

  /// The box is normally opened by [initHive] before the provider is read.
  /// Keeping the lookup lazy also makes the provider safe to construct in
  /// tests before Hive initialization, while every real operation still
  /// requires the persistent box.
  HiveMenuService({Box<MenuItem>? box}) : _providedBox = box;

  Box<MenuItem> get _box {
    final box = _providedBox;
    if (box != null) return box;
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('La caja persistente del menú no está inicializada.');
    }
    return Hive.box<MenuItem>(boxName);
  }

  @override
  Future<List<MenuItem>> fetchMenu() async =>
      List<MenuItem>.unmodifiable(_box.values);

  @override
  Future<MenuItem?> getMenuItem(String id) async => _box.get(id);

  @override
  Future<MenuItem> createMenuItem(MenuItem item) async {
    if (_box.containsKey(item.id)) {
      throw MenuException(
        'Ya existe un plato con ese identificador.',
        code: 'MENU_ITEM_ALREADY_EXISTS',
      );
    }
    await _box.put(item.id, item);
    return item;
  }

  @override
  Future<MenuItem> updateMenuItem(String id, MenuItem item) async {
    if (!_box.containsKey(id)) {
      throw MenuItemNotFoundException(id);
    }
    final updated = item.id == id ? item : item.copyWith(id: id);
    await _box.put(id, updated);
    return updated;
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    if (!_box.containsKey(id)) {
      throw MenuItemNotFoundException(id);
    }
    await _box.delete(id);
  }

  @override
  Future<List<String>> getCategories() async {
    final categories = _box.values.map((item) => item.category).toSet().toList();
    categories.sort();
    return categories;
  }

  @override
  Future<void> adjustStock(
    String itemId,
    String? variationId,
    int quantityChange,
  ) async {
    final item = _box.get(itemId);
    if (item == null) {
      throw MenuItemNotFoundException(itemId);
    }

    final MenuItem updated;
    if (variationId == null) {
      updated = item.copyWith(
        stock: _checkedStock(item.stock, quantityChange),
      );
    } else {
      final variationIndex = item.variations.indexWhere(
        (variation) => variation.id == variationId,
      );
      if (variationIndex == -1) {
        throw MenuItemVariationNotFoundException(itemId, variationId);
      }
      final variations = List<MenuItemVariation>.from(item.variations);
      final variation = variations[variationIndex];
      variations[variationIndex] = variation.copyWith(
        stock: _checkedStock(variation.stock, quantityChange),
      );
      updated = item.copyWith(variations: variations);
    }

    // A single aggregate write keeps the base stock and variation stocks
    // independent and prevents a partial variation update in the box.
    await _box.put(item.id, updated);
  }

  int _checkedStock(int currentStock, int quantityChange) {
    final newStock = currentStock + quantityChange;
    if (newStock < 0) {
      throw StockAdjustmentNegativeException();
    }
    return newStock;
  }

  /// Seed data used only when an installation has no menu yet. Existing
  /// persisted values are never replaced, so stock is preserved literally.
  static List<MenuItem> defaultMenu() => [
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
}

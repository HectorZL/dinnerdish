import 'package:dinnerhome/models/menu_item.dart';

abstract class MenuService {
  Future<List<MenuItem>> fetchMenu();
  Future<MenuItem?> getMenuItem(String id);
  Future<MenuItem> createMenuItem(MenuItem item);
  Future<MenuItem> updateMenuItem(String id, MenuItem item);
  Future<void> deleteMenuItem(String id);
  Future<List<String>> getCategories();

  /// Adjusts the stock of the base dish when [variationId] is null, or of
  /// the identified variation otherwise.
  ///
  /// Implementations must reject missing dishes/variations and any result
  /// below zero. They must not silently clamp an invalid adjustment.
  Future<void> adjustStock(
    String itemId,
    String? variationId,
    int quantityChange,
  );
}

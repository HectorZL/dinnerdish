import 'package:dinnerhome/models/menu_item.dart';

abstract class MenuService {
  Future<List<MenuItem>> fetchMenu();
  Future<MenuItem?> getMenuItem(String id);
  Future<MenuItem> createMenuItem(MenuItem item);
  Future<MenuItem> updateMenuItem(String id, MenuItem item);
  Future<void> deleteMenuItem(String id);
  Future<List<String>> getCategories();
  Future<void> adjustStock(String itemId, String? variationId, int quantityChange);
}

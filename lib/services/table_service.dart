import 'package:dinnerhome/models/table.dart';

abstract class TableService {
  Future<List<Table>> getTables();
  Future<Table> getTable(String id);
  Future<Table> createTable(Table table);
  Future<Table> updateTable(String id, Table table);
  Future<Table> updateTableStatus(String id, TableStatus status);
  Stream<List<Table>> watchTables();
}

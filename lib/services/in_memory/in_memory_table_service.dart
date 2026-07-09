import 'dart:async';
import 'package:dinnerhome/models/table.dart';
import 'package:dinnerhome/services/table_service.dart';

class InMemoryTableService implements TableService {
  final Map<String, Table> _tables = {};
  final _tableEventsController = StreamController<List<Table>>.broadcast();

  InMemoryTableService() {
    _initializeTables();
  }

  void _initializeTables() {
    _tables['01'] = const Table(id: '01', number: 1, seats: 4, status: TableStatus.available);
    _tables['02'] = const Table(id: '02', number: 2, seats: 4, status: TableStatus.available);
    _tables['03'] = const Table(id: '03', number: 3, seats: 4, status: TableStatus.available);
    _tables['04'] = const Table(id: '04', number: 4, seats: 4, status: TableStatus.available);
  }

  @override
  Future<List<Table>> getTables() async {
    return _tables.values.toList()..sort((a, b) => a.number.compareTo(b.number));
  }

  @override
  Future<Table> getTable(String id) async {
    final table = _tables[id];
    if (table == null) {
      throw Exception('Table not found');
    }
    return table;
  }

  @override
  Future<Table> updateTableStatus(String id, TableStatus status) async {
    final table = _tables[id];
    if (table == null) {
      throw Exception('Table not found');
    }
    final updatedTable = Table(
      id: table.id,
      number: table.number,
      seats: table.seats,
      status: status,
      section: table.section,
    );
    _tables[id] = updatedTable;
    _emitEvent();
    return updatedTable;
  }

  @override
  Stream<List<Table>> watchTables() {
    // Emit initial value on listen
    Future.microtask(() => _emitEvent());
    return _tableEventsController.stream;
  }

  void _emitEvent() {
    _tableEventsController.add(_tables.values.toList()..sort((a, b) => a.number.compareTo(b.number)));
  }
}

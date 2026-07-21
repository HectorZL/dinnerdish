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
    for (var number = 1; number <= 4; number++) {
      final id = number.toString().padLeft(2, '0');
      _tables[id] = Table(
        id: id,
        number: number,
        seats: 4,
        status: TableStatus.available,
      );
    }
  }

  @override
  Future<List<Table>> getTables() async => _sortedTables();

  @override
  Future<Table> getTable(String id) async {
    final table = _tables[id];
    if (table == null) throw StateError('Mesa no encontrada.');
    return table;
  }

  @override
  Future<Table> createTable(Table table) async {
    _validate(table);
    if (_tables.containsKey(table.id)) {
      throw StateError('Ya existe una mesa con ese identificador.');
    }
    if (_tables.values.any((item) => item.number == table.number)) {
      throw StateError('Ya existe la mesa número ${table.number}.');
    }
    _tables[table.id] = table;
    _emitEvent();
    return table;
  }

  @override
  Future<Table> updateTable(String id, Table table) async {
    if (!_tables.containsKey(id)) throw StateError('Mesa no encontrada.');
    final updated = Table(
      id: id,
      number: table.number,
      seats: table.seats,
      status: table.status,
      section: table.section,
    );
    _validate(updated);
    if (_tables.values.any(
      (item) => item.id != id && item.number == updated.number,
    )) {
      throw StateError('Ya existe la mesa número ${updated.number}.');
    }
    _tables[id] = updated;
    _emitEvent();
    return updated;
  }

  @override
  Future<Table> updateTableStatus(String id, TableStatus status) async {
    final table = await getTable(id);
    return updateTable(
      id,
      Table(
        id: id,
        number: table.number,
        seats: table.seats,
        status: status,
        section: table.section,
      ),
    );
  }

  @override
  Stream<List<Table>> watchTables() {
    Future.microtask(_emitEvent);
    return _tableEventsController.stream;
  }

  List<Table> _sortedTables() {
    return _tables.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  void _validate(Table table) {
    if (table.number <= 0) {
      throw ArgumentError.value(table.number, 'number', 'Debe ser positivo.');
    }
    if (table.seats <= 0) {
      throw ArgumentError.value(table.seats, 'seats', 'Debe ser positivo.');
    }
  }

  void _emitEvent() {
    _tableEventsController.add(_sortedTables());
  }
}

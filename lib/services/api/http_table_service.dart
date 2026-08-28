import 'dart:async';
import 'package:dinnerhome/models/table.dart';
import 'package:dinnerhome/services/table_service.dart';
import 'package:dinnerhome/services/socket_service.dart';
import 'api_client.dart';

class HttpTableService implements TableService {
  final ApiClient _client;
  final SocketService? _socketService;
  final _tablesStreamController = StreamController<List<Table>>.broadcast();
  StreamSubscription? _socketSubscription;

  HttpTableService({
    ApiClient? client,
    SocketService? socketService,
  })  : _client = client ?? ApiClient(),
        _socketService = socketService {
    _socketSubscription = _socketService?.orderEvents.listen((_) {
      // Refresh tables on relevant socket events
      getTables();
    });
  }

  @override
  Future<List<Table>> getTables() async {
    final res = await _client.get('/api/tables');
    final list = (res as List)
        .map((e) => Table.fromJson(e as Map<String, dynamic>))
        .toList();
    _tablesStreamController.add(list);
    return list;
  }

  @override
  Future<Table> getTable(String id) async {
    final res = await _client.get('/api/tables/$id');
    return Table.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<Table> createTable(Table table) async {
    final res = await _client.post('/api/tables', body: table.toJson());
    final created = Table.fromJson(res as Map<String, dynamic>);
    getTables();
    return created;
  }

  @override
  Future<Table> updateTable(String id, Table table) async {
    final res = await _client.put('/api/tables/$id', body: table.toJson());
    final updated = Table.fromJson(res as Map<String, dynamic>);
    getTables();
    return updated;
  }

  @override
  Future<Table> updateTableStatus(String id, TableStatus status) async {
    final res = await _client.put('/api/tables/$id/status', body: {
      'status': status.name,
    });
    final updated = Table.fromJson(res as Map<String, dynamic>);
    getTables();
    return updated;
  }

  @override
  Stream<List<Table>> watchTables() => _tablesStreamController.stream;

  void dispose() {
    _socketSubscription?.cancel();
    _tablesStreamController.close();
  }
}

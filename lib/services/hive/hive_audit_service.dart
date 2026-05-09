import 'package:hive/hive.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/services/audit_service.dart';

class HiveAuditService implements AuditService {
  final Box<AuditEntry> _box;

  HiveAuditService(this._box);

  @override
  Future<void> record({
    required String action,
    required String userId,
    required Map<String, dynamic> metadata,
    DateTime? timestamp,
  }) async {
    final entry = AuditEntry(
      id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      userId: userId,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    );
    await _box.add(entry);
  }

  @override
  Future<List<AuditEntry>> list({int limit = 100, int offset = 0}) async {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.skip(offset).take(limit).toList();
  }
}

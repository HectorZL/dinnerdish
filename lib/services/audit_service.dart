import 'package:dinnerhome/models/audit_entry.dart';

abstract class AuditService {
  Future<void> record({
    required String action,
    required String userId,
    required Map<String, dynamic> metadata,
    DateTime? timestamp,
  });
  Future<List<AuditEntry>> list({int limit = 100, int offset = 0});
}

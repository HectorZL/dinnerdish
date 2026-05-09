import 'package:hive/hive.dart';

part 'audit_entry.g.dart';

@HiveType(typeId: 12)
class AuditEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String action;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final Map<String, dynamic>? metadata;

  const AuditEntry({
    required this.id,
    required this.action,
    required this.userId,
    required this.timestamp,
    this.metadata,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final action = json['action'] as String?;
    if (action == null) {
      throw ArgumentError('Missing required field: action');
    }
    final userId = json['userId'] as String?;
    if (userId == null) {
      throw ArgumentError('Missing required field: userId');
    }
    final timestampRaw = json['timestamp'] as String?;
    if (timestampRaw == null) {
      throw ArgumentError('Missing required field: timestamp');
    }
    final metadata = json['metadata'] as Map<String, dynamic>?;

    return AuditEntry(
      id: id,
      action: action,
      userId: userId,
      timestamp: DateTime.parse(timestampRaw),
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

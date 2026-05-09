// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditEntryAdapter extends TypeAdapter<AuditEntry> {
  @override
  final int typeId = 12;

  @override
  AuditEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditEntry(
      id: fields[0] as String,
      action: fields[1] as String,
      userId: fields[2] as String,
      timestamp: fields[3] as DateTime,
      metadata: (fields[4] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AuditEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

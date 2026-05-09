// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TableAdapter extends TypeAdapter<Table> {
  @override
  final int typeId = 8;

  @override
  Table read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Table(
      id: fields[0] as String,
      number: fields[1] as int,
      seats: fields[2] as int,
      status: fields[3] as TableStatus,
      section: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Table obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.seats)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.section);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TableStatusAdapter extends TypeAdapter<TableStatus> {
  @override
  final int typeId = 7;

  @override
  TableStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TableStatus.available;
      case 1:
        return TableStatus.occupied;
      case 2:
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }

  @override
  void write(BinaryWriter writer, TableStatus obj) {
    switch (obj) {
      case TableStatus.available:
        writer.writeByte(0);
        break;
      case TableStatus.occupied:
        writer.writeByte(1);
        break;
      case TableStatus.reserved:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

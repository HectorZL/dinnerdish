// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_drawer_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashDrawerSessionAdapter extends TypeAdapter<CashDrawerSession> {
  @override
  final int typeId = 17;

  @override
  CashDrawerSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashDrawerSession(
      id: fields[0] as String,
      cashierId: fields[1] as String,
      openedAt: fields[2] as DateTime,
      closedAt: fields[3] as DateTime?,
      startingBalanceCents: fields[4] as int,
      expectedBalanceCents: fields[5] as int,
      actualBalanceCents: fields[6] as int,
      differenceCents: fields[7] as int,
      status: fields[8] as CashDrawerStatus,
    );
  }

  @override
  void write(BinaryWriter writer, CashDrawerSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cashierId)
      ..writeByte(2)
      ..write(obj.openedAt)
      ..writeByte(3)
      ..write(obj.closedAt)
      ..writeByte(4)
      ..write(obj.startingBalanceCents)
      ..writeByte(5)
      ..write(obj.expectedBalanceCents)
      ..writeByte(6)
      ..write(obj.actualBalanceCents)
      ..writeByte(7)
      ..write(obj.differenceCents)
      ..writeByte(8)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashDrawerSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CashDrawerStatusAdapter extends TypeAdapter<CashDrawerStatus> {
  @override
  final int typeId = 16;

  @override
  CashDrawerStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CashDrawerStatus.open;
      case 1:
        return CashDrawerStatus.closed;
      case 2:
        return CashDrawerStatus.reconciled;
      default:
        return CashDrawerStatus.open;
    }
  }

  @override
  void write(BinaryWriter writer, CashDrawerStatus obj) {
    switch (obj) {
      case CashDrawerStatus.open:
        writer.writeByte(0);
        break;
      case CashDrawerStatus.closed:
        writer.writeByte(1);
        break;
      case CashDrawerStatus.reconciled:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashDrawerStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

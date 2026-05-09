// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentTransactionAdapter extends TypeAdapter<PaymentTransaction> {
  @override
  final int typeId = 15;

  @override
  PaymentTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentTransaction(
      id: fields[0] as String,
      orderId: fields[1] as String,
      processedBy: fields[2] as String,
      amountCents: fields[3] as int,
      method: fields[4] as PaymentMethod,
      status: fields[5] as PaymentStatus,
      createdAt: fields[6] as DateTime,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentTransaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderId)
      ..writeByte(2)
      ..write(obj.processedBy)
      ..writeByte(3)
      ..write(obj.amountCents)
      ..writeByte(4)
      ..write(obj.method)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentRequestAdapter extends TypeAdapter<PaymentRequest> {
  @override
  final int typeId = 11;

  @override
  PaymentRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentRequest(
      id: fields[0] as String,
      orderId: fields[1] as String,
      requestedBy: fields[2] as String,
      amountCents: fields[3] as int,
      requestedAt: fields[4] as DateTime,
      reason: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentRequest obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.orderId)
      ..writeByte(2)
      ..write(obj.requestedBy)
      ..writeByte(3)
      ..write(obj.amountCents)
      ..writeByte(4)
      ..write(obj.requestedAt)
      ..writeByte(5)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

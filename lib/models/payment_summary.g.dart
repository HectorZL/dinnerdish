// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentSummaryAdapter extends TypeAdapter<PaymentSummary> {
  @override
  final int typeId = 18;

  @override
  PaymentSummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentSummary(
      method: fields[0] as PaymentMethod,
      count: fields[1] as int,
      totalCents: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentSummary obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.method)
      ..writeByte(1)
      ..write(obj.count)
      ..writeByte(2)
      ..write(obj.totalCents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentSummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

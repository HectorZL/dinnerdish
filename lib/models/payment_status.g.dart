// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final int typeId = 14;

  @override
  PaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentStatus.requested;
      case 1:
        return PaymentStatus.processing;
      case 2:
        return PaymentStatus.completed;
      case 3:
        return PaymentStatus.failed;
      case 4:
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.requested;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    switch (obj) {
      case PaymentStatus.requested:
        writer.writeByte(0);
        break;
      case PaymentStatus.processing:
        writer.writeByte(1);
        break;
      case PaymentStatus.completed:
        writer.writeByte(2);
        break;
      case PaymentStatus.failed:
        writer.writeByte(3);
        break;
      case PaymentStatus.refunded:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

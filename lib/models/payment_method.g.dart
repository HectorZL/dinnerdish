// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentMethodAdapter extends TypeAdapter<PaymentMethod> {
  @override
  final int typeId = 13;

  @override
  PaymentMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentMethod.cash;
      case 1:
        return PaymentMethod.creditCard;
      case 2:
        return PaymentMethod.debitCard;
      case 3:
        return PaymentMethod.transfer;
      case 4:
        return PaymentMethod.split;
      case 5:
        return PaymentMethod.qr;
      default:
        return PaymentMethod.cash;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentMethod obj) {
    switch (obj) {
      case PaymentMethod.cash:
        writer.writeByte(0);
        break;
      case PaymentMethod.creditCard:
        writer.writeByte(1);
        break;
      case PaymentMethod.debitCard:
        writer.writeByte(2);
        break;
      case PaymentMethod.transfer:
        writer.writeByte(3);
        break;
      case PaymentMethod.split:
        writer.writeByte(4);
        break;
      case PaymentMethod.qr:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

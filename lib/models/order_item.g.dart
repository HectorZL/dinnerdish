// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderItemAdapter extends TypeAdapter<OrderItem> {
  @override
  final int typeId = 4;

  @override
  OrderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderItem(
      id: fields[0] as String,
      menuItemId: fields[1] as String,
      quantity: fields[2] as int,
      notes: fields[3] as String?,
      status: fields[4] as OrderStatus,
      modifierIds: (fields[5] as List).cast<String>(),
      priceCents: fields[6] as int,
      name: fields[7] as String?,
      variationId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.menuItemId)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.modifierIds)
      ..writeByte(6)
      ..write(obj.priceCents)
      ..writeByte(7)
      ..write(obj.name)
      ..writeByte(8)
      ..write(obj.variationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = 3;

  @override
  OrderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.sent;
      case 2:
        return OrderStatus.preparing;
      case 3:
        return OrderStatus.ready;
      case 4:
        return OrderStatus.served;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    switch (obj) {
      case OrderStatus.pending:
        writer.writeByte(0);
        break;
      case OrderStatus.sent:
        writer.writeByte(1);
        break;
      case OrderStatus.preparing:
        writer.writeByte(2);
        break;
      case OrderStatus.ready:
        writer.writeByte(3);
        break;
      case OrderStatus.served:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

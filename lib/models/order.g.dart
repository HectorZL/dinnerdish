// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 6;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as String,
      tableId: fields[1] as String,
      waiterId: fields[2] as String,
      items: (fields[3] as List).cast<OrderItem>(),
      status: fields[4] as OrderStatus,
      subtotalCents: fields[5] as int,
      taxCents: fields[6] as int,
      totalCents: fields[7] as int,
      createdAt: fields[8] as DateTime,
      sentToKitchenAt: fields[9] as DateTime?,
      readyAt: fields[10] as DateTime?,
      notes: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tableId)
      ..writeByte(2)
      ..write(obj.waiterId)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.subtotalCents)
      ..writeByte(6)
      ..write(obj.taxCents)
      ..writeByte(7)
      ..write(obj.totalCents)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.sentToKitchenAt)
      ..writeByte(10)
      ..write(obj.readyAt)
      ..writeByte(11)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = 5;

  @override
  OrderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OrderStatus.draft;
      case 1:
        return OrderStatus.sentToKitchen;
      case 2:
        return OrderStatus.prepping;
      case 3:
        return OrderStatus.ready;
      case 4:
        return OrderStatus.billed;
      case 5:
        return OrderStatus.closed;
      default:
        return OrderStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    switch (obj) {
      case OrderStatus.draft:
        writer.writeByte(0);
        break;
      case OrderStatus.sentToKitchen:
        writer.writeByte(1);
        break;
      case OrderStatus.prepping:
        writer.writeByte(2);
        break;
      case OrderStatus.ready:
        writer.writeByte(3);
        break;
      case OrderStatus.billed:
        writer.writeByte(4);
        break;
      case OrderStatus.closed:
        writer.writeByte(5);
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

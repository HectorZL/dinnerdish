// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 1;

  @override
  MenuItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItem(
      id: fields[0] as String,
      name: fields[1] as String,
      priceCents: fields[2] as int,
      modifiers: (fields[3] as List).cast<Modifier>(),
      available: fields[4] as bool,
      category: fields[5] as String,
      stock: fields[6] as int,
      variations: (fields[7] as List).cast<MenuItemVariation>(),
      additionalIds: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.priceCents)
      ..writeByte(3)
      ..write(obj.modifiers)
      ..writeByte(4)
      ..write(obj.available)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.stock)
      ..writeByte(7)
      ..write(obj.variations)
      ..writeByte(8)
      ..write(obj.additionalIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

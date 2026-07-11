// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item_variation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MenuItemVariationAdapter extends TypeAdapter<MenuItemVariation> {
  @override
  final int typeId = 19;

  @override
  MenuItemVariation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItemVariation(
      id: fields[0] as String,
      name: fields[1] as String,
      priceCents: fields[2] as int,
      stock: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MenuItemVariation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.priceCents)
      ..writeByte(3)
      ..write(obj.stock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItemVariationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

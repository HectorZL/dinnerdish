// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifier.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModifierAdapter extends TypeAdapter<Modifier> {
  @override
  final int typeId = 2;

  @override
  Modifier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Modifier(
      id: fields[0] as String,
      name: fields[1] as String,
      priceCents: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Modifier obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.priceCents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModifierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

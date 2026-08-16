// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_additional.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SelectedAdditionalAdapter extends TypeAdapter<SelectedAdditional> {
  @override
  final int typeId = 20;

  @override
  SelectedAdditional read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SelectedAdditional(
      assignmentId: fields[0] as String,
      additionalId: fields[1] as String,
      source: fields[2] as AdditionalSource,
      nameSnapshot: fields[3] as String,
      priceCentsSnapshot: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SelectedAdditional obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.assignmentId)
      ..writeByte(1)
      ..write(obj.additionalId)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.nameSnapshot)
      ..writeByte(4)
      ..write(obj.priceCentsSnapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedAdditionalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

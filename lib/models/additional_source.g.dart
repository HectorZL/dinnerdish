// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'additional_source.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdditionalSourceAdapter extends TypeAdapter<AdditionalSource> {
  @override
  final int typeId = 21;

  @override
  AdditionalSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AdditionalSource.global;
      case 1:
        return AdditionalSource.special;
      default:
        return AdditionalSource.global;
    }
  }

  @override
  void write(BinaryWriter writer, AdditionalSource obj) {
    switch (obj) {
      case AdditionalSource.global:
        writer.writeByte(0);
        break;
      case AdditionalSource.special:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdditionalSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

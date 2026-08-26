// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 10;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final rolesList = fields[9] != null
        ? (fields[9] as List).cast<Role>()
        : (fields[3] != null ? [fields[3] as Role] : const [Role.mesero]);
    return User(
      id: fields[0] as String,
      username: fields[1] as String,
      name: fields[2] as String,
      roles: rolesList,
      token: fields[4] as String?,
      email: fields[5] as String?,
      lastLogin: fields[6] as String?,
      isActive: fields[7] as bool,
      password: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.token)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.lastLogin)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.password)
      ..writeByte(9)
      ..write(obj.roles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 9;

  @override
  Role read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Role.mesero;
      case 1:
        return Role.cajero;
      case 2:
        return Role.cocinero;
      case 3:
        return Role.admin;
      default:
        return Role.mesero;
    }
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    switch (obj) {
      case Role.mesero:
        writer.writeByte(0);
        break;
      case Role.cajero:
        writer.writeByte(1);
        break;
      case Role.cocinero:
        writer.writeByte(2);
        break;
      case Role.admin:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

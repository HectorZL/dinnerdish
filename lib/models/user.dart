import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 9)
enum Role {
  @HiveField(0)
  mesero,
  @HiveField(1)
  cajero,
  @HiveField(2)
  cocinero,
  @HiveField(3)
  admin,
}

@HiveType(typeId: 10)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final Role role;

  @HiveField(4)
  final String? token;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null) {
      throw ArgumentError('Missing required field: id');
    }
    final username = json['username'] as String?;
    if (username == null) {
      throw ArgumentError('Missing required field: username');
    }
    final name = json['name'] as String?;
    if (name == null) {
      throw ArgumentError('Missing required field: name');
    }
    final roleRaw = json['role'] as String?;
    if (roleRaw == null) {
      throw ArgumentError('Missing required field: role');
    }
    final token = json['token'] as String?;

    return User(
      id: id,
      username: username,
      name: name,
      role: Role.values.byName(roleRaw),
      token: token,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'role': role.name,
        'token': token,
      };
}

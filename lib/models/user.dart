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

  @HiveField(5)
  final String? email;

  @HiveField(6)
  final String? lastLogin;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final String? password;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.token,
    this.email,
    this.lastLogin,
    this.isActive = true,
    this.password,
  });

  User copyWith({
    String? id,
    String? username,
    String? name,
    Role? role,
    String? token,
    String? email,
    String? lastLogin,
    bool? isActive,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      token: token ?? this.token,
      email: email ?? this.email,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      password: password ?? this.password,
    );
  }

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
    final email = json['email'] as String?;
    final lastLogin = json['lastLogin'] as String?;
    final isActive = json['isActive'] as bool? ?? true;
    final password = json['password'] as String?;

    return User(
      id: id,
      username: username,
      name: name,
      role: Role.values.byName(roleRaw),
      token: token,
      email: email,
      lastLogin: lastLogin,
      isActive: isActive,
      password: password,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'role': role.name,
        'token': token,
        'email': email,
        'lastLogin': lastLogin,
        'isActive': isActive,
        'password': password,
      };
}

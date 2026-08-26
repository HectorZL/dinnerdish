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

  @HiveField(9)
  final List<Role> roles;

  Role get role => roles.isNotEmpty ? roles.first : Role.mesero;

  const User({
    required this.id,
    required this.username,
    required this.name,
    this.roles = const [Role.mesero],
    this.token,
    this.email,
    this.lastLogin,
    this.isActive = true,
    this.password,
  });

  bool hasRole(Role targetRole) => roles.contains(targetRole);

  User copyWith({
    String? id,
    String? username,
    String? name,
    Role? role,
    List<Role>? roles,
    String? token,
    String? email,
    String? lastLogin,
    bool? isActive,
    String? password,
  }) {
    final updatedRoles = roles ??
        (role != null ? [role] : this.roles);
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      roles: updatedRoles,
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
    
    List<Role> parsedRoles = [];
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List)
          .map((r) {
            try {
              return Role.values.byName(r.toString());
            } catch (_) {
              return null;
            }
          })
          .whereType<Role>()
          .toList();
    }
    
    if (parsedRoles.isEmpty) {
      final roleRaw = json['role'] as String?;
      if (roleRaw != null) {
        try {
          parsedRoles = [Role.values.byName(roleRaw)];
        } catch (_) {
          parsedRoles = [Role.mesero];
        }
      } else {
        parsedRoles = [Role.mesero];
      }
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
      roles: parsedRoles,
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
        'roles': roles.map((r) => r.name).toList(),
        'token': token,
        'email': email,
        'lastLogin': lastLogin,
        'isActive': isActive,
        'password': password,
      };
}

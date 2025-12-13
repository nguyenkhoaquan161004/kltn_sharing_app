class AdminModel {
  final int adminId;
  final String name;
  final String email;
  final String passwordHash;
  final String permissionLevel; // 'super_admin', 'admin', 'moderator'
  final DateTime createdAt;

  AdminModel({
    required this.adminId,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.permissionLevel,
    required this.createdAt,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      adminId: json['admin_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['password_hash'] ?? '',
      permissionLevel: json['permission_level'] ?? 'admin',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'permission_level': permissionLevel,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AdminModel copyWith({
    int? adminId,
    String? name,
    String? email,
    String? passwordHash,
    String? permissionLevel,
    DateTime? createdAt,
  }) {
    return AdminModel(
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

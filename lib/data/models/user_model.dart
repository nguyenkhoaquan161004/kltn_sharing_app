class UserModel {
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final String role; // 'user', 'seller', 'premium'
  final int trustScore;
  final DateTime createdAt;
  final String? avatar;
  final String? address;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.role,
    required this.trustScore,
    required this.createdAt,
    this.avatar,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      passwordHash: json['password_hash'] ?? '',
      role: json['role'] ?? 'user',
      trustScore: json['trust_score'] ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      avatar: json['avatar'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'role': role,
      'trust_score': trustScore,
      'created_at': createdAt.toIso8601String(),
      if (avatar != null) 'avatar': avatar,
      if (address != null) 'address': address,
    };
  }

  UserModel copyWith({
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? passwordHash,
    String? role,
    int? trustScore,
    DateTime? createdAt,
    String? avatar,
    String? address,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      trustScore: trustScore ?? this.trustScore,
      createdAt: createdAt ?? this.createdAt,
      avatar: avatar ?? this.avatar,
      address: address ?? this.address,
    );
  }
}

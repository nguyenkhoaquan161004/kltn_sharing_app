class GamificationModel {
  final int gamificationId;
  final int userId;
  final int points;
  final int level;
  final DateTime updatedAt;

  GamificationModel({
    required this.gamificationId,
    required this.userId,
    required this.points,
    required this.level,
    required this.updatedAt,
  });

  factory GamificationModel.fromJson(Map<String, dynamic> json) {
    return GamificationModel(
      gamificationId: json['gamification_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gamification_id': gamificationId,
      'user_id': userId,
      'points': points,
      'level': level,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GamificationModel copyWith({
    int? gamificationId,
    int? userId,
    int? points,
    int? level,
    DateTime? updatedAt,
  }) {
    return GamificationModel(
      gamificationId: gamificationId ?? this.gamificationId,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      level: level ?? this.level,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

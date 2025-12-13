class UserBadgeModel {
  final int userBadgeId;
  final int userId;
  final int badgeId;
  final DateTime earnedAt;

  UserBadgeModel({
    required this.userBadgeId,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
  });

  factory UserBadgeModel.fromJson(Map<String, dynamic> json) {
    return UserBadgeModel(
      userBadgeId: json['user_badge_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      badgeId: json['badge_id'] ?? 0,
      earnedAt:
          DateTime.parse(json['earned_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_badge_id': userBadgeId,
      'user_id': userId,
      'badge_id': badgeId,
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  UserBadgeModel copyWith({
    int? userBadgeId,
    int? userId,
    int? badgeId,
    DateTime? earnedAt,
  }) {
    return UserBadgeModel(
      userBadgeId: userBadgeId ?? this.userBadgeId,
      userId: userId ?? this.userId,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }
}

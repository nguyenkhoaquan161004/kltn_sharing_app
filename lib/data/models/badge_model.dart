class BadgeModel {
  final int badgeId;
  final String name;
  final String description;
  final String icon;

  BadgeModel({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId: json['badge_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge_id': badgeId,
      'name': name,
      'description': description,
      'icon': icon,
    };
  }

  BadgeModel copyWith({
    int? badgeId,
    String? name,
    String? description,
    String? icon,
  }) {
    return BadgeModel(
      badgeId: badgeId ?? this.badgeId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }
}

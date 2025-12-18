class NotificationModel {
  final int notificationId;
  final int userId;
  final String title;
  final String message;
  final String
      type; // 'selection', 'receipt', 'achievement', 'message', 'system'
  final String? relatedItemName;
  final String? relatedUserName;
  final DateTime createdAt;
  final bool isRead;
  final String? iconPath;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedItemName,
    this.relatedUserName,
    required this.createdAt,
    this.isRead = false,
    this.iconPath,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      relatedItemName: json['related_item_name'],
      relatedUserName: json['related_user_name'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      iconPath: json['icon_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_item_name': relatedItemName,
      'related_user_name': relatedUserName,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'icon_path': iconPath,
    };
  }

  NotificationModel copyWith({
    int? notificationId,
    int? userId,
    String? title,
    String? message,
    String? type,
    String? relatedItemName,
    String? relatedUserName,
    DateTime? createdAt,
    bool? isRead,
    String? iconPath,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedItemName: relatedItemName ?? this.relatedItemName,
      relatedUserName: relatedUserName ?? this.relatedUserName,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}

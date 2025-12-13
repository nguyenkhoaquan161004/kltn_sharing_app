class NotificationModel {
  final int notificationId;
  final int userId;
  final int? itemId;
  final String
      type; // 'item_shared', 'interest_received', 'transaction_completed', etc.
  final String message;
  final bool readStatus;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    this.itemId,
    required this.type,
    required this.message,
    required this.readStatus,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      itemId: json['item_id'],
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      readStatus: json['read_status'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      'type': type,
      'message': message,
      'read_status': readStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? notificationId,
    int? userId,
    int? itemId,
    String? type,
    String? message,
    bool? readStatus,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      message: message ?? this.message,
      readStatus: readStatus ?? this.readStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

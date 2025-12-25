import 'package:intl/intl.dart';

/// Notification type enum matching backend
enum NotificationType {
  itemShared,
  itemInterest,
  transactionCreated,
  transactionAccepted,
  transactionRejected,
  transactionCompleted,
  transactionCancelled,
  messageReceived,
  badgeEarned,
  pointsEarned,
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.itemShared:
        return 'ITEM_SHARED';
      case NotificationType.itemInterest:
        return 'ITEM_INTEREST';
      case NotificationType.transactionCreated:
        return 'TRANSACTION_CREATED';
      case NotificationType.transactionAccepted:
        return 'TRANSACTION_ACCEPTED';
      case NotificationType.transactionRejected:
        return 'TRANSACTION_REJECTED';
      case NotificationType.transactionCompleted:
        return 'TRANSACTION_COMPLETED';
      case NotificationType.transactionCancelled:
        return 'TRANSACTION_CANCELLED';
      case NotificationType.messageReceived:
        return 'MESSAGE_RECEIVED';
      case NotificationType.badgeEarned:
        return 'BADGE_EARNED';
      case NotificationType.pointsEarned:
        return 'POINTS_EARNED';
      case NotificationType.system:
        return 'SYSTEM';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'ITEM_SHARED':
        return NotificationType.itemShared;
      case 'ITEM_INTEREST':
        return NotificationType.itemInterest;
      case 'TRANSACTION_CREATED':
        return NotificationType.transactionCreated;
      case 'TRANSACTION_ACCEPTED':
        return NotificationType.transactionAccepted;
      case 'TRANSACTION_REJECTED':
        return NotificationType.transactionRejected;
      case 'TRANSACTION_COMPLETED':
        return NotificationType.transactionCompleted;
      case 'TRANSACTION_CANCELLED':
        return NotificationType.transactionCancelled;
      case 'MESSAGE_RECEIVED':
        return NotificationType.messageReceived;
      case 'BADGE_EARNED':
        return NotificationType.badgeEarned;
      case 'POINTS_EARNED':
        return NotificationType.pointsEarned;
      case 'SYSTEM':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}

/// Notification model matching backend API
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? referenceId;
  final String? referenceType;
  final bool readStatus;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.referenceType,
    required this.readStatus,
    required this.createdAt,
  });

  /// Create from JSON (API response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: NotificationTypeExtension.fromString(json['type'] ?? 'SYSTEM'),
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      readStatus: json['readStatus'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  /// Get notification icon based on type
  String get icon {
    switch (type) {
      case NotificationType.itemShared:
        return '📦';
      case NotificationType.itemInterest:
        return '❤️';
      case NotificationType.transactionCreated:
        return '📝';
      case NotificationType.transactionAccepted:
        return '✅';
      case NotificationType.transactionRejected:
        return '❌';
      case NotificationType.transactionCompleted:
        return '🎉';
      case NotificationType.transactionCancelled:
        return '⛔';
      case NotificationType.messageReceived:
        return '💬';
      case NotificationType.badgeEarned:
        return '🏆';
      case NotificationType.pointsEarned:
        return '⭐';
      case NotificationType.system:
        return 'ℹ️';
    }
  }

  /// Format time relative to now
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? referenceId,
    String? referenceType,
    bool? readStatus,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      readStatus: readStatus ?? this.readStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  Color _getTypeColor() {
    switch (notification.type) {
      case 'selection':
        return AppColors.success;
      case 'receipt':
        return AppColors.info;
      case 'achievement':
        return const Color(0xFFFFB800); // Gold color
      case 'message':
        return AppColors.primaryTeal;
      case 'system':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getTypeIcon() {
    switch (notification.type) {
      case 'selection':
        return '🎉';
      case 'receipt':
        return '📦';
      case 'achievement':
        return '⭐';
      case 'message':
        return '💬';
      case 'system':
        return '🔔';
      default:
        return '📢';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.notificationId.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primaryTeal.withOpacity(0.05),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.borderLight
                  : AppColors.primaryTeal.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with type color
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getTypeIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with unread indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Time
                    Text(
                      _formatTime(notification.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

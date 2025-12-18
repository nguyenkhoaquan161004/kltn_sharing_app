import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/mock_data.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/bottom_navigation_widget.dart';
import 'widgets/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationModel> _notifications;
  String _filterType =
      'all'; // all, selection, receipt, achievement, message, system

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    _notifications = MockData.getNotificationsByUserId(1);
    // Sort by newest first
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<NotificationModel> get _filteredNotifications {
    if (_filterType == 'all') {
      return _notifications;
    }
    return _notifications.where((n) => n.type == _filterType).toList();
  }

  void _markAsRead(int notificationId) {
    final index =
        _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      setState(() {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  void _deleteNotification(int notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.notificationId == notificationId);
    });
  }

  int _getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppHeaderBar(
          orderCount: 0,
          onSearchTap: () {},
          onMessagesTap: () {},
        ),
      ),
      body: Column(
        children: [
          // Header with title and mark all as read
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thông báo',
                      style: AppTextStyles.h2,
                    ),
                    if (_getUnreadCount() > 0)
                      GestureDetector(
                        onTap: _markAllAsRead,
                        child: Text(
                          'Đánh dấu đã đọc',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Unread count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Có ${_getUnreadCount()} thông báo chưa đọc',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chọn nhận', 'selection'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Nhận hàng', 'receipt'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Thành tích', 'achievement'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tin nhắn', 'message'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification list
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có thông báo',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return NotificationCard(
                        notification: notification,
                        onTap: () => _markAsRead(notification.notificationId),
                        onDismiss: () =>
                            _deleteNotification(notification.notificationId),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 2),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal
              : AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.primaryTeal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

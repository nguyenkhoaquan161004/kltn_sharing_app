import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/item_provider.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../profile/widgets/create_product_modal.dart';
import 'widgets/notification_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filterType =
      'all'; // all, ITEM_SHARED, ITEM_INTEREST, TRANSACTION_CREATED, etc.
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
      // Also refresh unread count periodically
      _refreshUnreadCount();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final notificationProvider = context.read<NotificationProvider>();

    final scrollPercentage = _scrollController.position.pixels /
        _scrollController.position.maxScrollExtent;
    print(
        '[NotificationsScreen] Scroll: ${scrollPercentage.toStringAsFixed(2)}% (${_scrollController.position.pixels} / ${_scrollController.position.maxScrollExtent})');

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // User scrolled near bottom, load more
      print(
          '[NotificationsScreen] Near bottom! isLoadingMore=${notificationProvider.isLoadingMore}, currentPage=${notificationProvider.currentPage}, totalPages=${notificationProvider.totalPages}');
      if (!notificationProvider.isLoadingMore &&
          notificationProvider.currentPage < notificationProvider.totalPages) {
        print('[NotificationsScreen] Loading more notifications...');
        notificationProvider.loadMoreNotifications();
      }
    }
  }

  void _loadNotifications() {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    // Set auth token
    if (authProvider.accessToken != null) {
      notificationProvider.setAuthToken(authProvider.accessToken);
    }

    // Fetch notifications
    print('[NotificationsScreen] Loading notifications...');
    notificationProvider.fetchNotifications();
  }

  void _refreshUnreadCount() {
    final notificationProvider = context.read<NotificationProvider>();
    notificationProvider.refreshUnreadCount();
  }

  Future<void> _handleRefresh() async {
    _loadNotifications();
    // Wait a bit for the fetch to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  List<NotificationModel> _getFilteredNotifications(
      List<NotificationModel> notifications) {
    if (_filterType == 'all') {
      return notifications;
    }
    return notifications.where((n) => n.type.value == _filterType).toList();
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await context.read<NotificationProvider>().markAsRead(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu là đã đọc'),
          duration: Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await context.read<NotificationProvider>().markAllAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả là đã đọc'),
          duration: Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateProductModal(
        onProductCreated: (success) {
          if (success) {
            final itemProvider = context.read<ItemProvider>();
            itemProvider.loadItems();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tạo sản phẩm thành công!')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderBar(),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, _) {
          final filteredNotifications =
              _getFilteredNotifications(notificationProvider.notifications);

          return Column(
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
                        if (notificationProvider.unreadCount > 0)
                          Tooltip(
                            message: 'Đánh dấu tất cả đã đọc',
                            child: GestureDetector(
                              onTap: _markAllAsRead,
                              child: Icon(
                                Icons.done_all,
                                size: 24,
                                color: AppColors.primaryTeal,
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
                        'Có ${notificationProvider.unreadCount} thông báo chưa đọc',
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
                      _buildFilterChip('Mục chia sẻ', 'ITEM_SHARED'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Quan tâm', 'ITEM_INTEREST'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Giao dịch', 'TRANSACTION_CREATED'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Huy hiệu', 'BADGE_EARNED'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              if (notificationProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      notificationProvider.errorMessage!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.red.shade700),
                    ),
                  ),
                ),

              // Notification list
              Expanded(
                child: notificationProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : filteredNotifications.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _handleRefresh,
                            child: Center(
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 100),
                                        const Icon(
                                          Icons.notifications_none,
                                          size: 64,
                                          color: AppColors.textHint,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Không có thông báo',
                                          style:
                                              AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _handleRefresh,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: filteredNotifications.length +
                                  (notificationProvider.isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Show loading indicator at the end
                                if (index == filteredNotifications.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final notification =
                                    filteredNotifications[index];
                                return NotificationCard(
                                  notification: notification,
                                  onTap: () => _markAsRead(notification.id),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: 2,
        onAddPressed: _showAddItemModal,
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
        // Reset pagination and reload when filter changes
        final notificationProvider = context.read<NotificationProvider>();
        // Reset to page 1 and reload
        notificationProvider.fetchNotifications(page: 1);
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

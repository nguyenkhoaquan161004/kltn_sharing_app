import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

/// Provider for managing notifications state
class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _notificationService = NotificationApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _pageSize = 20;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Initialize with auth token
  void setAuthToken(String? accessToken) {
    if (accessToken != null) {
      _notificationService.setAuthToken(accessToken);
    }
  }

  /// Fetch notifications paginated (fresh fetch)
  Future<void> fetchNotifications({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _notificationService.getNotifications(
        page: page,
        limit: limit,
      );

      // Handle ApiResponse structure: data contains { "data": [...], "page": 1, "limit": 20, "total": 100 }
      final notificationsList = response['data'] as List? ?? [];
      _notifications = notificationsList
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Extract pagination info
      _currentPage = response['page'] ?? 1;
      _pageSize = response['limit'] ?? 20;
      final total = response['totalElements'] ??
          0; // API uses 'totalElements' not 'total'
      _totalPages = total > 0 ? (total / _pageSize).ceil() : 1;

      // Update unread count from fetched notifications
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      print(
          '[NotificationProvider] Fetched ${_notifications.length} notifications (page $_currentPage/$_totalPages), totalElements=$total');
      print(
          '[NotificationProvider] Response pagination: page=${response['page']}, limit=${response['limit']}, totalElements=${response['totalElements']}');
      print('[NotificationProvider] Unread count: $_unreadCount');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('[NotificationProvider] Error: $_errorMessage');
    }
  }

  /// Load more notifications (append to existing list)
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || _currentPage >= _totalPages) {
      print(
          '[NotificationProvider] Already loading or at last page. isLoadingMore=$_isLoadingMore, currentPage=$_currentPage, totalPages=$_totalPages');
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      print('[NotificationProvider] Loading page $nextPage...');
      final response = await _notificationService.getNotifications(
        page: nextPage,
        limit: _pageSize,
      );

      // Handle ApiResponse structure
      final notificationsList = response['data'] as List? ?? [];
      final newNotifications = notificationsList
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Append to existing list
      _notifications.addAll(newNotifications);

      // Update pagination info
      _currentPage = response['page'] ?? nextPage;
      _pageSize = response['limit'] ?? _pageSize;
      final total = response['totalElements'] ??
          0; // API uses 'totalElements' not 'total'
      _totalPages = total > 0 ? (total / _pageSize).ceil() : 1;

      print(
          '[NotificationProvider] Loaded more ${newNotifications.length} notifications (page $_currentPage/$_totalPages)');
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('[NotificationProvider] Error loading more: $_errorMessage');
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Get unread notifications
  Future<void> fetchUnreadNotifications() async {
    try {
      final unread = await _notificationService.getUnreadNotifications();
      _notifications = unread;
      _unreadCount = unread.length;
      notifyListeners();
      print(
          '[NotificationProvider] Fetched ${unread.length} unread notifications');
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('[NotificationProvider] Error fetching unread: $_errorMessage');
    }
  }

  /// Get unread count
  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      notifyListeners();
      print('[NotificationProvider] Unread count: $_unreadCount');
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      print('[NotificationProvider] Error getting count: $errorMsg');
      // Don't fail silently - log the error details
      _errorMessage = errorMsg;
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        // Update unread count
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        print('[NotificationProvider] Unread count after mark: $_unreadCount');
        notifyListeners();
      }

      // Refresh to get latest data from server
      await fetchNotifications();
      print(
          '[NotificationProvider] ✅ Marked notification as read and refreshed');
    } catch (e) {
      print('[NotificationProvider] ❌ Error marking as read: $e');
      rethrow;
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Update local state
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();

      // Refresh to get latest data from server
      await fetchNotifications();
      print('[NotificationProvider] ✅ Marked all as read and refreshed');
    } catch (e) {
      print('[NotificationProvider] ❌ Error marking all as read: $e');
      rethrow;
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await fetchNotifications();
    await refreshUnreadCount();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

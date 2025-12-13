import '../mock_data.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../models/message_model.dart';
import '../models/gamification_model.dart';
import '../models/transaction_model.dart';
import '../models/location_model.dart';
import '../models/category_model.dart';
import '../models/item_interest_model.dart';
import '../models/notification_model.dart';
import '../models/user_badge_model.dart';
import '../models/badge_model.dart';

/// Service để quản lý mock data trong quá trình phát triển
class MockDataService {
  // Singleton pattern
  static final MockDataService _instance = MockDataService._internal();

  factory MockDataService() {
    return _instance;
  }

  MockDataService._internal();

  // ==================== ADMIN METHODS ====================
  Future<List<AdminModel>> getAllAdmins() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.admins,
    );
  }

  Future<AdminModel?> getAdminById(int adminId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.admins.firstWhere(
        (a) => a.adminId == adminId,
        orElse: () => throw Exception('Admin not found'),
      ),
    );
  }

  // ==================== USER METHODS ====================
  Future<List<UserModel>> getAllUsers() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.users,
    );
  }

  Future<UserModel?> getUserById(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getUserById(userId),
    );
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.users.where((u) => u.role == role).toList(),
    );
  }

  // ==================== ITEM METHODS ====================
  Future<List<ItemModel>> getAllItems() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.items,
    );
  }

  Future<ItemModel?> getItemById(int itemId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getItemById(itemId),
    );
  }

  Future<List<ItemModel>> getItemsByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getItemsByUserId(userId),
    );
  }

  Future<List<ItemModel>> getItemsByCategory(int categoryId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.items.where((i) => i.categoryId == categoryId).toList(),
    );
  }

  Future<List<ItemModel>> getAvailableItems() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.items.where((i) => i.status == 'available').toList(),
    );
  }

  // ==================== CATEGORY METHODS ====================
  Future<List<CategoryModel>> getAllCategories() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.categories,
    );
  }

  Future<CategoryModel?> getCategoryById(int categoryId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getCategoryById(categoryId),
    );
  }

  // ==================== LOCATION METHODS ====================
  Future<List<LocationModel>> getAllLocations() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.locations,
    );
  }

  Future<LocationModel?> getLocationById(int locationId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getLocationById(locationId),
    );
  }

  // ==================== MESSAGE METHODS ====================
  Future<List<MessageModel>> getAllMessages() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.messages,
    );
  }

  Future<List<MessageModel>> getMessagesByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getMessagesByUserId(userId),
    );
  }

  Future<List<MessageModel>> getConversation(int userId1, int userId2) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.messages
          .where(
            (m) =>
                (m.senderId == userId1 && m.receiverId == userId2) ||
                (m.senderId == userId2 && m.receiverId == userId1),
          )
          .toList(),
    );
  }

  // ==================== GAMIFICATION METHODS ====================
  Future<List<GamificationModel>> getAllGamifications() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.gamifications,
    );
  }

  Future<GamificationModel?> getGamificationByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getGamificationByUserId(userId),
    );
  }

  Future<List<GamificationModel>> getTopUsersByPoints(int limit) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () {
        final sorted = List<GamificationModel>.from(MockData.gamifications);
        sorted.sort((a, b) => b.points.compareTo(a.points));
        return sorted.take(limit).toList();
      },
    );
  }

  // ==================== TRANSACTION METHODS ====================
  Future<List<TransactionModel>> getAllTransactions() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.transactions,
    );
  }

  Future<List<TransactionModel>> getTransactionsByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.transactions
          .where((t) => t.sharerId == userId || t.receiverId == userId)
          .toList(),
    );
  }

  Future<List<TransactionModel>> getTransactionsByStatus(String status) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.transactions.where((t) => t.status == status).toList(),
    );
  }

  // ==================== ITEM INTEREST METHODS ====================
  Future<List<ItemInterestModel>> getAllItemInterests() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.itemInterests,
    );
  }

  Future<List<ItemInterestModel>> getItemInterestsByItemId(int itemId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.itemInterests.where((i) => i.itemId == itemId).toList(),
    );
  }

  Future<List<ItemInterestModel>> getItemInterestsByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.itemInterests.where((i) => i.userId == userId).toList(),
    );
  }

  // ==================== NOTIFICATION METHODS ====================
  Future<List<NotificationModel>> getAllNotifications() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.notifications,
    );
  }

  Future<List<NotificationModel>> getNotificationsByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getNotificationsByUserId(userId),
    );
  }

  Future<int> getUnreadNotificationCount(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getUnreadNotificationCount(userId),
    );
  }

  // ==================== BADGE METHODS ====================
  Future<List<BadgeModel>> getAllBadges() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.badges,
    );
  }

  Future<BadgeModel?> getBadgeById(int badgeId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getBadgeById(badgeId),
    );
  }

  Future<List<BadgeModel>> getBadgesByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.getBadgesByUserId(userId),
    );
  }

  // ==================== USER BADGE METHODS ====================
  Future<List<UserBadgeModel>> getAllUserBadges() async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.userBadges,
    );
  }

  Future<List<UserBadgeModel>> getUserBadgesByUserId(int userId) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.userBadges.where((ub) => ub.userId == userId).toList(),
    );
  }

  // ==================== SEARCH & FILTER ====================
  Future<List<ItemModel>> searchItems(String query) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () => MockData.items
          .where((i) =>
              i.name.toLowerCase().contains(query.toLowerCase()) ||
              i.description.toLowerCase().contains(query.toLowerCase()))
          .toList(),
    );
  }

  Future<List<ItemModel>> filterItems({
    int? categoryId,
    int? locationId,
    String? status,
    int? maxPrice,
  }) async {
    return Future.delayed(
      const Duration(milliseconds: 300),
      () {
        var filtered = MockData.items;

        if (categoryId != null) {
          filtered = filtered.where((i) => i.categoryId == categoryId).toList();
        }

        if (locationId != null) {
          filtered = filtered.where((i) => i.locationId == locationId).toList();
        }

        if (status != null) {
          filtered = filtered.where((i) => i.status == status).toList();
        }

        return filtered;
      },
    );
  }
}

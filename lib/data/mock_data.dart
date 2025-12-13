import 'models/admin_model.dart';
import 'models/user_model.dart';
import 'models/item_model.dart';
import 'models/message_model.dart';
import 'models/gamification_model.dart';
import 'models/transaction_model.dart';
import 'models/location_model.dart';
import 'models/category_model.dart';
import 'models/item_interest_model.dart';
import 'models/notification_model.dart';
import 'models/user_badge_model.dart';
import 'models/badge_model.dart';

/// Mock data class chứa tất cả dữ liệu ảo cho phát triển
class MockData {
  // ==================== LOCATIONS ====================
  static final List<LocationModel> locations = [
    LocationModel(
      locationId: 1,
      name: 'TP.HCM - Quận 1',
      latitude: 10.7769,
      longitude: 106.7009,
    ),
    LocationModel(
      locationId: 2,
      name: 'TP.HCM - Quận 3',
      latitude: 10.7873,
      longitude: 106.6804,
    ),
    LocationModel(
      locationId: 3,
      name: 'TP.HCM - Quận 5',
      latitude: 10.7626,
      longitude: 106.6549,
    ),
    LocationModel(
      locationId: 4,
      name: 'TP.HCM - Quận 7',
      latitude: 10.7343,
      longitude: 106.7247,
    ),
    LocationModel(
      locationId: 5,
      name: 'Hà Nội - Hoàn Kiếm',
      latitude: 21.0285,
      longitude: 105.8542,
    ),
    LocationModel(
      locationId: 6,
      name: 'Hà Nội - Cầu Giấy',
      latitude: 21.0452,
      longitude: 105.7857,
    ),
  ];

  // ==================== CATEGORIES ====================
  static final List<CategoryModel> categories = [
    CategoryModel(categoryId: 1, name: 'Quần áo'),
    CategoryModel(categoryId: 2, name: 'Giày dép'),
    CategoryModel(categoryId: 3, name: 'Điện tử'),
    CategoryModel(categoryId: 4, name: 'Sách'),
    CategoryModel(categoryId: 5, name: 'Đồ chơi'),
    CategoryModel(categoryId: 6, name: 'Nội thất'),
    CategoryModel(categoryId: 7, name: 'Thể thao'),
    CategoryModel(categoryId: 8, name: 'Khác'),
  ];

  // ==================== BADGES ====================
  static final List<BadgeModel> badges = [
    BadgeModel(
      badgeId: 1,
      name: 'Người chia sẻ mới',
      description: 'Chia sẻ sản phẩm đầu tiên của bạn',
      icon: '🌟',
    ),
    BadgeModel(
      badgeId: 2,
      name: 'Nhà chia sẻ lạc quan',
      description: 'Nhận được 5 lần đánh giá tích cực liên tiếp',
      icon: '⭐',
    ),
    BadgeModel(
      badgeId: 3,
      name: 'Nhân từ',
      description: 'Chia sẻ tổng cộng 100 sản phẩm',
      icon: '❤️',
    ),
    BadgeModel(
      badgeId: 4,
      name: 'Người nhận hào phóng',
      description: 'Nhận được 50 sản phẩm',
      icon: '🎁',
    ),
    BadgeModel(
      badgeId: 5,
      name: 'Kỵ sĩ mạo hiểm',
      description: 'Hoàn thành 10 giao dịch',
      icon: '⚔️',
    ),
  ];

  // ==================== ADMINS ====================
  static final List<AdminModel> admins = [
    AdminModel(
      adminId: 1,
      name: 'Admin Chính',
      email: 'admin@kltn.com',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      permissionLevel: 'super_admin',
      createdAt: DateTime(2024, 1, 15),
    ),
    AdminModel(
      adminId: 2,
      name: 'Quản lý Nội dung',
      email: 'content@kltn.com',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      permissionLevel: 'admin',
      createdAt: DateTime(2024, 2, 1),
    ),
    AdminModel(
      adminId: 3,
      name: 'Người kiểm duyệt',
      email: 'moderator@kltn.com',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      permissionLevel: 'moderator',
      createdAt: DateTime(2024, 3, 10),
    ),
  ];

  // ==================== USERS ====================
  static final List<UserModel> users = [
    UserModel(
      userId: 1,
      name: 'Nguyễn Khoa Quân',
      email: 'quan@example.com',
      phone: '0912345678',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'premium',
      trustScore: 95,
      createdAt: DateTime(2023, 6, 15),
      avatar: 'https://i.pravatar.cc/150?img=1',
      address: '8A/12A Thái Văn Lung, Q.1, TP.HCM',
    ),
    UserModel(
      userId: 2,
      name: 'Trần Minh Anh',
      email: 'minh.anh@example.com',
      phone: '0987654321',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'seller',
      trustScore: 88,
      createdAt: DateTime(2023, 7, 20),
      avatar: 'https://i.pravatar.cc/150?img=2',
      address: 'Quận 3, TP.HCM',
    ),
    UserModel(
      userId: 3,
      name: 'Phạm Thị Bích',
      email: 'bich@example.com',
      phone: '0901112233',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'user',
      trustScore: 72,
      createdAt: DateTime(2023, 8, 10),
      avatar: 'https://i.pravatar.cc/150?img=3',
      address: 'Quận 5, TP.HCM',
    ),
    UserModel(
      userId: 4,
      name: 'Đinh Văn Cường',
      email: 'cuong@example.com',
      phone: '0944556677',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'seller',
      trustScore: 85,
      createdAt: DateTime(2023, 9, 5),
      avatar: 'https://i.pravatar.cc/150?img=4',
      address: 'Quận 7, TP.HCM',
    ),
    UserModel(
      userId: 5,
      name: 'Lý Thanh Tú',
      email: 'thanh.tu@example.com',
      phone: '0967788990',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'user',
      trustScore: 68,
      createdAt: DateTime(2023, 10, 12),
      avatar: 'https://i.pravatar.cc/150?img=5',
      address: 'Hà Nội',
    ),
    UserModel(
      userId: 6,
      name: 'Võ Hoàng Huy',
      email: 'hoang.huy@example.com',
      phone: '0988990011',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'premium',
      trustScore: 92,
      createdAt: DateTime(2023, 11, 8),
      avatar: 'https://i.pravatar.cc/150?img=6',
      address: 'Quận 1, TP.HCM',
    ),
  ];

  // ==================== ITEMS ====================
  static final List<ItemModel> items = [
    ItemModel(
      itemId: 1,
      userId: 1,
      name: 'Giày Nike Air Max mới',
      description:
          'Giày Nike Air Max 90 chính hãng, tình trạng như mới, chỉ mang 2 lần',
      quantity: 1,
      status: 'available',
      categoryId: 2,
      locationId: 1,
      expirationDate: DateTime.now().add(Duration(days: 30)),
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      price: 0,
    ),
    ItemModel(
      itemId: 2,
      userId: 2,
      name: 'Áo thun cotton',
      description: 'Áo thun cotton chất lượng cao, màu đen, size M, mất size',
      quantity: 3,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expirationDate: DateTime.now().add(Duration(days: 45)),
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      price: 50000,
    ),
    ItemModel(
      itemId: 3,
      userId: 3,
      name: 'Sách "Cách dạy con thông minh"',
      description:
          'Sách hay về giáo dục trẻ em, tình trạng tốt, có chữ ký tác giả',
      quantity: 2,
      status: 'available',
      categoryId: 4,
      locationId: 3,
      expirationDate: DateTime.now().add(Duration(days: 60)),
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      price: 0,
    ),
    ItemModel(
      itemId: 4,
      userId: 4,
      name: 'Ghế gỗ ăn cơm',
      description:
          'Ghế gỗ ăn cơm, bộ 4 cái, màu nâu sẫm, hơi cũ nhưng còn chắc chỉ',
      quantity: 4,
      status: 'available',
      categoryId: 6,
      locationId: 4,
      expirationDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      price: 500000,
    ),
    ItemModel(
      itemId: 5,
      userId: 5,
      name: 'Laptop Asus cũ',
      description:
          'Laptop Asus VivoBook 15, Intel i5, RAM 8GB, SSD 512GB, pin còn tốt',
      quantity: 1,
      status: 'pending',
      categoryId: 3,
      locationId: 5,
      expirationDate: DateTime.now().add(Duration(days: 20)),
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      price: 0,
    ),
    ItemModel(
      itemId: 6,
      userId: 1,
      name: 'Bộ vợt cầu lông',
      description: 'Bộ vợt cầu lông cao cấp, 2 cái, có túi xách, ít dùng',
      quantity: 2,
      status: 'available',
      categoryId: 7,
      locationId: 1,
      expirationDate: DateTime.now().add(Duration(days: 75)),
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      price: 200000,
    ),
    ItemModel(
      itemId: 7,
      userId: 2,
      name: 'Quần jeans nam',
      description:
          'Quần jeans nam hiệu Levi\'s, size 32, màu xanh, tình trạng mới',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expirationDate: DateTime.now().add(Duration(days: 55)),
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      price: 0,
    ),
    ItemModel(
      itemId: 8,
      userId: 6,
      name: 'Đồ chơi Lego',
      description:
          'Bộ Lego City, hơn 500 mảnh, hộp nguyên bản, từ 5 tuổi trở lên',
      quantity: 1,
      status: 'available',
      categoryId: 5,
      locationId: 6,
      expirationDate: DateTime.now().add(Duration(days: 100)),
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      price: 150000,
    ),
  ];

  // ==================== MESSAGES ====================
  static final List<MessageModel> messages = [
    MessageModel(
      messageId: 1,
      senderId: 1,
      receiverId: 2,
      itemId: 1,
      content: 'Bạn còn giày này không? Tôi rất quan tâm.',
      createdAt: DateTime.now().subtract(Duration(hours: 24)),
    ),
    MessageModel(
      messageId: 2,
      senderId: 2,
      receiverId: 1,
      itemId: 1,
      content: 'Còn chứ! Bạn muốn xem trực tiếp không?',
      createdAt: DateTime.now().subtract(Duration(hours: 23)),
    ),
    MessageModel(
      messageId: 3,
      senderId: 3,
      receiverId: 4,
      itemId: 4,
      content: 'Ghế có thể giao ở quận 1 được không?',
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    MessageModel(
      messageId: 4,
      senderId: 4,
      receiverId: 3,
      itemId: 4,
      content: 'Được thôi, mình có thể giao miễn phí.',
      createdAt: DateTime.now().subtract(Duration(hours: 11)),
    ),
    MessageModel(
      messageId: 5,
      senderId: 5,
      receiverId: 1,
      itemId: null,
      content: 'Xin chào, bạn có quen mình ở trường không?',
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    MessageModel(
      messageId: 6,
      senderId: 1,
      receiverId: 5,
      itemId: null,
      content: 'Ừ, cái gì tôi giúp bạn được không?',
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
  ];

  // ==================== GAMIFICATION ====================
  static final List<GamificationModel> gamifications = [
    GamificationModel(
      gamificationId: 1,
      userId: 1,
      points: 3520,
      level: 15,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 2,
      userId: 2,
      points: 2890,
      level: 12,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 3,
      userId: 3,
      points: 1450,
      level: 8,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 4,
      userId: 4,
      points: 2750,
      level: 11,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 5,
      userId: 5,
      points: 890,
      level: 5,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 6,
      userId: 6,
      points: 3200,
      level: 14,
      updatedAt: DateTime.now(),
    ),
  ];

  // ==================== TRANSACTIONS ====================
  static final List<TransactionModel> transactions = [
    TransactionModel(
      transactionId: 1,
      itemId: 1,
      sharerId: 1,
      receiverId: 2,
      status: 'completed',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+1',
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      confirmedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    TransactionModel(
      transactionId: 2,
      itemId: 2,
      sharerId: 2,
      receiverId: 3,
      status: 'pending',
      paymentVerified: false,
      createdAt: DateTime.now().subtract(Duration(hours: 48)),
    ),
    TransactionModel(
      transactionId: 3,
      itemId: 3,
      sharerId: 3,
      receiverId: 4,
      status: 'completed',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+2',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      confirmedAt: DateTime.now().subtract(Duration(days: 4)),
    ),
    TransactionModel(
      transactionId: 4,
      itemId: 5,
      sharerId: 5,
      receiverId: 1,
      status: 'verified',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+3',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      confirmedAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    TransactionModel(
      transactionId: 5,
      itemId: 6,
      sharerId: 1,
      receiverId: 3,
      status: 'completed',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+4',
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      confirmedAt: DateTime.now().subtract(Duration(days: 6)),
    ),
  ];

  // ==================== ITEM INTERESTS ====================
  static final List<ItemInterestModel> itemInterests = [
    ItemInterestModel(
      interestId: 1,
      itemId: 1,
      userId: 2,
      reason: 'Cần giày chạy bộ mới',
      status: 'accepted',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    ItemInterestModel(
      interestId: 2,
      itemId: 1,
      userId: 3,
      reason: 'Thích style của giày này',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    ItemInterestModel(
      interestId: 3,
      itemId: 2,
      userId: 4,
      reason: 'Tìm áo thun màu đen',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(hours: 24)),
    ),
    ItemInterestModel(
      interestId: 4,
      itemId: 3,
      userId: 1,
      reason: 'Cần sách học dạy con',
      status: 'accepted',
      createdAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    ItemInterestModel(
      interestId: 5,
      itemId: 4,
      userId: 5,
      reason: 'Tìm ghế ăn cơm rẻ',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(hours: 36)),
    ),
    ItemInterestModel(
      interestId: 6,
      itemId: 5,
      userId: 2,
      reason: 'Cần laptop để học lập trình',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
  ];

  // ==================== NOTIFICATIONS ====================
  static final List<NotificationModel> notifications = [
    NotificationModel(
      notificationId: 1,
      userId: 1,
      itemId: 1,
      type: 'item_shared',
      message: 'Bạn vừa chia sẻ "Giày Nike Air Max mới"',
      readStatus: true,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    NotificationModel(
      notificationId: 2,
      userId: 1,
      itemId: 1,
      type: 'interest_received',
      message: 'Có 2 người quan tâm đến sản phẩm của bạn',
      readStatus: true,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    NotificationModel(
      notificationId: 3,
      userId: 1,
      itemId: null,
      type: 'transaction_completed',
      message: 'Giao dịch "Giày Nike Air Max mới" đã hoàn thành',
      readStatus: false,
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
    ),
    NotificationModel(
      notificationId: 4,
      userId: 2,
      itemId: 2,
      type: 'item_shared',
      message: 'Bạn vừa chia sẻ "Áo thun cotton"',
      readStatus: true,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    NotificationModel(
      notificationId: 5,
      userId: 3,
      itemId: 4,
      type: 'interest_received',
      message: 'Có 1 người quan tâm đến sản phẩm của bạn',
      readStatus: false,
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
  ];

  // ==================== USER BADGES ====================
  static final List<UserBadgeModel> userBadges = [
    UserBadgeModel(
      userBadgeId: 1,
      userId: 1,
      badgeId: 1,
      earnedAt: DateTime(2023, 6, 20),
    ),
    UserBadgeModel(
      userBadgeId: 2,
      userId: 1,
      badgeId: 2,
      earnedAt: DateTime(2023, 9, 15),
    ),
    UserBadgeModel(
      userBadgeId: 3,
      userId: 1,
      badgeId: 3,
      earnedAt: DateTime(2024, 1, 10),
    ),
    UserBadgeModel(
      userBadgeId: 4,
      userId: 2,
      badgeId: 1,
      earnedAt: DateTime(2023, 7, 25),
    ),
    UserBadgeModel(
      userBadgeId: 5,
      userId: 2,
      badgeId: 5,
      earnedAt: DateTime(2023, 12, 5),
    ),
    UserBadgeModel(
      userBadgeId: 6,
      userId: 4,
      badgeId: 1,
      earnedAt: DateTime(2023, 9, 10),
    ),
    UserBadgeModel(
      userBadgeId: 7,
      userId: 6,
      badgeId: 2,
      earnedAt: DateTime(2023, 11, 20),
    ),
    UserBadgeModel(
      userBadgeId: 8,
      userId: 6,
      badgeId: 3,
      earnedAt: DateTime(2024, 1, 30),
    ),
  ];

  /// Hàm trợ giúp: Lấy user theo ID
  static UserModel? getUserById(int userId) {
    try {
      return users.firstWhere((u) => u.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy item theo ID
  static ItemModel? getItemById(int itemId) {
    try {
      return items.firstWhere((i) => i.itemId == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy category theo ID
  static CategoryModel? getCategoryById(int categoryId) {
    try {
      return categories.firstWhere((c) => c.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy location theo ID
  static LocationModel? getLocationById(int locationId) {
    try {
      return locations.firstWhere((l) => l.locationId == locationId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy badge theo ID
  static BadgeModel? getBadgeById(int badgeId) {
    try {
      return badges.firstWhere((b) => b.badgeId == badgeId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy danh sách item của user
  static List<ItemModel> getItemsByUserId(int userId) {
    return items.where((i) => i.userId == userId).toList();
  }

  /// Hàm trợ giúp: Lấy danh sách tin nhắn của user
  static List<MessageModel> getMessagesByUserId(int userId) {
    return messages
        .where((m) => m.senderId == userId || m.receiverId == userId)
        .toList();
  }

  /// Hàm trợ giúp: Lấy gamification của user
  static GamificationModel? getGamificationByUserId(int userId) {
    try {
      return gamifications.firstWhere((g) => g.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy badges của user
  static List<BadgeModel> getBadgesByUserId(int userId) {
    final userBadgeList =
        userBadges.where((ub) => ub.userId == userId).toList();
    return userBadgeList
        .map((ub) => getBadgeById(ub.badgeId))
        .whereType<BadgeModel>()
        .toList();
  }

  /// Hàm trợ giúp: Lấy notifications của user
  static List<NotificationModel> getNotificationsByUserId(int userId) {
    return notifications.where((n) => n.userId == userId).toList();
  }

  /// Hàm trợ giúp: Đếm unread notifications
  static int getUnreadNotificationCount(int userId) {
    return notifications
        .where((n) => n.userId == userId && !n.readStatus)
        .length;
  }
}

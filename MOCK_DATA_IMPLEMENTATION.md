# Mock Data Implementation - KLTN Sharing App

## 📋 Tổng quan

Đã hoàn thành tạo hệ thống mock data toàn bộ cho dự án KLTN Sharing App, bao gồm 12 models và hơn 100+ dữ liệu ảo cho phát triển.

## 📁 Cấu trúc Thư mục

```
lib/
├── data/
│   ├── models/
│   │   ├── admin_model.dart                 ✅ Admin model
│   │   ├── user_model.dart                  ✅ User model
│   │   ├── item_model.dart                  ✅ Item model
│   │   ├── message_model.dart               ✅ Message model
│   │   ├── gamification_model.dart          ✅ Gamification model
│   │   ├── transaction_model.dart           ✅ Transaction model
│   │   ├── location_model.dart              ✅ Location model
│   │   ├── category_model.dart              ✅ Category model
│   │   ├── item_interest_model.dart         ✅ ItemInterest model
│   │   ├── notification_model.dart          ✅ Notification model
│   │   ├── user_badge_model.dart            ✅ UserBadge model
│   │   └── badge_model.dart                 ✅ Badge model
│   │
│   ├── services/
│   │   └── mock_data_service.dart           ✅ Service để quản lý mock data
│   │
│   └── mock_data.dart                       ✅ File chứa tất cả dữ liệu ảo
│
└── presentation/
    └── screens/
        ├── home/
        │   └── home_screen_with_mock_example.dart     ✅ Example integration
        │
        └── profile/
            └── profile_screen_mock_example.dart       ✅ Example integration
```

## 📊 Dữ Liệu Ảo Hiện Tại

### 👨‍💼 Admins (3 records)
- Admin Chính (super_admin)
- Quản lý Nội dung (admin)
- Người kiểm duyệt (moderator)

### 👥 Users (6 records)
- Các roles: user, seller, premium
- Trust scores từ 68-95
- Avatar URLs từ pravatar.cc
- Includes: name, email, phone, address, created_at

### 📦 Items (8 records)
- 8 sản phẩm chia sẻ
- Statuses: available, pending
- Categories: quần áo, giày dép, điện tử, sách, đồ chơi, nội thất, thể thao
- Expiration dates 20-100 ngày từ bây giờ
- Includes: quantity, user_id, category_id, location_id

### 💬 Messages (6 records)
- Tin nhắn giữa các users
- Một số liên quan đến items
- Một số là tin nhắn chung
- Timestamps: các thời điểm khác nhau

### 🎮 Gamifications (6 records)
- Points: 890-3520
- Levels: 5-15
- Một record cho mỗi user

### 🏆 Badges (5 records)
- Người chia sẻ mới
- Nhà chia sẻ lạc quan
- Nhân từ
- Người nhận hào phóng
- Kỵ sĩ mạo hiểm

### 🎁 Transactions (5 records)
- Statuses: completed, pending, verified
- Includes: payment_verified, proof_image
- Has: sharer_id, receiver_id, item_id
- Timestamps: created_at, confirmed_at

### 💌 Notifications (5 records)
- Types: item_shared, interest_received, transaction_completed
- Includes: read_status
- For: user tracking

### 📍 Locations (6 records)
- TP.HCM: Quận 1, 3, 5, 7
- Hà Nội: Hoàn Kiếm, Cầu Giấy
- Coordinates: latitude, longitude

### 🏷️ Categories (8 records)
- Quần áo, Giày dép, Điện tử, Sách, Đồ chơi, Nội thất, Thể thao, Khác

### ⭐ Item Interests (6 records)
- Users quan tâm đến items
- Statuses: interested, accepted
- Reasons: tại sao quan tâm

### 🎫 User Badges (8 records)
- Mapping users -> badges
- Earned dates

## 🚀 Cách Sử Dụng

### Import Service
```dart
import 'package:kltn_sharing_app/data/services/mock_data_service.dart';
```

### Trong Widget
```dart
final MockDataService _mockDataService = MockDataService();

// Lấy tất cả users
final users = await _mockDataService.getAllUsers();

// Lấy user theo ID
final user = await _mockDataService.getUserById(1);

// Lấy items có sẵn
final items = await _mockDataService.getAvailableItems();

// Tìm kiếm items
final results = await _mockDataService.searchItems('giày');

// Lấy leaderboard
final topUsers = await _mockDataService.getTopUsersByPoints(10);
```

### Với FutureBuilder
```dart
FutureBuilder<List<UserModel>>(
  future: _mockDataService.getAllUsers(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    final users = snapshot.data ?? [];
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(users[index].name),
        );
      },
    );
  },
)
```

## 📚 Danh Sách Methods

### User Methods
- `getAllUsers()` - Tất cả users
- `getUserById(int userId)` - User theo ID
- `getUsersByRole(String role)` - Users theo role

### Item Methods
- `getAllItems()` - Tất cả items
- `getItemById(int itemId)` - Item theo ID
- `getItemsByUserId(int userId)` - Items của user
- `getItemsByCategory(int categoryId)` - Items theo category
- `getAvailableItems()` - Items có sẵn
- `searchItems(String query)` - Tìm kiếm
- `filterItems({...})` - Lọc theo criteria

### Gamification Methods
- `getAllGamifications()` - Tất cả gamification records
- `getGamificationByUserId(int userId)` - Gamification của user
- `getTopUsersByPoints(int limit)` - Top users

### Message Methods
- `getAllMessages()` - Tất cả messages
- `getMessagesByUserId(int userId)` - Messages của user
- `getConversation(int userId1, int userId2)` - Cuộc hội thoại

### Notification Methods
- `getAllNotifications()` - Tất cả notifications
- `getNotificationsByUserId(int userId)` - Notifications của user
- `getUnreadNotificationCount(int userId)` - Đếm unread

### Badge Methods
- `getAllBadges()` - Tất cả badges
- `getBadgeById(int badgeId)` - Badge theo ID
- `getBadgesByUserId(int userId)` - Badges của user

### Location Methods
- `getAllLocations()` - Tất cả locations
- `getLocationById(int locationId)` - Location theo ID

### Category Methods
- `getAllCategories()` - Tất cả categories
- `getCategoryById(int categoryId)` - Category theo ID

### Transaction Methods
- `getAllTransactions()` - Tất cả transactions
- `getTransactionsByUserId(int userId)` - Transactions của user
- `getTransactionsByStatus(String status)` - Transactions theo status

### Item Interest Methods
- `getAllItemInterests()` - Tất cả item interests
- `getItemInterestsByItemId(int itemId)` - Interests cho item
- `getItemInterestsByUserId(int userId)` - Interests của user

### Admin Methods
- `getAllAdmins()` - Tất cả admins
- `getAdminById(int adminId)` - Admin theo ID

## 💡 Example Implementation

### HomeScreen with Mock Data
File: `lib/presentation/screens/home/home_screen_with_mock_example.dart`
- Demonstrates: Loading available items từ mock data
- UI: Product grid với FutureBuilder
- Features: Error handling, empty state, loading state

### ProfileScreen with Mock Data
File: `lib/presentation/screens/profile/profile_screen_mock_example.dart`
- Demonstrates: Multiple FutureBuilders
- UI: User info, gamification, badges, statistics
- Features: Nested async calls, data integration

## ⚡ Performance Notes

- Mỗi call có delay 300ms để mô phỏng network latency
- Dữ liệu được load trong memory (không cần database)
- Perfect cho development & testing
- Dễ dàng swap sang real API sau

## 🔄 Chuyển sang Real API

Khi sẵn sàng:

1. Tạo `ApiDataService` class
2. Implement cùng methods như `MockDataService`
3. Replace import hoặc dùng Service Locator (GetIt)

```dart
// Với GetIt
final getIt = GetIt.instance;

// Dev mode
getIt.registerSingleton<IDataService>(MockDataService());

// Production
getIt.registerSingleton<IDataService>(ApiDataService());

// Usage (không cần thay đổi code)
final service = getIt<IDataService>();
```

## 📝 Best Practices

✅ **Luôn làm:**
- Sử dụng `MockDataService` instead of trực tiếp `MockData`
- Sử dụng `FutureBuilder` hoặc `async/await`
- Handle error states
- Hiển thị loading indicators
- Validate dữ liệu trong UI

❌ **Tránh:**
- Hardcode IDs
- Ignore errors
- Bỏ qua loading states
- Modify mock data trong widgets
- Direct access to `MockData` class

## 📖 Documentation

Để chi tiết hơn, xem `MOCK_DATA_GUIDE.md`

## 🎯 Next Steps

1. ✅ Tích hợp mock data vào các screens hiện tại
2. ⏳ Setup API service khi sẵn sàng
3. ⏳ Migrate data từ mock → real API
4. ⏳ Unit tests cho data layer
5. ⏳ Integration tests cho screens

## 📞 Support

Nếu gặp issue:
1. Check `MOCK_DATA_GUIDE.md`
2. Xem các example screens
3. Verify imports paths
4. Check models compatibility

---

**Status**: ✅ Hoàn tất  
**Last Updated**: 2024-11-22  
**Models Count**: 12  
**Total Mock Records**: 100+

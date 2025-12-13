# Mock Data Usage Guide

## Tổng quan

Mock data được tạo ra để hỗ trợ quá trình phát triển ứng dụng KLTN Sharing App. Nó chứa dữ liệu ảo cho tất cả các bảng trong cơ sở dữ liệu.

## Cấu trúc File

### Models (`lib/data/models/`)
- `admin_model.dart` - Model cho Admin
- `user_model.dart` - Model cho User
- `item_model.dart` - Model cho Item (sản phẩm chia sẻ)
- `message_model.dart` - Model cho Message (tin nhắn)
- `gamification_model.dart` - Model cho Gamification (điểm & cấp độ)
- `transaction_model.dart` - Model cho Transaction (giao dịch)
- `location_model.dart` - Model cho Location (vị trí)
- `category_model.dart` - Model cho Category (danh mục)
- `item_interest_model.dart` - Model cho ItemInterest (quan tâm sản phẩm)
- `notification_model.dart` - Model cho Notification (thông báo)
- `user_badge_model.dart` - Model cho UserBadge (huy hiệu của user)
- `badge_model.dart` - Model cho Badge (huy hiệu)

### Mock Data (`lib/data/mock_data.dart`)
Chứa tất cả dữ liệu ảo được định nghĩa trong `MockData` class

### Service (`lib/data/services/mock_data_service.dart`)
Cung cấp các method tiện dụng để truy cập và quản lý mock data

## Cách Sử Dụng

### 1. Import Service
```dart
import 'package:kltn_sharing_app/data/services/mock_data_service.dart';
```

### 2. Sử dụng trong Widget
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final MockDataService _mockDataService = MockDataService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<UserModel>>(
        future: _mockDataService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          
          final users = snapshot.data ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 3. Sử dụng với BLoC/Provider
```dart
class UserRepository {
  final MockDataService _mockDataService = MockDataService();
  
  Future<UserModel?> getUserById(int userId) {
    return _mockDataService.getUserById(userId);
  }
  
  Future<List<UserModel>> getAllUsers() {
    return _mockDataService.getAllUsers();
  }
}
```

## Available Methods

### Admin Methods
- `getAllAdmins()` - Lấy tất cả admin
- `getAdminById(int adminId)` - Lấy admin theo ID

### User Methods
- `getAllUsers()` - Lấy tất cả users
- `getUserById(int userId)` - Lấy user theo ID
- `getUsersByRole(String role)` - Lấy users theo role (user, seller, premium)

### Item Methods
- `getAllItems()` - Lấy tất cả items
- `getItemById(int itemId)` - Lấy item theo ID
- `getItemsByUserId(int userId)` - Lấy items của user
- `getItemsByCategory(int categoryId)` - Lấy items theo danh mục
- `getAvailableItems()` - Lấy items có sẵn
- `searchItems(String query)` - Tìm kiếm items
- `filterItems({categoryId, locationId, status, maxPrice})` - Lọc items

### Category Methods
- `getAllCategories()` - Lấy tất cả danh mục
- `getCategoryById(int categoryId)` - Lấy danh mục theo ID

### Location Methods
- `getAllLocations()` - Lấy tất cả vị trí
- `getLocationById(int locationId)` - Lấy vị trí theo ID

### Message Methods
- `getAllMessages()` - Lấy tất cả tin nhắn
- `getMessagesByUserId(int userId)` - Lấy tin nhắn của user
- `getConversation(int userId1, int userId2)` - Lấy cuộc hội thoại giữa 2 user

### Gamification Methods
- `getAllGamifications()` - Lấy tất cả gamification records
- `getGamificationByUserId(int userId)` - Lấy gamification của user
- `getTopUsersByPoints(int limit)` - Lấy top users theo điểm

### Transaction Methods
- `getAllTransactions()` - Lấy tất cả giao dịch
- `getTransactionsByUserId(int userId)` - Lấy giao dịch của user
- `getTransactionsByStatus(String status)` - Lấy giao dịch theo trạng thái

### Item Interest Methods
- `getAllItemInterests()` - Lấy tất cả quan tâm sản phẩm
- `getItemInterestsByItemId(int itemId)` - Lấy quan tâm theo item
- `getItemInterestsByUserId(int userId)` - Lấy quan tâm theo user

### Notification Methods
- `getAllNotifications()` - Lấy tất cả thông báo
- `getNotificationsByUserId(int userId)` - Lấy thông báo của user
- `getUnreadNotificationCount(int userId)` - Đếm thông báo chưa đọc

### Badge Methods
- `getAllBadges()` - Lấy tất cả huy hiệu
- `getBadgeById(int badgeId)` - Lấy huy hiệu theo ID
- `getBadgesByUserId(int userId)` - Lấy huy hiệu của user

### User Badge Methods
- `getAllUserBadges()` - Lấy tất cả user badges
- `getUserBadgesByUserId(int userId)` - Lấy huy hiệu của user

## Dữ Liệu Ảo Hiện Tại

### Users
- 6 users với các roles: user, seller, premium
- Diverse trust scores: 68 - 95
- Avatar URLs sử dụng pravatar.cc

### Items
- 8 sản phẩm chia sẻ
- Các danh mục: quần áo, giày dép, điện tử, sách, đồ chơi, nội thất, thể thao
- Status: available, pending
- Expiration dates khoảng 20-100 ngày từ bây giờ

### Messages
- 6 tin nhắn
- Giữa các user khác nhau
- Một số có liên quan đến items, một số là tin nhắn chung

### Transactions
- 5 giao dịch
- Status: completed, pending, verified
- Payment verification examples

### Badges & Gamifications
- 5 huy hiệu khác nhau
- Gamification records cho tất cả users
- User badges mapping users -> badges

### Notifications
- 5 thông báo
- Các loại: item_shared, interest_received, transaction_completed

## Chú Ý Khi Phát Triển

1. **Delay**: Mỗi method có delay 300ms để mô phỏng network request
2. **Singleton Pattern**: MockDataService sử dụng singleton pattern
3. **Future-based**: Tất cả methods trả về Future để dễ dàng swap sang real API
4. **Type Safety**: Tất cả models đều được type-safe

## Chuyển từ Mock Data sang Real API

Khi sẵn sàng chuyển sang real API:

1. Tạo `RealDataService` implement cùng interface
2. Replace `MockDataService` bằng `RealDataService`
3. Hoặc sử dụng Service Locator pattern (GetIt) để dễ dàng swap

Ví dụ với GetIt:
```dart
// Initialization
getIt.registerSingleton<DataService>(MockDataService());
// Hoặc
getIt.registerSingleton<DataService>(RealDataService());

// Usage
final dataService = getIt<DataService>();
```

## Cập Nhật Mock Data

Để thêm/sửa mock data:

1. Chỉnh sửa `MockData` class trong `lib/data/mock_data.dart`
2. Hoặc thêm methods mới trong `MockDataService`
3. Models được auto-generated từ JSON, nên nhớ sử dụng `copyWith` để tạo variants

Ví dụ thêm user mới:
```dart
UserModel newUser = UserModel(
  userId: 7,
  name: 'New User',
  email: 'new@example.com',
  phone: '0912345678',
  passwordHash: '\$2b\$12\$...',
  role: 'user',
  trustScore: 50,
  createdAt: DateTime.now(),
);

// Thêm vào MockData.users
MockData.users.add(newUser);
```

## Best Practices

1. ✅ Luôn sử dụng `MockDataService` thay vì trực tiếp truy cập `MockData`
2. ✅ Sử dụng `FutureBuilder` hoặc `async/await` để xử lý Future
3. ✅ Thêm error handling cho snapshot errors
4. ✅ Sử dụng loader/skeleton screens khi loading
5. ❌ Đừng hardcode IDs, hãy sử dụng queries
6. ❌ Đừng bỏ qua error states

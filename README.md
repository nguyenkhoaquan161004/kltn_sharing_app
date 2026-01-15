# KLTN Sharing App

## 📋 Khái Quát Dự Án

**KLTN Sharing App** là một ứng dụng mobile nền tảng chia sẻ dựa trên mô hình kinh tế chia sẻ (sharing economy). Ứng dụng kết nối những người muốn cho thuê các mặt hàng của họ với những người cần thuê chúng, tạo ra một cộng đồng tiêu dùng bền vững và tiết kiệm chi phí.

## 🎯 Mô Tả Sản Phẩm

### Tính Năng Chính:
- **Danh Sách Sản Phẩm**: Duyệt, tìm kiếm và lọc các sản phẩm cho thuê
- **Quản Lý Giao Dịch**: Xem lịch sử giao dịch, chi tiết đơn hàng và trạng thái
- **Hệ Thống Tin Nhắn**: Chat real-time giữa người thuê và chủ sản phẩm
- **Thông Báo Real-time**: Nhận thông báo tức thì cho các sự kiện quan trọng (FCM)
- **Xác Thực 2 Tầng**: OTP verification để bảo mật tài khoản
- **Huy Hiệu & Thành Tích**: Hệ thống gamification khuyến khích người dùng tham gia
- **Bảng Xếp Hạng**: Theo dõi những người dùng hoạt động nhất
- **Quản Lý Giỏ Hàng**: Thêm/xóa sản phẩm trước khi thanh toán
- **Giao Dịch Sản Phẩm**: Suất tươi mới cho thuê/trả sản phẩm
- **Tìm Kiếm Hình Ảnh**: AI-powered image search để tìm sản phẩm tương tự
- **Đăng Nhập Google**: Xác thực nhanh chóng qua Google Sign-in
- **Định Vị Địa Phương**: Tìm sản phẩm gần vị trí của bạn

### Công Nghệ Sử Dụng:
- **Frontend**: Flutter (Dart)
- **Backend**: Java Spring Boot
- **API Communication**: HTTP (Dio)
- **Real-time**: WebSocket
- **Authentication**: JWT + Refresh Token
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Location**: Geocoding & Geolocator
- **State Management**: Provider

## 📁 Cấu Trúc Thư Mục

```
lib/
├── core/
│   ├── constants/           # Các hằng số ứng dụng
│   ├── utils/               # Utility functions, helpers
│   │   ├── auth_token_callback_helper.dart
│   │   ├── token_refresh_interceptor.dart
│   │   └── ...
│   └── routes/              # App routing configuration
├── data/
│   ├── models/              # Data models & entities
│   ├── providers/           # State management (Provider)
│   └── services/            # API services & business logic
│       ├── item_api_service.dart
│       ├── notification_api_service.dart
│       ├── message_api_service.dart
│       └── ...
├── presentation/
│   ├── screens/             # UI screens
│   │   ├── home/
│   │   ├── search/
│   │   ├── cart/
│   │   ├── messages/
│   │   ├── profile/
│   │   └── ...
│   ├── widgets/             # Reusable widgets
│   ├── providers/           # Provider-based state management
│   └── pages/               # Page containers
├── main.dart                # Entry point
└── config/                  # App configuration

assets/
├── icons/                   # Icon assets
├── images/                  # Image assets
├── svgs/                    # SVG files
└── fonts/                   # Custom fonts

docs/
├── ADMIN_SETUP.md           # Admin setup guide
├── API_RESPONSE_STRUCTURE.md
├── GOOGLE_LOGIN.md
├── LEADERBOARD_API.md
├── MESSAGING_API.md
├── TRANSACTIONS.md
└── TRANSACTION_DETAILS.md
```

## 🚀 Cách Chạy Dự Án

### 📋 Yêu Cầu
- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android SDK (API level 21+) hoặc iOS 11.0+
- Git

### ⚙️ Cài Đặt

1. **Clone Repository**
   ```bash
   git clone https://github.com/nguyenkhoaquan161004/kltn_sharing_app.git
   cd kltn_sharing_app
   ```

2. **Cài Đặt Dependencies**
   ```bash
   flutter pub get
   ```

3. **Cấu Hình Firebase (Optional - nếu sử dụng FCM)**
   - Tải file `google-services.json` từ Firebase Console
   - Đặt vào thư mục `android/app/`

4. **Cấu Hình Backend API**
   - Mở file `lib/core/constants/api_constants.dart`
   - Cập nhật `BASE_URL` trỏ đến server backend của bạn

### ▶️ Chạy Ứng Dụng

**Chạy trên Emulator/Device:**
```bash
flutter run
```

**Build APK (Debug):**
```bash
flutter build apk --debug
```

**Build APK (Release):**
```bash
flutter build apk --release
```

**Build iOS:**
```bash
flutter build ios
```

### 🧪 Lint & Analyze

**Kiểm tra lỗi:**
```bash
flutter analyze
```

**Format code:**
```bash
dart format .
```

## 🔑 Tính Năng Bảo Mật

- ✅ JWT Token Authentication
- ✅ Automatic Token Refresh (401 handling)
- ✅ Immediate Logout on 403 Error
- ✅ OTP Email Verification
- ✅ Secure Token Storage (SharedPreferences)
- ✅ SSL/TLS Encryption

## 📚 Tài Liệu Tham Khảo

Chi tiết về các tính năng và API, xem thư mục `docs/`:
- [Admin Setup Guide](docs/ADMIN_SETUP.md)
- [Messaging API](docs/MESSAGING_API.md)
- [Leaderboard API](docs/LEADERBOARD_API.md)
- [Transactions Guide](docs/TRANSACTIONS.md)

## 👥 Tác Giả

- **Nguyễn Khoa Quân** - Frontend (Flutter)
- **Tahomee** - Backend (Java Spring Boot)

## 📄 License

This project is private and belongs to the KLTN team.

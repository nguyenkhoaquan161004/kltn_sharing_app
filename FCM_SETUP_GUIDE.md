# Hướng dẫn Setup Firebase Cloud Messaging (FCM) Token

## Tổng quan

FCM (Firebase Cloud Messaging) là dịch vụ của Google để gửi push notifications. Backend của bạn có API để nhận FCM token và gửi notifications.

**FCM Token là gì?**
- Mã định danh duy nhất cho từng thiết bị
- Dùng để gửi push notifications đến thiết bị cụ thể
- Cần được gửi lên backend sau khi login

---

## 1. Cài đặt Dependencies

Đã thêm vào `pubspec.yaml`:
```yaml
firebase_core: ^26.0.0
firebase_messaging: ^14.6.0
```

Chạy:
```bash
flutter pub get
```

---

## 2. Setup Firebase Project

### Bước 1: Tạo Firebase Project (nếu chưa có)
1. Vào [Firebase Console](https://console.firebase.google.com)
2. Tạo project mới
3. Thêm ứng dụng Android và iOS

### Bước 2: Download File Cấu hình

**Cho Android:**
1. Vào Firebase Console → Project Settings → Download `google-services.json`
2. Đặt file vào: `android/app/`

**Cho iOS:**
1. Download `GoogleService-Info.plist`
2. Đặt file vào: `ios/Runner/` (thêm vào Xcode)

### Bước 3: Cấu hình Firebase Options

Mở file `lib/firebase_options.dart` và điền thông tin từ Firebase Console:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',                          // Từ google-services.json
  appId: 'YOUR_APP_ID',                            // Từ google-services.json
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',   // Từ google-services.json
  projectId: 'YOUR_PROJECT_ID',                    // Từ Firebase Console
  storageBucket: 'YOUR_STORAGE_BUCKET',            // Từ Firebase Console
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',                          // Từ GoogleService-Info.plist
  appId: 'YOUR_APP_ID',                            // Từ GoogleService-Info.plist
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',   // Từ GoogleService-Info.plist
  projectId: 'YOUR_PROJECT_ID',                    // Từ GoogleService-Info.plist
  storageBucket: 'YOUR_STORAGE_BUCKET',            // Từ GoogleService-Info.plist
  iosBundleId: 'com.kltn.kltnSharingApp',
);
```

---

## 3. Cách Lấy FCM Token

### Tự động (được setup rồi)

FCM token được lấy tự động trong `main.dart`:
```dart
await FCMService().initialize();
```

Khi khởi động ứng dụng:
1. ✅ Firebase được khởi tạo
2. ✅ FCMService lấy token từ Firebase
3. ✅ Token được lưu vào SharedPreferences
4. ✅ Lắng nghe token refresh

### Lấy token khi cần

```dart
// Lấy token từ local storage
final token = FCMService().getFCMToken();

// Hoặc lấy token mới từ Firebase
final token = await FCMService().getFCMTokenFromFirebase();
```

---

## 4. Gửi Token Lên Backend

### A. Tự động sau login

File `login_screen.dart` đã được cập nhật:

```dart
// Sau khi login thành công
final fcmToken = await FCMService().getFCMTokenFromFirebase();
if (fcmToken != null) {
  // TODO: Gọi API để update FCM token lên backend
  print('FCM Token: $fcmToken');
}
```

### B. Tạo API method trong UserApiService

Mở `lib/data/services/user_api_service.dart` và thêm:

```dart
/// Update FCM token trên backend
Future<void> updateFCMToken(String fcmToken) async {
  try {
    final response = await _dio.post(
      '/api/v2/users/fcm-token',  // TODO: Xác nhận endpoint từ BE
      data: {
        'fcmToken': fcmToken,
      },
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('[UserApiService] ✅ FCM token updated successfully');
    }
  } catch (e) {
    print('[UserApiService] ❌ Failed to update FCM token: $e');
    rethrow;
  }
}
```

### C. Cập nhật LoginScreen

Trong `lib/presentation/screens/auth/login_screen.dart`:

```dart
// Trong _handleLogin()
try {
  final fcmToken = await FCMService().getFCMTokenFromFirebase();
  if (fcmToken != null) {
    await userProvider.updateFCMToken(fcmToken);
    print('[LoginScreen] ✅ FCM token sent to backend');
  }
} catch (e) {
  print('[LoginScreen] ⚠️  Failed to update FCM token: $e');
}
```

---

## 5. Kiểm Tra Token

### Debug Console

Khi chạy ứng dụng, bạn sẽ thấy:
```
[FCMService] ✅ FCM Token: eZ5p8dXf...
[FCMService] 🔄 FCM Token refreshed: eZ5p8dXf...
[LoginScreen] 📤 Sending FCM token to backend
[LoginScreen] ✅ FCM token sent to backend
```

### Postman/API Test

1. Login để lấy access token
2. Gọi API `/api/v2/users/fcm-token` với:
```json
{
  "fcmToken": "eZ5p8dXf..."
}
```

---

## 6. Backend Integration

### Endpoint nào?

Backend của bạn cần có endpoint để nhận FCM token:
- **Endpoint:** `POST /api/v2/users/fcm-token` (hoặc tương tự)
- **Headers:** `Authorization: Bearer {accessToken}`
- **Body:**
```json
{
  "fcmToken": "..."
}
```

### Hỏi Backend Team

```
1. Endpoint để gửi FCM token là gì?
   - URL: ?
   - Method: GET/POST/PUT?
   - Parameter: fcmToken, token, deviceToken?
   
2. Khi nào cần gửi token?
   - Sau login?
   - Mỗi lần mở app?
   - Khi token refresh?
   
3. Cách gửi notifications:
   - API endpoint?
   - Tính năng gì được support?
```

---

## 7. Xử lý Notifications

### Foreground (ứng dụng đang chạy)

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got message: ${message.notification?.title}');
  // Hiển thị local notification hoặc update UI
});
```

### Background (ứng dụng chạy nền)

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
}

// Đăng ký handler
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## 8. Kiểm Tra Lỗi

| Lỗi | Giải pháp |
|-----|----------|
| `PlatformException: Not initialized` | Đảm bảo `Firebase.initializeApp()` được gọi trước |
| FCM token trống | Kiểm tra Firebase Console cấu hình |
| Token không cập nhật trên backend | Kiểm tra API endpoint đúng chưa |
| Không nhận notification | Kiểm tra token đã lưu trên backend chưa |

---

## 9. File Cấu hình

**Tạo file `.env` (optional):**
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_APP_ID=your-app-id
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
```

---

## 10. Checklist

- [ ] Download `google-services.json` (Android)
- [ ] Download `GoogleService-Info.plist` (iOS)
- [ ] Điền thông tin vào `firebase_options.dart`
- [ ] Chạy `flutter pub get`
- [ ] Cập nhật `UserApiService` với method `updateFCMToken()`
- [ ] Test login - kiểm tra logs
- [ ] Xác nhận token lưu lên backend
- [ ] Test notification từ Firebase Console

---

## Tài liệu Tham Khảo

- [Firebase Messaging Documentation](https://firebase.flutter.dev/docs/messaging/overview)
- [FCM Setup Guide](https://firebase.google.com/docs/cloud-messaging/flutter/client-setup)
- [Local Notifications](https://pub.dev/packages/flutter_local_notifications)

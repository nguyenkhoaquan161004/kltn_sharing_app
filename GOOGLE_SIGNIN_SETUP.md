# Google Sign-In Setup Guide

## Problem
Bạn đang gặp lỗi: `MissingPluginException(No implementation found for method init on channel plugins.flutter.io/google_sign_in)`

Điều này xảy ra vì Google Sign-In plugin chưa được cấu hình đúng ở phía native Android.

## Giải pháp

### 1. **Cài đặt Google Play Services** ✅ (Đã hoàn tất)
   - Đã thêm `google_sign_in: ^6.2.1` vào `pubspec.yaml`
   - Đã thêm meta-data vào `AndroidManifest.xml`

### 2. **Tạo Google Cloud Project và lấy Client ID**

#### Bước 2a: Tạo Project tại Google Cloud Console
1. Vào https://console.cloud.google.com
2. Tạo project mới (e.g., "KLTN Sharing App")
3. Vào **OAuth consent screen**:
   - Chọn **External** user type
   - Điền thông tin app
   - Thêm scopes: `profile`, `email`, `openid`

#### Bước 2b: Tạo Android OAuth Client
1. Vào **Credentials** → **Create Credentials** → **OAuth Client ID**
2. Chọn **Android**
3. Điền Package name: `com.example.kltn_sharing_app`
4. Lấy **SHA-1 fingerprint** từ Android Keystore:

```bash
# Lấy debug keystore SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Hoặc trên Windows:
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

5. Copy SHA-1 fingerprint vào Google Cloud Console
6. Lấy **Client ID** (dạng: `xxx-xxx.apps.googleusercontent.com`)

### 3. **Cập nhật google-services.json** (Nếu cần)

1. Tải `google-services.json` từ Firebase Console
2. Đặt vào: `android/app/google-services.json`

### 4. **Clean & Rebuild**

```bash
flutter clean
flutter pub get
flutter run
```

### 5. **Kiểm tra lỗi khác (Nếu vẫn gặp lỗi)**

Nếu vẫn gặp `MissingPluginException` sau các bước trên:

#### Option A: Xoá emulator cache
```bash
flutter clean
rm -rf build/
flutter pub get
```

#### Option B: Rebuild emulator/APK
```bash
flutter build apk --debug
flutter install
```

#### Option C: Kiểm tra GeneratedPluginRegistrant.java
Đảm bảo file này được generate:
- `android/app/src/debug/java/io/flutter/plugins/GeneratedPluginRegistrant.java`

Nếu không có, chạy:
```bash
flutter pub get
flutter pub upgrade
```

### 6. **Cấu hình Backend (API)**

Đảm bảo backend của bạn đã cấu hình Google Sign-In:
- Endpoint: `/public/v2/auth/google`
- Method: `POST`
- Body:
```json
{
  "idToken": "string",
  "code": "string",
  "redirectUri": "string",
  "codeVerifier": "string"
}
```

### 7. **Kiểm tra Frontend Code**

File: `lib/presentation/screens/auth/login_screen.dart`

```dart
Future<void> _handleGoogleSignIn() async {
  try {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;
    
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    
    final success = await authProvider.googleLogin(idToken: idToken);
    // ... rest of code
  }
}
```

## Troubleshooting

| Lỗi | Nguyên nhân | Giải pháp |
|-----|----------|---------|
| `MissingPluginException` | Plugin chưa được load | `flutter clean && flutter pub get && flutter run` |
| `GoogleSignInException: Unknown status 12500` | Google Play Services không có sẵn | Cài đặt trên thiết bị/emulator có Google Play Store |
| `GoogleSignInException: DEVELOPER_ERROR` | SHA-1 hoặc Client ID không khớp | Kiểm tra lại `google-services.json` |
| `401 Unauthorized` từ API | idToken không hợp lệ | Kiểm tra backend xác thực idToken |

## Tài liệu tham khảo

- Google Sign-In Flutter: https://pub.dev/packages/google_sign_in
- Firebase Console: https://console.firebase.google.com
- Google Cloud Console: https://console.cloud.google.com

---

**Ngày tạo:** 2025-12-30  
**Version:** 1.0

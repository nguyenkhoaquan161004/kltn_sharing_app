# Refresh Token Implementation Guide

## Những gì đã được implement:

### 1. **AuthProvider** - Token Management (`lib/data/providers/auth_provider.dart`)
- ✅ Lưu `accessToken`, `refreshToken`, `tokenExpiresAt` vào SharedPreferences
- ✅ `refreshAccessToken()` - Sử dụng refresh token để lấy access token mới
- ✅ `_shouldRefreshToken()` - Kiểm tra nếu token sắp hết hạn (60 giây buffer)
- ✅ `getValidAccessToken()` - Tự động refresh nếu cần, trả về valid token

### 2. **AuthApiService** - API Endpoints (`lib/data/services/auth_api_service.dart`)
- ✅ `/login` - Đăng nhập, nhận accessToken + refreshToken
- ✅ `/refresh-token` - Refresh access token bằng refresh token (POST RefreshTokenRequest)
- ✅ `/logout` - Đăng xuất, gửi refreshToken

### 3. **ItemApiService** Enhancement (`lib/data/services/item_api_service.dart`)
- ✅ Thêm `setGetValidTokenCallback()` method
- ✅ Gọi `_getValidTokenCallback()` trước mỗi request để đảm bảo token hợp lệ

## Token Flow:

```
1. User Login
   ↓
   POST /public/v2/auth/login
   ← accessToken (15 phút), refreshToken (30 ngày)
   ↓
   Save tokens + expiresAt time

2. API Request
   ↓
   Check: Token hết hạn chưa?
   ├─ Nếu còn hơn 60s → Dùng token hiện tại
   └─ Nếu sắp hết → Refresh token trước

3. Token Refresh
   ↓
   POST /public/v2/auth/refresh-token
   {refreshToken: "..."}
   ← New accessToken + new refreshToken
   ↓
   Lưu lại + Retry request

4. Nếu Refresh Token Hết Hạn (30 ngày)
   ↓
   Refresh token request returns 401
   ↓
   Clear all tokens
   ↓
   User phải login lại
```

## Những bước cần làm tiếp:

### 1. Update main.dart - Pass callback đến API Services
```dart
// UserApiService
Provider<UserApiService>(
  create: (context) => UserApiService(),
),

// Sau khi tạo UserProvider, set callback:
ChangeNotifierProxyProvider2<AuthProvider, UserApiService, UserProvider>(
  create: (context) => UserProvider(),
  update: (context, authProvider, userApiService, previous) {
    final provider = previous ?? UserProvider();
    // Set callback để auto-refresh token
    userApiService.setGetValidTokenCallback(() => 
      authProvider.getValidAccessToken());
    return provider;
  },
),
```

### 2. Update UserApiService, GamificationApiService, CategoryApiService
- Thêm `_getValidTokenCallback` field
- Thêm `setGetValidTokenCallback()` method  
- Gọi callback trước mỗi authenticated request

### 3. Test Token Refresh
1. Login → Lấy tokens
2. Chờ accessToken sắp hết (hoặc manual test bằng cách set expiresAt ngắn)
3. Gửi API request → Nó phải auto-refresh token
4. Verify token mới được save

## Current Implementation Status:

✅ AuthProvider: Token management logic complete
✅ AuthApiService: Refresh endpoint ready
✅ ItemApiService: Enhanced with callback support
⏳ UserApiService: Needs update
⏳ GamificationApiService: Needs update
⏳ CategoryApiService: Needs update
⏳ main.dart: Needs callback setup

## Key Constants:

- **Access Token Expiry**: 15 minutes (900 seconds)
- **Refresh Token Expiry**: 30 days (2592000 seconds)
- **Refresh Buffer**: 60 seconds (refresh if expires within 60s)

## Important Notes:

1. Token được lưu vào SharedPreferences (persist qua session)
2. Khi app start, tokens được auto-load từ SharedPreferences
3. Nếu refresh token hết hạn, user phải login lại (không có cách khác)
4. Mỗi refresh cấp new refreshToken, update token list

# Token Refresh Architecture - Chi Tiết Hoạt Động

## Tóm Tắt Cơ Chế

App sử dụng **2 chiếc refresh token**:
1. **Access Token** (15 phút): Dùng cho API requests
2. **Refresh Token** (30 ngày): Dùng để lấy access token mới

## Quy Trình Chi Tiết

### 1. LOGIN (AuthProvider.login)
```
User clicks Login
    ↓
POST /public/v2/auth/login {username, password}
    ↓
Backend returns:
{
  "access_token": "eyJhbGc...",      ← Dùng cho API calls (15 phút)
  "refresh_token": "eyJhbGc...",     ← Lưu tính lâu dài (30 ngày)
  "expires_in": 900                   ← Token sẽ hết hạn sau 900 giây
}
    ↓
AuthProvider._saveTokens() lưu vào SharedPreferences:
  - access_token
  - refresh_token  ← QUAN TRỌNG!
  - token_expires_at (900s từ bây giờ)
    ↓
✅ User đã login
```

### 2. API REQUEST - Token Còn Hiệu Lực
```
User makes API request (e.g., GET /items)
    ↓
ItemApiService.getItems()
    ↓
Add header: Authorization: Bearer {access_token}
    ↓
POST /items
    ↓
✅ Backend checks token → còn hạn → Returns 200 OK
```

### 3. API REQUEST - Token Sắp Hết Hạn (Proactive)
```
User makes API request
    ↓
ItemApiService.getItems()
    ↓
AuthProvider.getValidAccessToken() check:
  - Token hết hạn trong 60 giây chưa?
  - YES → Call AuthProvider.refreshAccessToken()
    ↓
AuthProvider.refreshAccessToken():
  - POST /public/v2/auth/refresh-token
  - Body: { "refreshToken": "{stored_refresh_token}" }
    ↓
Backend validates refresh token → OK
  → Returns new tokens
    ↓
AuthProvider._saveTokens() update SharedPreferences:
  - access_token ← NEW
  - refresh_token ← NEW (backend may rotate it)
    ↓
✅ Got fresh access token
    ↓
Retry original API request with NEW token
```

### 4. API REQUEST - Token Hết Hạn (401 Error)
```
User makes API request
    ↓
ItemApiService.getItems()
    ↓
Authorization: Bearer {expired_access_token}
    ↓
Backend rejects: 401 Unauthorized
    ↓
TokenRefreshInterceptor.onError() catches 401
    ↓
Check: refreshToken in SharedPreferences?
  - YES → POST /public/v2/auth/refresh-token
  - NO → Clear all tokens, Force re-login
    ↓
Backend validates refresh token → OK
  → Returns new tokens
    ↓
TokenRefreshInterceptor._saveTokens():
  - access_token ← NEW
  - refresh_token ← NEW
    ↓
✅ Got fresh access token
    ↓
Retry original API request with NEW token
```

### 5. REFRESH TOKEN HẾT HẠN (30 ngày)
```
Refresh token hết hạn → Backend rejects it
    ↓
TokenRefreshInterceptor detects error
    ↓
Clear all tokens from SharedPreferences:
  - access_token
  - refresh_token
  - token_expires_at
    ↓
Call onTokenExpiredCallback
    ↓
User forced to re-login
```

## Các File Liên Quan

### 1. **lib/data/providers/auth_provider.dart**
- `login()` - Đăng nhập, lưu cả access + refresh token
- `_saveTokens()` - Lưu tokens vào SharedPreferences
- `refreshAccessToken()` - Dùng refresh token để lấy access token mới
- `getValidAccessToken()` - Return valid token (refresh nếu cần)
- `_shouldRefreshToken()` - Check token sắp hết hạn (60s buffer)
- `_clearTokens()` - Xóa all tokens khi refresh fail

### 2. **lib/core/utils/token_refresh_interceptor.dart**
- Thêm vào tất cả API services
- `onError()` - Bắt 401/403, tự động refresh token
- `_saveTokens()` - Lưu tokens mới từ refresh response
- `setCallbacks()` - Set callback từ AuthProvider (optional)

### 3. **lib/data/services/auth_api_service.dart**
- `login()` - POST /login, trả TokenResponse
- `refreshToken()` - POST /refresh-token, trả TokenResponse mới

### 4. **lib/data/models/auth_response_model.dart**
```dart
class TokenResponse {
  final String accessToken;
  final String refreshToken;  ← QUAN TRỌNG!
  final int expiresIn;
  final String tokenType;
}
```

### 5. **lib/main.dart**
- ItemApiService, UserApiService, vv
- Mỗi cái đều có TokenRefreshInterceptor
- ProxyProvider set callback từ AuthProvider

## Debug Checklist

Nếu token refresh không hoạt động:

✅ **Login screen:**
- [ ] Backend trả về `access_token` + `refresh_token`?
  - Check: API response format
  - Check: TokenResponse.fromJson() parsing

✅ **AuthProvider:**
- [ ] `_saveTokens()` được gọi sau login?
  - Print: "[AuthProvider] ✅ Tokens saved"
  - Check: refreshToken lưu vào SharedPreferences
- [ ] `_shouldRefreshToken()` trả true khi token sắp hết?
  - Print: Token expiry time

✅ **Token Refresh:**
- [ ] Khi 401, `TokenRefreshInterceptor.onError()` được gọi?
  - Print: "[TokenRefreshInterceptor] Attempting to refresh..."
- [ ] Refresh token tồn tại trong SharedPreferences?
  - Print: "[TokenRefreshInterceptor] Using refresh token..."
- [ ] Backend `/refresh-token` endpoint hoạt động?
  - Test: Postman POST /refresh-token {refreshToken: "..."}
  - Check response format: {success: true, data: {access_token, refresh_token}}
- [ ] New tokens được save?
  - Print: "[TokenRefreshInterceptor] New refresh token saved..."

✅ **API Services:**
- [ ] Mỗi service có TokenRefreshInterceptor?
  - Check: `_tokenRefreshInterceptor = TokenRefreshInterceptor()`
- [ ] Callback được set từ main.dart?
  - Print: "Error setting token refresh callback" nếu fail

## Logs Cần Xem

### Successful Login:
```
[AuthProvider] ✅ Tokens saved to SharedPreferences
[AuthProvider] - Access Token: eyJhbGciOiJIUzUxMiJ9...
[AuthProvider] - Refresh Token: eyJhbGciOiJIUzUxMiJ9...
[AuthProvider] - Expires At: 2024-01-01 12:45:00.000000
```

### Successful Proactive Refresh:
```
[AuthProvider] 🔄 Refreshing access token using refresh token...
[AuthProvider] ✅ Got new tokens from backend
[AuthProvider] New refresh token: eyJhbGciOiJIUzUxMiJ9...
[AuthProvider] ✅ Token refreshed successfully
```

### Successful 401 Recovery:
```
[TokenRefreshInterceptor] Attempting to refresh token after 401 error
[TokenRefreshInterceptor] Using refresh token from SharedPreferences: eyJhbGc...
[TokenRefreshInterceptor] ✅ Token refreshed successfully
[TokenRefreshInterceptor] New refresh token saved: eyJhbGc...
```

### Token Expired (Need Re-login):
```
[TokenRefreshInterceptor] ❌ No refresh token available in SharedPreferences
[TokenRefreshInterceptor] ❌ Token refresh failed
[AuthProvider] User session expired, need to re-login
```

## Important Notes

1. **RefreshToken phải được lưu** - Đây là key để refresh. Nếu không lưu → không thể refresh → phải login lại
2. **Mỗi refresh cấp new refreshToken** - Backend có thể rotate token, phải save cái mới
3. **Interceptor hoạt động tự động** - Không cần manual call refresh khi 401
4. **ProxyProvider wiring** - main.dart phải inject callback vào tất cả API services
5. **Token expiry buffer** - Refresh 60s trước hết hạn (proactive)

## Testing Token Refresh

### 1. Simulate Token Expiry:
```dart
// In debug, manually set token to expire
_tokenExpiresAt = DateTime.now().subtract(Duration(seconds: 61));
```

### 2. Make API Request:
```dart
// Should trigger auto-refresh in AuthProvider.getValidAccessToken()
final items = await itemApiService.getItems();
```

### 3. Check Logs:
```
[AuthProvider] 🔄 Refreshing access token...
[AuthProvider] ✅ Token refreshed successfully
[ItemAPI] REQUEST[GET] => /items
[ItemAPI] RESPONSE[200] => /items
```

### 4. Verify RefreshToken Saved:
```dart
final prefs = await SharedPreferences.getInstance();
final newRefreshToken = prefs.getString('refresh_token');
print('New refresh token: $newRefreshToken');
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────┐                                        │
│  │   AuthProvider      │                                        │
│  │ (Token Manager)     │                                        │
│  ├─────────────────────┤                                        │
│  │ accessToken         │                                        │
│  │ refreshToken    ←─────── SAVE HERE on login!                │
│  │ tokenExpiresAt      │                                        │
│  │                     │                                        │
│  │ login()             │                                        │
│  │ refreshAccessToken()│                                        │
│  │ getValidToken()     │                                        │
│  └────────┬────────────┘                                        │
│           │                                                     │
│           │ Callback: getValidAccessToken()                    │
│           │                                                     │
│  ┌────────▼─────────────────────────────────────────────────┐ │
│  │            Item/User/Category API Services              │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  ┌──────────────────────────────────────────────────┐   │ │
│  │  │    TokenRefreshInterceptor                       │   │ │
│  │  ├──────────────────────────────────────────────────┤   │ │
│  │  │ onError(401/403)                                 │   │ │
│  │  │ ├─ Get refreshToken from SharedPreferences       │   │ │
│  │  │ ├─ POST /refresh-token {refreshToken}            │   │ │
│  │  │ ├─ Save new tokens                               │   │ │
│  │  │ └─ Retry original request                        │   │ │
│  │  │                                                  │   │ │
│  │  │ _saveTokens()                                    │   │ │
│  │  │ └─ Save to SharedPreferences                    │   │ │
│  │  └──────────────────────────────────────────────────┘   │ │
│  │                                                         │ │
│  │  Dio HTTP Client                                        │ │
│  └─────────────────────────────────────────────────────────┘ │
│                          │                                     │
└──────────────────────────┼─────────────────────────────────────┘
                           │ HTTP
                           │
                    ┌──────▼──────┐
                    │   Backend   │
                    │             │
                    │ /login      │
                    │ /refresh..  │
                    │ /items      │
                    │ /users      │
                    └─────────────┘
```

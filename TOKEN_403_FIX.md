# 403 Token Expiration Fix - Implementation Summary

## ✅ Problem Solved
When API calls fail with **403 Forbidden** (token expired or refresh failed), the app now:
- Automatically logs out the user
- Shows an error message
- Redirects to the login screen
- Allows user to re-authenticate

Instead of showing an error screen with a "Retry" button.

## Solution Architecture

### 1. **TokenRefreshInterceptor** handles 403 errors
Location: [lib/core/utils/token_refresh_interceptor.dart](lib/core/utils/token_refresh_interceptor.dart#L72-L99)

When HTTP 403 is received:
- Clears all tokens from storage
- Calls `onTokenExpiredCallback()` immediately
- Does NOT retry the failed request

### 2. **Helper Utility** provides consistent callback
Created: [lib/core/utils/auth_token_callback_helper.dart](lib/core/utils/auth_token_callback_helper.dart)

`createTokenExpiredCallback(BuildContext context)` function that:
- Calls `authProvider.logout()` to clear user session
- Displays SnackBar message with user-friendly text
- Redirects to login screen via `context.go(AppRoutes.login)`
- Handles errors gracefully with try-catch

### 3. **All Services Updated** with correct callback signature
Changed from: `Future<String?> Function()` (incorrect)
Changed to: `Future<void> Function()` (correct)

Services updated:
- [lib/data/services/item_api_service.dart](lib/data/services/item_api_service.dart#L96)
- [lib/data/services/cart_api_service.dart](lib/data/services/cart_api_service.dart#L56)
- [lib/data/services/transaction_api_service.dart](lib/data/services/transaction_api_service.dart#L57)
- [lib/data/services/message_api_service.dart](lib/data/services/message_api_service.dart#L59)
- [lib/data/services/report_api_service.dart](lib/data/services/report_api_service.dart#L54)
- [lib/data/services/user_api_service.dart](lib/data/services/user_api_service.dart#L57)

### 4. **All Screens Updated** to use correct callback
Fixed 11 screen/widget files to use `createTokenExpiredCallback(context)` instead of incorrect `() async => authProvider.accessToken`:

- [search_results_screen.dart](lib/presentation/screens/search/search_results_screen.dart#L78)
- [product_detail_screen.dart](lib/presentation/screens/product/product_detail_screen.dart#L78)
- [cart_all_screen.dart](lib/presentation/screens/orders/cart_all_screen.dart#L80)
- [order_detail_screen.dart](lib/presentation/screens/orders/order_detail_screen.dart#L48)
- [messages_list_screen.dart](lib/presentation/screens/messages/messages_list_screen.dart#L49)
- [chat_screen.dart](lib/presentation/screens/messages/chat_screen.dart#L78)
- [profile_products_tab.dart](lib/presentation/screens/profile/widgets/profile_products_tab.dart#L77)
- [profile_achievements_tab.dart](lib/presentation/screens/profile/widgets/profile_achievements_tab.dart#L45)
- [cart_item_request_modal.dart](lib/presentation/screens/orders/widgets/cart_item_request_modal.dart#L99)
- [chatbot_screen.dart](lib/presentation/screens/chatbot/chatbot_screen.dart#L51)

## Execution Flow

```
API Request with token
    ↓
Response 403 Forbidden (or token refresh fails)
    ↓
TokenRefreshInterceptor.onError(403) triggers
    ↓
Clear tokens from SharedPreferences
    ↓
Call onTokenExpiredCallback()
    ↓
createTokenExpiredCallback() executes:
  - authProvider.logout()      // Backend call to /api/v2/auth/logout
  - Show SnackBar message      // "Phiên đăng nhập... hết hạn"
  - context.go(AppRoutes.login) // Redirect to login screen
    ↓
User sees login screen and can re-authenticate
```

## Logs to Monitor

When 403 is encountered, you'll see:
```
[TokenRefreshInterceptor] 🚫 403 Forbidden - Token không hợp lệ hoặc quyền bị từ chối
[TokenRefreshInterceptor] Path: /api/v2/items
[TokenRefreshInterceptor] Clearing tokens and forcing re-login...
[TokenExpiredCallback] 🚫 Token expired - logging out and redirecting to login
[TokenExpiredCallback] Calling logout...
[TokenExpiredCallback] Redirecting to login screen
```

## Testing

To verify this fix works:

1. **Start the app and login** ✓
2. **Get token expiration:**
   - Wait for token to expire naturally, OR
   - Manually revoke token on backend, OR
   - Delete token from SharedPreferences in debugger
3. **Make any API call** (scroll list, click search, etc.)
4. **Expected behavior:**
   - See message: "Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại."
   - Automatically redirected to login screen
   - Can log in again successfully

## Edge Cases Handled

✅ Network errors during logout - still redirects to login  
✅ Context unmounted - safe guards prevent crashes  
✅ Multiple concurrent API calls - first 403 wins (no race conditions)  
✅ 401 (token expired) still tries refresh - separate from 403  
✅ 403 with insufficient permissions - also triggers logout (security)

## Files Changed

1. **Created new file:**
   - `lib/core/utils/auth_token_callback_helper.dart`

2. **Modified service files** (fixed callback signature):
   - lib/data/services/item_api_service.dart
   - lib/data/services/cart_api_service.dart  
   - lib/data/services/transaction_api_service.dart
   - lib/data/services/message_api_service.dart
   - lib/data/services/report_api_service.dart
   - lib/data/services/user_api_service.dart

3. **Modified screen files** (added import + fixed callback usage):
   - lib/presentation/screens/search/search_results_screen.dart
   - lib/presentation/screens/product/product_detail_screen.dart
   - lib/presentation/screens/profile/widgets/profile_products_tab.dart
   - lib/presentation/screens/orders/cart_all_screen.dart
   - lib/presentation/screens/orders/order_detail_screen.dart
   - lib/presentation/screens/profile/widgets/profile_achievements_tab.dart
   - lib/presentation/screens/orders/widgets/cart_item_request_modal.dart
   - lib/presentation/screens/messages/messages_list_screen.dart
   - lib/presentation/screens/messages/chat_screen.dart
   - lib/presentation/screens/chatbot/chatbot_screen.dart

# Cart All Screen - 4 Tab Implementation

## Overview

Updated `cart_all_screen.dart` to display 4 tabs for managing shopping carts and transactions with status filtering.

## Tabs Structure

### 1. **Giỏ hàng (Cart)**
- **API**: `GET /api/v2/cart`
- **Content**: User's cart items waiting to be ordered
- **Status**: Items available for selection
- **Actions**: 
  - "Nhắn ngay" (Message seller)
  - "Tôi muốn nhận" (Request item - opens ItemRequestModal)

### 2. **Chờ duyệt (Pending Approval)**
- **API**: `GET /api/v2/transactions/me`
- **Filter**: Status = `PENDING`
- **Content**: Transaction requests waiting for sharer approval
- **Display**: Shows item info, sharer name, status badge
- **Actions**: "Chi tiết" (View details)

### 3. **Đã duyệt (Approved)**
- **API**: `GET /api/v2/transactions/me`
- **Filter**: Status = `ACCEPTED` OR `IN_PROGRESS`
- **Content**: Approved transactions being prepared/shipped
- **Status Display**: "Đã duyệt - Đang chờ giao hàng" or "Đang giao hàng"
- **Actions**: "Chi tiết" (View details)

### 4. **Hoàn thành (Completed)**
- **API**: `GET /api/v2/transactions/me`
- **Filter**: Status = `REJECTED`, `COMPLETED`, or `CANCELLED`
- **Content**: Finished transactions
- **Status Display**: Shows final status (Từ chối, Hoàn thành, Đã hủy)
- **Actions**: "Chi tiết" (View details)

## Transaction Status Flow

```
PENDING (Chờ duyệt)
    ↓
ACCEPTED (Đã duyệt)
    ↓
IN_PROGRESS (Đang giao)
    ↓
COMPLETED (Hoàn thành)

OR

PENDING → REJECTED (Từ chối)
PENDING → CANCELLED (Đã hủy)
```

## Implementation Details

### State Management
```dart
List<dynamic> _cartItems = [];
List<TransactionModel> _pendingTransactions = [];
List<TransactionModel> _acceptedTransactions = [];
List<TransactionModel> _completedTransactions = [];

bool _isLoadingCart = false;
bool _isLoadingTransactions = false;
String? _errorMessage;
```

### Data Loading
The `_loadCartAndTransactions()` method:
1. Loads cart items from MockData (TODO: Replace with API call)
2. Loads transactions from MockData (TODO: Replace with API call)
3. Filters transactions by status into separate lists
4. Shows loading state and error messages

### Transaction Card Display
Each transaction card shows:
- Product image (placeholder)
- Product name
- Sharer name (from seller info)
- Current status with color coding
- Navigation to detail screen

### Status Color Mapping
```dart
PENDING       → Orange (#FFA726)
ACCEPTED      → Teal (primary color)
REJECTED      → Red
IN_PROGRESS   → Cyan
COMPLETED     → Green (success color)
CANCELLED     → Gray
```

### Helper Methods
- `_getStatusDisplay(status)` - Vietnamese status label
- `_getStatusColor(status)` - Status color for display
- `_buildTransactionActionButtons(transaction)` - Status-specific action buttons
- `_buildTransactionSection()` - Transaction list builder
- `_buildTransactionCard()` - Individual transaction card

## API Integration (TODO)

### Cart Endpoint
```http
GET /api/v2/cart
Authorization: Bearer <access_token>
```

### Transactions Endpoint
```http
GET /api/v2/transactions/me
Authorization: Bearer <access_token>
```

**Replace mock data calls with actual API calls:**

```dart
// Example implementation
Future<void> _loadCartAndTransactions() async {
  try {
    // Load cart
    final cartResponse = await _cartApiService.getCart();
    
    // Load transactions
    final transResponse = await _transactionApiService.getMyTransactions();
    
    // Process and filter...
  } catch (e) {
    setState(() => _errorMessage = e.toString());
  }
}
```

## Key Features

✅ **4 Tab Navigation** - Tab bar with 4 distinct tabs
✅ **Status Filtering** - Transactions automatically filtered by status
✅ **Empty States** - Shows appropriate empty state for each tab
✅ **Loading States** - Displays loading indicator while fetching data
✅ **Error Handling** - Shows error messages if API calls fail
✅ **Status Badges** - Color-coded status indicators
✅ **Transaction Details** - Navigation to transaction detail screen
✅ **Type Safety** - Uses TransactionStatus enum instead of strings
✅ **Auth Integration** - Automatically sets auth tokens from AuthProvider
✅ **Responsive UI** - Scrollable list with proper padding and spacing

## User Journey

1. User opens "Đơn hàng" (Orders) screen
2. Sees 4 tabs: Giỏ hàng, Chờ duyệt, Đã duyệt, Hoàn thành
3. **Giỏ hàng tab**: Can request items or message sellers
4. **Chờ duyệt tab**: Waiting for seller to approve request
5. **Đã duyệt tab**: Seller approved, tracking delivery
6. **Hoàn thành tab**: Completed, rejected, or cancelled transactions

## Testing Checklist

- [ ] Cart tab displays items correctly
- [ ] Pending tab shows only PENDING status transactions
- [ ] Approved tab shows ACCEPTED and IN_PROGRESS transactions
- [ ] Completed tab shows REJECTED, COMPLETED, CANCELLED transactions
- [ ] Empty state shows for tabs with no data
- [ ] Loading indicator shows while fetching data
- [ ] Error message displays on API failure
- [ ] Status colors display correctly
- [ ] Navigation to transaction details works
- [ ] Request item modal opens from cart tab
- [ ] Message seller functionality works

## Files Modified

- `lib/presentation/screens/orders/cart_all_screen.dart` - Main implementation

## Related Files

- `lib/data/models/transaction_status.dart` - TransactionStatus enum
- `lib/data/models/transaction_model.dart` - TransactionModel with status enum
- `lib/data/services/transaction_api_service.dart` - API service
- `lib/data/services/cart_api_service.dart` - Cart API service
- `lib/data/providers/auth_provider.dart` - Auth token management

## Next Steps

1. Implement actual API calls in `_loadCartAndTransactions()`
2. Add pagination for large lists
3. Add refresh/pull-to-refresh functionality
4. Implement real-time status updates (WebSocket)
5. Add transaction filtering/search
6. Add transaction sorting options
7. Implement caching to reduce API calls
8. Add animations for status changes

## Notes

- Uses MockData for testing until API endpoints are available
- Auth tokens are automatically managed via AuthProvider
- All transaction status filtering uses the type-safe TransactionStatus enum
- UI colors are consistent with app theme defined in AppColors
- Empty states help guide user behavior


# Cart All Screen - Quick Reference Guide

## 🎯 What Was Implemented

Updated the **cart_all_screen.dart** to have **4 tabs** instead of 3:

| Tab | Tên | API | Statuses |
|-----|-----|-----|----------|
| 1 | **Giỏ hàng** | `GET /api/v2/cart` | N/A (Items) |
| 2 | **Chờ duyệt** | `GET /api/v2/transactions/me` | `PENDING` |
| 3 | **Đã duyệt** | `GET /api/v2/transactions/me` | `ACCEPTED`, `IN_PROGRESS` |
| 4 | **Hoàn thành** | `GET /api/v2/transactions/me` | `REJECTED`, `COMPLETED`, `CANCELLED` |

## 📊 Tab Details

### Tab 1: Giỏ Hàng (Shopping Cart)
**Shows:** Items user wants to order
**API:** `GET /api/v2/cart`
**Buttons:**
- "Nhắn ngay" - Message the seller
- "Tôi muốn nhận" - Request the item

### Tab 2: Chờ Duyệt (Pending)
**Shows:** Transactions waiting for seller approval
**Status:** PENDING
**Display:** Product, seller name, pending status
**Action:** View transaction details

### Tab 3: Đã Duyệt (Approved)
**Shows:** Accepted and in-progress transactions
**Statuses:** ACCEPTED, IN_PROGRESS
**Display:** "Đã duyệt - Đang chờ giao hàng" or "Đang giao hàng"
**Action:** View transaction details

### Tab 4: Hoàn Thành (Completed)
**Shows:** Finished transactions (all states)
**Statuses:** REJECTED, COMPLETED, CANCELLED
**Display:** Final status with color coding
**Action:** View transaction details

## 🎨 Status Colors

```
PENDING      → 🟠 Orange (#FFA726)
ACCEPTED     → 🔵 Teal (Primary)
REJECTED     → 🔴 Red
IN_PROGRESS  → 🔷 Cyan
COMPLETED    → 🟢 Green (Success)
CANCELLED    → ⚪ Gray
```

## 🔧 Key Code Features

### State Variables
```dart
List<TransactionModel> _pendingTransactions = [];
List<TransactionModel> _acceptedTransactions = [];
List<TransactionModel> _completedTransactions = [];
bool _isLoadingCart = false;
bool _isLoadingTransactions = false;
```

### Data Loading
```dart
Future<void> _loadCartAndTransactions() async {
  // Loads cart items
  // Loads transactions and filters by status
  // Handles loading and error states
}
```

### Helper Methods
```dart
String _getStatusDisplay(TransactionStatus status)  // Vietnamese labels
Color _getStatusColor(TransactionStatus status)      // Status colors
Widget _buildTransactionCard(TransactionModel tx)    // Card UI
Widget _buildTransactionActionButtons(...)           // Status-specific buttons
```

## 📱 UI Components

### Empty States
- Cart tab: Shopping cart icon + "Chưa có sản phẩm trong giỏ hàng"
- Pending tab: Inbox icon + "Không có đơn hàng chờ duyệt"
- Approved tab: Check circle icon + "Không có đơn hàng đã duyệt"
- Completed tab: Done all icon + "Không có đơn hàng hoàn thành"

### Loading States
CircularProgressIndicator shown while fetching data

### Error Handling
Error message displayed if API call fails

## 🚀 Usage Flow

1. User taps "Đơn hàng" in main menu
2. Cart All Screen opens with 4 tabs
3. Tab 1 (Giỏ hàng): Shows available items to order
4. Tab 2 (Chờ duyệt): Shows pending requests
5. Tab 3 (Đã duyệt): Shows approved/shipping orders
6. Tab 4 (Hoàn thành): Shows completed/cancelled/rejected orders

## 🔌 API Integration

### Currently Using
- MockData for development/testing

### TODO: Replace with Real APIs
```dart
// Cart
final cartResponse = await _cartApiService.getCart();

// Transactions
final txResponse = await _transactionApiService.getMyTransactions();
```

## 📦 Dependencies

- **transaction_model.dart** - Transaction data model
- **transaction_status.dart** - Status enum with conversions
- **transaction_api_service.dart** - API calls
- **cart_api_service.dart** - Cart API calls
- **auth_provider.dart** - Auth token management

## ✅ What Works

✓ 4 tabs with proper navigation
✓ Status filtering for transactions
✓ Empty state displays
✓ Loading indicators
✓ Error handling
✓ Type-safe status enums
✓ Color-coded status badges
✓ Navigation to transaction details
✓ Auth token integration
✓ Responsive layout

## 🔍 Status Translation

| Status | Vietnamese | Where |
|--------|------------|-------|
| PENDING | Chờ duyệt | Tab 2 |
| ACCEPTED | Đã chấp nhận | Tab 3 |
| IN_PROGRESS | Đang giao | Tab 3 |
| COMPLETED | Hoàn thành | Tab 4 |
| REJECTED | Từ chối | Tab 4 |
| CANCELLED | Đã hủy | Tab 4 |

## 📝 File Modified

```
lib/presentation/screens/orders/cart_all_screen.dart
```

## 📚 Related Documentation

See `CART_ALL_SCREEN_IMPLEMENTATION.md` for detailed implementation guide.

---

**Status:** ✅ Ready for testing | ⚠️ Uses MockData | 📋 API calls need implementation

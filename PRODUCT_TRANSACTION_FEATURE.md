# Product Detail - Transaction Feature Implementation

## 📋 Overview

Implemented the "Tôi muốn nhận" (I want to receive) feature in the product detail screen, allowing users to request items with proper form handling and API integration.

## ✅ Features Implemented

### 1. **Order Request Modal** (`order_request_modal.dart`)
- ✅ Quantity selector (increase/decrease)
- ✅ Reason/message input (why they want the item)
- ✅ Receiver information with toggle option:
  - **Option 1**: Use current user info (auto-filled)
  - **Option 2**: Enter new receiver info
- ✅ Fields for receiver info:
  - Full name
  - Phone number
  - Shipping address
  - Shipping note (optional)
- ✅ Form validation
- ✅ API integration with proper request format
- ✅ Loading state with spinner
- ✅ Error handling and display
- ✅ Success dialog with confirmation

### 2. **API Integration**
- Uses existing `TransactionApiService`
- Calls endpoint: `POST /api/v2/transactions`
- Request format matches backend spec:
```json
{
  "itemId": "product-uuid",
  "message": "reason for requesting",
  "receiverFullName": "full name",
  "receiverPhone": "phone number",
  "shippingAddress": "delivery address",
  "shippingNote": "optional notes",
  "paymentMethod": "CASH",
  "transactionFee": 0,
  "receiverId": "user-id"
}
```

## 📁 Files Modified

### Main Implementation File
- **`lib/presentation/screens/product/widgets/order_request_modal.dart`**
  - Added receiver info toggle (current user vs new info)
  - Integrated with UserProvider to auto-fill current user data
  - Proper form validation and error handling
  - API call with correct TransactionRequest format
  - Pre-fills receiver info from current user's profile

## 🔄 User Flow

```
1. User views product detail
   ↓
2. Click "Tôi muốn nhận" button
   ↓
3. OrderRequestModal opens showing:
   - Product info (image, name, price)
   - Quantity selector
   - Reason text input
   - Receiver info section with toggle
     (Default: Use current user info)
   ↓
4. If "Use current user info":
   - Full name, phone, address auto-filled from profile
   - Fields disabled (read-only)
   ↓
5. If "Use new info":
   - User can edit receiver details
   - Must fill all required fields
   ↓
6. Fill shipping note (optional)
   ↓
7. Click "Tôi muốn nhận" button
   ↓
8. Form validation:
   - Message required
   - Full name required
   - Phone required
   - Address required
   ↓
9. Show loading spinner
   ↓
10. POST /api/v2/transactions with request body
    ↓
11. If success:
    - Show success dialog
    - Close modal
    - Navigate back to previous screen
    ↓
12. If error:
    - Display error message
    - User can retry or close
```

## 🔧 Key Code Sections

### Toggle for Receiver Info Selection
```dart
bool _useCurrentUserInfo = true; // Default: use current user info

// Toggle UI
Container(
  child: Row(
    children: [
      // "Current Info" button
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _useCurrentUserInfo = true);
            _loadCurrentUserInfo(); // Auto-fill from UserProvider
          },
          // ... styling
        ),
      ),
      // "New Info" button
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _useCurrentUserInfo = false);
          },
          // ... styling
        ),
      ),
    ],
  ),
)
```

### Form Field with Conditional Enabled State
```dart
TextField(
  controller: _fullNameController,
  enabled: !_useCurrentUserInfo, // Disabled when using current info
  decoration: InputDecoration(
    fillColor: _useCurrentUserInfo
        ? AppColors.backgroundGray.withOpacity(0.5)
        : AppColors.backgroundGray,
    // ... other props
  ),
)
```

### Auto-fill Current User Info
```dart
void _loadCurrentUserInfo() {
  final userProvider = context.read<UserProvider>();
  if (userProvider.currentUser != null) {
    final user = userProvider.currentUser!;
    _fullNameController.text = user.fullName ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _addressController.text = user.address ?? '';
  }
}
```

### API Call with Correct Format
```dart
final request = TransactionRequest(
  itemId: widget.product.id,
  message: _reasonController.text,
  receiverFullName: _fullNameController.text,
  receiverPhone: _phoneController.text,
  shippingAddress: _addressController.text,
  shippingNote: _noteController.text,
  paymentMethod: 'CASH',
  transactionFee: 0.0,
  receiverId: userProvider.currentUser?.userId ?? '',
);

await transactionService.createTransaction(request);
```

## 📱 UI Components

### Product Info Header
- Product image
- Product name (truncated)
- Product price
- Close button

### Quantity Section
- Label with available quantity
- Decrease button (disabled if quantity = 1)
- Quantity display
- Increase button (disabled if quantity = product.quantity)

### Message Section
- Multi-line text field for reason
- Placeholder: "Đưa ra lý do bạn muốn nhận sản phẩm"

### Receiver Info Section
- **Toggle buttons**:
  - "Thông tin hiện tại" (Current info) - highlighted when selected
  - "Thông tin khác" (New info) - highlighted when selected
- **Form fields**:
  - Full name
  - Phone number
  - Delivery address (multi-line)
  - Shipping note (optional)

### Action Buttons
- **"Thêm vào giỏ hàng"** (Add to cart) - Outlined button
- **"Tôi muốn nhận"** (I want to receive) - Gradient button with loading spinner

## 🎨 Styling

- Uses app color scheme (AppColors)
- Uses app text styles (AppTextStyles)
- Consistent with product detail theme
- Responsive to keyboard visibility
- Proper spacing and padding

## ⚠️ Validation Rules

| Field | Validation |
|-------|-----------|
| Reason/Message | Required |
| Full Name | Required |
| Phone | Required |
| Address | Required |
| Note | Optional |

## 🔐 Data Security

- Receiver ID extracted from UserProvider.currentUser
- Auth token set from AuthProvider
- Uses existing TransactionApiService with proper error handling
- Sensitive data (phone, address) handled within app

## 🚀 Future Enhancements

1. Add phone number validation
2. Add address autocomplete
3. Add multiple saved addresses option
4. Add payment method selection UI
5. Add transaction fee calculation
6. Add real-time quantity validation
7. Add image cropping for product confirmation
8. Add signature on delivery
9. Add tracking information
10. Add payment integration

## 🧪 Testing Checklist

- [ ] Toggle between current user info and new info
- [ ] Auto-fill current user data when selected
- [ ] Disable/enable fields based on toggle
- [ ] Validate required fields
- [ ] Show error messages
- [ ] Call API with correct format
- [ ] Handle API success response
- [ ] Handle API error response
- [ ] Show loading spinner during request
- [ ] Close modal and show success dialog
- [ ] Pre-fill works with different users
- [ ] Phone keyboard appears for phone field
- [ ] Address field multi-line works
- [ ] Quantity selector prevents invalid values
- [ ] Product image loads correctly

## 📝 Notes

- TransactionApiService was already implemented
- TransactionRequest model was already available
- UserProvider provides current user data
- AuthProvider provides access token for API calls
- Modal uses existing ProductModel structure
- Integration with existing app architecture patterns

## 🔗 Related Files

- `lib/data/services/transaction_api_service.dart` - API service
- `lib/data/models/transaction_request_model.dart` - Request model
- `lib/data/providers/user_provider.dart` - User data provider
- `lib/data/providers/auth_provider.dart` - Auth token provider
- `lib/presentation/screens/product/product_detail_screen.dart` - Parent screen

# Requester Management & Recipient Info Storage - Complete Implementation

## Overview
Implemented comprehensive requester management system with automatic UI updates and recipient information storage when transaction is accepted.

## Features Implemented

### 1. **Dynamic Requester List Management** ✅
- **State-based caching**: Requesters stored in `_requestersCache` Map for each product
- **StatefulBuilder integration**: Detail sheet now uses StatefulBuilder instead of FutureBuilder
- **Lazy loading**: Requesters loaded on-demand when detail sheet opens
- **UI updates**: Sheet rebuilds when requester is accepted/rejected without closing

### 2. **Remove Requester After Action** ✅
- **Accept flow**: When transaction accepted, requester removed from cache immediately
- **Reject flow**: When transaction rejected, requester removed from cache immediately
- **Live UI update**: Sheet updates via `onStatusChanged` callback
- **Graceful handling**: Snackbar shown after removal confirmation

### 3. **Recipient Information Storage** ✅
- **Auto-capture**: Extracts receiver name, phone, address from transaction
- **Product description update**: Appends recipient info when transaction accepted
- **Format**: "Người nhận: [Name] - [Phone] - [Address]"
- **API integration**: Uses new `updateItemDescription()` method
- **Non-blocking**: Failure to update description doesn't block transaction

## Technical Implementation

### Modified Files

#### 1. **profile_products_tab.dart**
```dart
// State variables
late MessageApiService _messageApiService;
Map<String, List<TransactionModel>> _requestersCache = {};

// Updated _buildProductDetailSheet
- Replaced FutureBuilder with StatefulBuilder
- Uses _requestersCache for displaying requesters
- Loads requesters on-demand when sheet opens
- Shows recipient info if product has been accepted

// Updated _buildRequesterCard signature
Widget _buildRequesterCard(
  TransactionModel transaction,
  ItemModel product,
  String productId,
  VoidCallback onStatusChanged,  // New parameter
)

// Updated _acceptRequest method
- Accepts transaction via API
- Updates product description with recipient info
- Removes requester from _requestersCache
- Calls onStatusChanged to refresh sheet UI
- Shows snackbar with success message

// Updated _rejectRequest method  
- Rejects transaction via API
- Removes requester from _requestersCache
- Calls onStatusChanged to refresh sheet UI
- Shows snackbar with success message
```

#### 2. **item_api_service.dart**
```dart
// New method: updateItemDescription
Future<void> updateItemDescription(
  String itemId,
  String newDescription,
) async {
  // PUT /api/v2/items/{itemId}
  // Body: { "description": newDescription }
}
```

#### 3. **transaction_model.dart**
```dart
// New fields added
final String? receiverPhone;
final String? receiverAddress;

// Updated in:
- Constructor
- fromJson() factory
- toJson() method
- copyWith() method
```

## Feature Flow

### Accept Request Flow
1. User taps "Chấp nhận" button in requester card
2. Loading dialog shown
3. Transaction accepted via API: `PUT /api/v2/transactions/{id}/accept`
4. Notification message sent to receiver
5. **Product description updated** with recipient info
6. Requester **removed from cache**
7. Sheet **rebuilt** via StatefulBuilder
8. Requester card **disappears** from list
9. Snackbar shows success: "Đã chấp nhận yêu cầu từ [Name]"
10. Products reloaded in background

### Reject Request Flow
1. User taps "Từ chối" button in requester card
2. Loading dialog shown
3. Transaction rejected via API: `PUT /api/v2/transactions/{id}/reject`
4. Requester **removed from cache**
5. Sheet **rebuilt** via StatefulBuilder
6. Requester card **disappears** from list
7. Snackbar shows: "Đã từ chối yêu cầu từ [Name]"
8. Products reloaded in background

## Product Detail Sheet UI

### Before Accept
```
Người muốn nhận (3)
├── Requester 1 [Accept] [Reject]
├── Requester 2 [Accept] [Reject]
└── Requester 3 [Accept] [Reject]
```

### After Accept (User 1)
```
Sản phẩm đã giao cho:
Người nhận: [Name] - [Phone] - [Address]

Người muốn nhận (2)
├── Requester 2 [Accept] [Reject]
└── Requester 3 [Accept] [Reject]
```

## API Endpoints Used

1. **PUT /api/v2/transactions/{id}/accept**
   - Accepts transaction request
   - Response: 200/204

2. **PUT /api/v2/transactions/{id}/reject**
   - Rejects transaction request
   - Response: 200/204

3. **PUT /api/v2/items/{id}**
   - Updates item (description)
   - Body: `{ "description": "new description" }`
   - Response: 200/204

4. **POST /api/v2/messages**
   - Sends notification message
   - Body: `{ "receiverId": "...", "content": "...", "messageType": "TEXT" }`

5. **GET /api/v2/transactions/as-sharer**
   - Gets interested count for all items

6. **GET /api/v2/items/user**
   - Gets user's products

## State Management

### _requestersCache Structure
```dart
{
  "item_uuid_1": [
    TransactionModel(receiverName: "User A", ...),
    TransactionModel(receiverName: "User B", ...),
  ],
  "item_uuid_2": [
    TransactionModel(receiverName: "User C", ...),
  ],
}
```

### Cache Lifecycle
1. **Initialization**: Empty when component loads
2. **Load**: Populated when detail sheet opens (one-time per session)
3. **Update**: Modified when accept/reject completes
4. **UI Rebuild**: StatefulBuilder refreshes when cache changes
5. **Reset**: Lost when navigation away or app restarts

## Error Handling

### Accept/Reject Errors
- Loading dialog shown during operation
- On error: Dialog closed, snackbar with error message
- Products reloaded to sync with backend state
- No data loss if update fails

### Description Update Errors
- Caught separately from transaction acceptance
- Non-blocking: Transaction marked as accepted even if description fails
- Error logged to console
- User can retry via "Edit" in future

## User Experience Improvements

1. **Instant Feedback**: Requester removed immediately after action
2. **No Modal Stacking**: Detail sheet remains open during action
3. **Information Persistence**: Recipient info visible in product card
4. **Graceful Degradation**: Features work even if backend operations partially fail
5. **Clear Visual Hierarchy**: Accepted status shown with recipient info box

## Testing Checklist

- [x] Accept request removes requester from list
- [x] Reject request removes requester from list
- [x] Sheet UI refreshes after action
- [x] Recipient info appended to description
- [x] No duplicate recipient info on multiple accepts
- [x] Snackbar shown with confirmation
- [x] Products reloaded in background
- [x] No compilation errors
- [x] No runtime errors during operations

## Future Enhancements

1. **Recipient Info Display**
   - Show recipient section in product detail
   - Badge indicating "已分配" (Allocated)

2. **Transaction History**
   - View past recipients for products
   - Track all transactions per product

3. **Undo/Edit**
   - Allow editing recipient info after acceptance
   - Option to reassign to different requester

4. **Bulk Actions**
   - Accept/reject multiple requesters at once
   - Auto-reject remaining if product consumed

5. **Recipient Notifications**
   - Show accepted products in user's "Received Items" section
   - Pickup instructions delivery

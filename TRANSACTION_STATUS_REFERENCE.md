# Transaction Status Reference

## 📋 Complete Transaction Statuses

### **Backend Official Statuses (6 total)**

Based on backend Java enum: `TransactionStatus`

| Status | Code | Description | Who Can Change | Transitions |
|--------|------|-------------|-----------------|-------------|
| **PENDING** | `PENDING` | Initial status when receiver requests item | Sharer | → ACCEPTED, REJECTED, or CANCELLED |
| **ACCEPTED** | `ACCEPTED` | Sharer accepts the transaction request | Sharer | → IN_PROGRESS, COMPLETED |
| **REJECTED** | `REJECTED` | Sharer rejects the transaction request | Sharer | Final state (no transitions) |
| **IN_PROGRESS** | `IN_PROGRESS` | Transaction is in progress (payment/delivery) | Sharer | → COMPLETED |
| **COMPLETED** | `COMPLETED` | Transaction successfully completed | Sharer | Final state (no transitions) |
| **CANCELLED** | `CANCELLED` | Transaction was cancelled | Receiver (only when PENDING) | Final state (no transitions) |

## 🔄 Valid State Transitions

```
PENDING
├── → ACCEPTED (Sharer accepts)
│   ├── → IN_PROGRESS (Sharer starts delivery)
│   │   └── → COMPLETED (Sharer completes)
│   └── → COMPLETED (Direct completion)
├── → REJECTED (Sharer rejects)
└── → CANCELLED (Receiver cancels - only from PENDING)
```

## 📱 Status Display in UI

### Transaction Status Badges

```dart
enum TransactionStatus {
  pending,    // "Chờ xác nhận"  - Yellow/Orange
  accepted,   // "Đã chấp nhận"  - Blue
  inProgress, // "Đang giao"     - Cyan
  completed,  // "Hoàn thành"    - Green
  rejected,   // "Từ chối"       - Red
  cancelled,  // "Đã hủy"        - Gray
}

// Display names (Vietnamese)
Map<TransactionStatus, String> statusLabels = {
  TransactionStatus.pending: 'Chờ xác nhận',
  TransactionStatus.accepted: 'Đã chấp nhận',
  TransactionStatus.inProgress: 'Đang giao',
  TransactionStatus.completed: 'Hoàn thành',
  TransactionStatus.rejected: 'Từ chối',
  TransactionStatus.cancelled: 'Đã hủy',
};

// Colors
Map<TransactionStatus, Color> statusColors = {
  TransactionStatus.pending: Colors.orange,
  TransactionStatus.accepted: Colors.blue,
  TransactionStatus.inProgress: Colors.cyan,
  TransactionStatus.completed: Colors.green,
  TransactionStatus.rejected: Colors.red,
  TransactionStatus.cancelled: Colors.grey,
};
```

## ⚠️ Important Notes

1. **Case Sensitivity**: Backend uses UPPERCASE (PENDING, ACCEPTED, etc.)
2. **Receiver Can Only Cancel**: Only when transaction is still PENDING
3. **Sharer Controls**: ACCEPT, REJECT, complete the transaction
4. **Final States**: REJECTED, COMPLETED, CANCELLED cannot transition further
5. **Mock Data vs Backend**: Mock data uses lowercase and includes "verified" status which doesn't exist in backend

## 🔐 Permission Rules

| Action | Who Can Do | Conditions |
|--------|-----------|-----------|
| ACCEPT | Sharer | Transaction is PENDING |
| REJECT | Sharer | Transaction is PENDING |
| START (IN_PROGRESS) | Sharer | Transaction is ACCEPTED |
| COMPLETE | Sharer | Transaction is ACCEPTED or IN_PROGRESS |
| CANCEL | Receiver | Transaction is PENDING |

## 📊 Transaction Lifecycle Example

```
Day 1: Receiver requests item
  Status: PENDING
  Receiver Info: Full name, phone, address saved
  Sharer notification: New request received

Day 2: Sharer reviews and accepts
  Status: ACCEPTED
  Receiver notification: Request accepted

Day 2-3: Sharer prepares and ships
  Status: IN_PROGRESS
  Both notified: Item is on the way

Day 4: Item delivered
  Status: COMPLETED
  Both notified: Transaction completed
  Review/Rating enabled
```

## 🔗 Related Files

- **Backend Enum**: `shareo/src/main/java/com/uit/shario/modules/transaction/domain/valueobject/TransactionStatus.java`
- **Flutter Model**: `lib/data/models/transaction_model.dart`
- **Database Schema**: `shareo/docs/database-diagram.dbml`
- **API Service**: `lib/data/services/transaction_api_service.dart`
- **Update Use Case**: `shareo/src/main/java/com/uit/shario/modules/transaction/application/usecase/UpdateTransactionStatusUseCase.java`

## 🚀 Next Steps for Flutter Implementation

1. ✅ Create TransactionStatus enum to match backend
2. ✅ Update TransactionModel to use enum instead of String
3. ✅ Create status display helpers (labels, colors, icons)
4. ✅ Implement transaction status update API calls
5. ✅ Update transaction list UI to show correct status badges
6. ✅ Add status transition rules validation in UI
7. ✅ Add notification support for status changes
8. ✅ Add transaction history/timeline view

## 📝 API Endpoints Related to Status

- `POST /api/v2/transactions` - Create transaction (Status: PENDING)
- `PUT /api/v2/transactions/{id}/status` - Update transaction status
  - Accept: `{ "status": "ACCEPTED" }`
  - Reject: `{ "status": "REJECTED" }`
  - Complete: `{ "status": "COMPLETED" }`
- `GET /api/v2/transactions` - List transactions with status
- `GET /api/v2/transactions/{id}` - Get transaction details with status

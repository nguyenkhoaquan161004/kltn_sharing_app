/// Transaction Status Enum
/// Matches backend: shareo/src/main/java/com/uit/shario/modules/transaction/domain/valueobject/TransactionStatus.java
enum TransactionStatus {
  pending, // Chờ xác nhận - Receiver requested, waiting for sharer acceptance
  accepted, // Đã chấp nhận - Sharer accepted the request
  rejected, // Từ chối - Sharer rejected the request
  inProgress, // Đang giao - Transaction in progress (payment/delivery)
  completed, // Hoàn thành - Transaction successfully completed
  cancelled, // Đã hủy - Transaction was cancelled by receiver
}

extension TransactionStatusExtension on TransactionStatus {
  /// Convert enum to backend string format (UPPERCASE)
  String toBackendString() {
    switch (this) {
      case TransactionStatus.pending:
        return 'PENDING';
      case TransactionStatus.accepted:
        return 'ACCEPTED';
      case TransactionStatus.rejected:
        return 'REJECTED';
      case TransactionStatus.inProgress:
        return 'IN_PROGRESS';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.cancelled:
        return 'CANCELLED';
    }
  }

  /// Convert backend string to enum
  static TransactionStatus fromBackendString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return TransactionStatus.pending;
      case 'ACCEPTED':
        return TransactionStatus.accepted;
      case 'REJECTED':
        return TransactionStatus.rejected;
      case 'IN_PROGRESS':
        return TransactionStatus.inProgress;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'CANCELLED':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  /// Get Vietnamese display name
  String getDisplayName() {
    switch (this) {
      case TransactionStatus.pending:
        return 'Chờ xác nhận';
      case TransactionStatus.accepted:
        return 'Đã chấp nhận';
      case TransactionStatus.rejected:
        return 'Từ chối';
      case TransactionStatus.inProgress:
        return 'Đang giao';
      case TransactionStatus.completed:
        return 'Hoàn thành';
      case TransactionStatus.cancelled:
        return 'Đã hủy';
    }
  }

  /// Get status color (for UI display)
  String getColorHex() {
    switch (this) {
      case TransactionStatus.pending:
        return '#FFA726'; // Orange
      case TransactionStatus.accepted:
        return '#42A5F5'; // Blue
      case TransactionStatus.rejected:
        return '#EF5350'; // Red
      case TransactionStatus.inProgress:
        return '#29B6F6'; // Cyan
      case TransactionStatus.completed:
        return '#66BB6A'; // Green
      case TransactionStatus.cancelled:
        return '#BDBDBD'; // Gray
    }
  }

  /// Check if transaction can be transitioned to new status
  bool canTransitionTo(TransactionStatus newStatus) {
    switch (this) {
      case TransactionStatus.pending:
        // From PENDING can go to: ACCEPTED, REJECTED, CANCELLED
        return newStatus == TransactionStatus.accepted ||
            newStatus == TransactionStatus.rejected ||
            newStatus == TransactionStatus.cancelled;

      case TransactionStatus.accepted:
        // From ACCEPTED can go to: IN_PROGRESS, COMPLETED
        return newStatus == TransactionStatus.inProgress ||
            newStatus == TransactionStatus.completed;

      case TransactionStatus.inProgress:
        // From IN_PROGRESS can go to: COMPLETED
        return newStatus == TransactionStatus.completed;

      case TransactionStatus.rejected:
      case TransactionStatus.completed:
      case TransactionStatus.cancelled:
        // Final states, no transitions
        return false;
    }
  }

  /// Check if this is a final state
  bool isFinalState() {
    return this == TransactionStatus.rejected ||
        this == TransactionStatus.completed ||
        this == TransactionStatus.cancelled;
  }

  /// Check if sharer can perform action (only if transaction not in final state)
  bool canSharerAct() {
    return this == TransactionStatus.pending ||
        this == TransactionStatus.accepted ||
        this == TransactionStatus.inProgress;
  }

  /// Check if receiver can cancel (only if PENDING)
  bool canReceiverCancel() {
    return this == TransactionStatus.pending;
  }
}

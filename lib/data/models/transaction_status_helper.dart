import 'package:flutter/material.dart';
import 'transaction_status.dart';

/// Helper class for transaction status UI display
class TransactionStatusHelper {
  static const Map<TransactionStatus, String> statusLabels = {
    TransactionStatus.pending: 'Chờ xác nhận',
    TransactionStatus.accepted: 'Đã chấp nhận',
    TransactionStatus.rejected: 'Từ chối',
    TransactionStatus.inProgress: 'Đang giao',
    TransactionStatus.completed: 'Hoàn thành',
    TransactionStatus.cancelled: 'Đã hủy',
  };

  static const Map<TransactionStatus, Color> statusColors = {
    TransactionStatus.pending: Color(0xFFFFA726), // Orange
    TransactionStatus.accepted: Color(0xFF42A5F5), // Blue
    TransactionStatus.rejected: Color(0xFFEF5350), // Red
    TransactionStatus.inProgress: Color(0xFF29B6F6), // Cyan
    TransactionStatus.completed: Color(0xFF66BB6A), // Green
    TransactionStatus.cancelled: Color(0xFFBDBDBD), // Gray
  };

  static const Map<TransactionStatus, Color> statusBackgroundColors = {
    TransactionStatus.pending: Color(0xFFFFE0B2), // Light Orange
    TransactionStatus.accepted: Color(0xFFBBDEFB), // Light Blue
    TransactionStatus.rejected: Color(0xFFEF9A9A), // Light Red
    TransactionStatus.inProgress: Color(0xFFB3E5FC), // Light Cyan
    TransactionStatus.completed: Color(0xFFC8E6C9), // Light Green
    TransactionStatus.cancelled: Color(0xFFE0E0E0), // Light Gray
  };

  static const Map<TransactionStatus, IconData> statusIcons = {
    TransactionStatus.pending: Icons.schedule,
    TransactionStatus.accepted: Icons.check_circle,
    TransactionStatus.rejected: Icons.cancel,
    TransactionStatus.inProgress: Icons.local_shipping,
    TransactionStatus.completed: Icons.done_all,
    TransactionStatus.cancelled: Icons.block,
  };

  /// Get display label for status
  static String getLabel(TransactionStatus status) {
    return statusLabels[status] ?? 'Unknown';
  }

  /// Get color for status
  static Color getColor(TransactionStatus status) {
    return statusColors[status] ?? Colors.grey;
  }

  /// Get background color for status
  static Color getBackgroundColor(TransactionStatus status) {
    return statusBackgroundColors[status] ?? Colors.grey.shade100;
  }

  /// Get icon for status
  static IconData getIcon(TransactionStatus status) {
    return statusIcons[status] ?? Icons.info;
  }

  /// Build status badge widget
  static Widget buildStatusBadge(
    TransactionStatus status, {
    bool compact = false,
  }) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getBackgroundColor(status),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: getColor(status),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getIcon(status),
            size: compact ? 14 : 16,
            color: getColor(status),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            getLabel(status),
            style: TextStyle(
              color: getColor(status),
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status timeline step
  static Widget buildTimelineStep(
    TransactionStatus status, {
    bool isCompleted = false,
    bool isCurrent = false,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isCurrent
                ? getColor(status)
                : Colors.grey.shade300,
            border: isCurrent
                ? Border.all(
                    color: getColor(status),
                    width: 3,
                  )
                : null,
          ),
          child: Icon(
            getIcon(status),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          getLabel(status),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCompleted || isCurrent ? getColor(status) : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Get status description (for detail view)
  static String getDescription(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Yêu cầu đã được gửi. Đang chờ người cho phồng duyệt.';
      case TransactionStatus.accepted:
        return 'Người cho đã chấp nhận yêu cầu của bạn.';
      case TransactionStatus.rejected:
        return 'Người cho đã từ chối yêu cầu của bạn.';
      case TransactionStatus.inProgress:
        return 'Sản phẩm đang được giao đến bạn.';
      case TransactionStatus.completed:
        return 'Giao dịch hoàn thành thành công. Cảm ơn bạn!';
      case TransactionStatus.cancelled:
        return 'Giao dịch đã bị hủy.';
    }
  }

  /// Check if user can perform action based on status
  static bool canAcceptRejectTransaction(TransactionStatus status) {
    return status == TransactionStatus.pending;
  }

  static bool canStartDelivery(TransactionStatus status) {
    return status == TransactionStatus.accepted;
  }

  static bool canCompleteTransaction(TransactionStatus status) {
    return status == TransactionStatus.accepted ||
        status == TransactionStatus.inProgress;
  }

  static bool canCancelTransaction(TransactionStatus status) {
    return status == TransactionStatus.pending;
  }

  /// Get next possible statuses
  static List<TransactionStatus> getNextPossibleStatuses(
      TransactionStatus status) {
    final next = <TransactionStatus>[];

    switch (status) {
      case TransactionStatus.pending:
        next.addAll([
          TransactionStatus.accepted,
          TransactionStatus.rejected,
          TransactionStatus.cancelled,
        ]);
        break;
      case TransactionStatus.accepted:
        next.addAll([
          TransactionStatus.inProgress,
          TransactionStatus.completed,
        ]);
        break;
      case TransactionStatus.inProgress:
        next.add(TransactionStatus.completed);
        break;
      case TransactionStatus.rejected:
      case TransactionStatus.completed:
      case TransactionStatus.cancelled:
        // No next states
        break;
    }

    return next;
  }
}

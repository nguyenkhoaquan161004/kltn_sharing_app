/// Model for transaction statistics
class TransactionStats {
  final int totalShared;
  final int totalReceived;
  final int completedShared;
  final int completedReceived;
  final int pendingShared;
  final int pendingReceived;
  final int acceptedShared;
  final int acceptedReceived;

  TransactionStats({
    required this.totalShared,
    required this.totalReceived,
    required this.completedShared,
    required this.completedReceived,
    required this.pendingShared,
    required this.pendingReceived,
    required this.acceptedShared,
    required this.acceptedReceived,
  });

  /// Factory constructor to create TransactionStats from JSON
  factory TransactionStats.fromJson(Map<String, dynamic> json) {
    return TransactionStats(
      totalShared: json['totalShared'] as int? ?? 0,
      totalReceived: json['totalReceived'] as int? ?? 0,
      completedShared: json['completedShared'] as int? ?? 0,
      completedReceived: json['completedReceived'] as int? ?? 0,
      pendingShared: json['pendingShared'] as int? ?? 0,
      pendingReceived: json['pendingReceived'] as int? ?? 0,
      acceptedShared: json['acceptedShared'] as int? ?? 0,
      acceptedReceived: json['acceptedReceived'] as int? ?? 0,
    );
  }

  /// Convert TransactionStats to JSON
  Map<String, dynamic> toJson() => {
        'totalShared': totalShared,
        'totalReceived': totalReceived,
        'completedShared': completedShared,
        'completedReceived': completedReceived,
        'pendingShared': pendingShared,
        'pendingReceived': pendingReceived,
        'acceptedShared': acceptedShared,
        'acceptedReceived': acceptedReceived,
      };
}

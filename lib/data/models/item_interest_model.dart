class ItemInterestModel {
  final int interestId;
  final int itemId;
  final int userId;
  final String reason;
  final String status; // 'interested', 'accepted', 'rejected', 'completed'
  final DateTime createdAt;

  ItemInterestModel({
    required this.interestId,
    required this.itemId,
    required this.userId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory ItemInterestModel.fromJson(Map<String, dynamic> json) {
    return ItemInterestModel(
      interestId: json['interest_id'] ?? 0,
      itemId: json['item_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'interested',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interest_id': interestId,
      'item_id': itemId,
      'user_id': userId,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ItemInterestModel copyWith({
    int? interestId,
    int? itemId,
    int? userId,
    String? reason,
    String? status,
    DateTime? createdAt,
  }) {
    return ItemInterestModel(
      interestId: interestId ?? this.interestId,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

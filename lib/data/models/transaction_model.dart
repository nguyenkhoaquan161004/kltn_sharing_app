class TransactionModel {
  final int transactionId;
  final int itemId;
  final int sharerId;
  final int receiverId;
  final String status; // 'pending', 'completed', 'cancelled', 'verified'
  final bool paymentVerified;
  final String? proofImage;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  TransactionModel({
    required this.transactionId,
    required this.itemId,
    required this.sharerId,
    required this.receiverId,
    required this.status,
    required this.paymentVerified,
    this.proofImage,
    required this.createdAt,
    this.confirmedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transaction_id'] ?? 0,
      itemId: json['item_id'] ?? 0,
      sharerId: json['sharer_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      status: json['status'] ?? 'pending',
      paymentVerified: json['payment_verified'] ?? false,
      proofImage: json['proof_image'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'item_id': itemId,
      'sharer_id': sharerId,
      'receiver_id': receiverId,
      'status': status,
      'payment_verified': paymentVerified,
      if (proofImage != null) 'proof_image': proofImage,
      'created_at': createdAt.toIso8601String(),
      if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    int? transactionId,
    int? itemId,
    int? sharerId,
    int? receiverId,
    String? status,
    bool? paymentVerified,
    String? proofImage,
    DateTime? createdAt,
    DateTime? confirmedAt,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      itemId: itemId ?? this.itemId,
      sharerId: sharerId ?? this.sharerId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      proofImage: proofImage ?? this.proofImage,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}

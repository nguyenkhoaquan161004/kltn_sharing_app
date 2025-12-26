import 'transaction_status.dart';

class TransactionModel {
  final int transactionId;
  final String? transactionIdUuid; // Original UUID from API
  final int itemId;
  final String? itemIdUuid; // Original UUID from API for item
  final int sharerId;
  final String? sharerIdUuid; // Original UUID from API for sharer
  final int receiverId;
  final String? receiverIdUuid; // Original UUID from API for receiver
  final TransactionStatus status;
  final bool paymentVerified;
  final String? proofImage;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  // Additional fields from API
  final String? itemName;
  final String? itemImageUrl;
  final String? sharerName;
  final String? sharerAvatar;
  final String? receiverName;
  final String? message;
  final int? quantity;
  final double? transactionFee;

  TransactionModel({
    required this.transactionId,
    this.transactionIdUuid,
    required this.itemId,
    this.itemIdUuid,
    required this.sharerId,
    this.sharerIdUuid,
    required this.receiverId,
    this.receiverIdUuid,
    required this.status,
    required this.paymentVerified,
    this.proofImage,
    required this.createdAt,
    this.confirmedAt,
    this.itemName,
    this.itemImageUrl,
    this.sharerName,
    this.sharerAvatar,
    this.receiverName,
    this.message,
    this.quantity = 1,
    this.transactionFee = 0.0,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Handle UUID strings by converting to int for compatibility
    int parseId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          // If it's a UUID string, use hash code
          return value.hashCode;
        }
      }
      return 0;
    }

    return TransactionModel(
      // API returns 'id' for transaction ID (UUID)
      transactionId: parseId(
          json['id'] ?? json['transactionId'] ?? json['transaction_id']),
      // Store original UUID if available - check both 'id' and 'transactionId' fields
      transactionIdUuid: (json['id'] is String)
          ? json['id']
          : (json['transactionId'] is String)
              ? json['transactionId']
              : null,
      // API returns 'itemId' (UUID)
      itemId: parseId(json['itemId'] ?? json['item_id']),
      // Store original item UUID if available - check both field names
      itemIdUuid: (json['itemId'] is String)
          ? json['itemId']
          : (json['item_id'] is String)
              ? json['item_id']
              : null,
      // API returns 'sharerId' (UUID)
      sharerId: parseId(json['sharerId'] ?? json['sharer_id']),
      // Store original sharer UUID if available - check both field names
      sharerIdUuid: (json['sharerId'] is String)
          ? json['sharerId']
          : (json['sharer_id'] is String)
              ? json['sharer_id']
              : null,
      // API returns 'receiverId' (UUID)
      receiverId: parseId(json['receiverId'] ?? json['receiver_id']),
      // Store original receiver UUID if available - check both field names
      receiverIdUuid: (json['receiverId'] is String)
          ? json['receiverId']
          : (json['receiver_id'] is String)
              ? json['receiver_id']
              : null,
      status: TransactionStatusExtension.fromBackendString(
          json['status'] ?? 'PENDING'),
      // Payment info is nested in API response
      paymentVerified: json['paymentVerified'] ??
          json['payment_verified'] ??
          json['paymentInfo']?['paymentVerified'] ??
          false,
      proofImage: json['proofImage'] ??
          json['proof_image'] ??
          json['paymentInfo']?['proofImage'],
      createdAt: DateTime.parse(json['createdAt'] ??
          json['created_at'] ??
          DateTime.now().toIso8601String()),
      confirmedAt: (json['confirmedAt'] ?? json['confirmed_at']) != null
          ? DateTime.parse(json['confirmedAt'] ?? json['confirmed_at'])
          : null,
      itemName: json['itemName'] ?? json['item_name'],
      itemImageUrl: json['itemImageUrl'] ??
          json['item_image_url'] ??
          json['imageUrl'] ??
          json['image_url'],
      sharerName: json['sharerName'] ?? json['sharer_name'],
      sharerAvatar: json['sharerAvatar'] ??
          json['sharer_avatar'] ??
          json['userAvatar'] ??
          json['user_avatar'],
      receiverName: json['receiverName'] ?? json['receiver_name'],
      message: json['message'],
      quantity: json['quantity'] ?? 1,
      transactionFee: (json['paymentInfo']?['transactionFee'] ??
              json['transactionFee'] ??
              0)
          .toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'itemId': itemId,
      'sharerId': sharerId,
      'receiverId': receiverId,
      'status': status.toBackendString(),
      'paymentVerified': paymentVerified,
      if (proofImage != null) 'proofImage': proofImage,
      'createdAt': createdAt.toIso8601String(),
      if (confirmedAt != null) 'confirmedAt': confirmedAt!.toIso8601String(),
      if (itemName != null) 'itemName': itemName,
      if (itemImageUrl != null) 'itemImageUrl': itemImageUrl,
      if (sharerName != null) 'sharerName': sharerName,
      if (sharerAvatar != null) 'sharerAvatar': sharerAvatar,
      if (receiverName != null) 'receiverName': receiverName,
      if (message != null) 'message': message,
      'quantity': quantity,
      'transactionFee': transactionFee,
    };
  }

  TransactionModel copyWith({
    int? transactionId,
    String? transactionIdUuid,
    int? itemId,
    String? itemIdUuid,
    int? sharerId,
    String? sharerIdUuid,
    int? receiverId,
    String? receiverIdUuid,
    TransactionStatus? status,
    bool? paymentVerified,
    String? proofImage,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? itemName,
    String? itemImageUrl,
    String? sharerName,
    String? sharerAvatar,
    String? receiverName,
    String? message,
    int? quantity,
    double? transactionFee,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      transactionIdUuid: transactionIdUuid ?? this.transactionIdUuid,
      itemId: itemId ?? this.itemId,
      itemIdUuid: itemIdUuid ?? this.itemIdUuid,
      sharerId: sharerId ?? this.sharerId,
      sharerIdUuid: sharerIdUuid ?? this.sharerIdUuid,
      receiverId: receiverId ?? this.receiverId,
      receiverIdUuid: receiverIdUuid ?? this.receiverIdUuid,
      status: status ?? this.status,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      proofImage: proofImage ?? this.proofImage,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      itemName: itemName ?? this.itemName,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      sharerName: sharerName ?? this.sharerName,
      sharerAvatar: sharerAvatar ?? this.sharerAvatar,
      receiverName: receiverName ?? this.receiverName,
      message: message ?? this.message,
      quantity: quantity ?? this.quantity,
      transactionFee: transactionFee ?? this.transactionFee,
    );
  }
}

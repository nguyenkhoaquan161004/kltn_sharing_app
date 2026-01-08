class TransactionRequest {
  final String itemId;
  final String message;
  final int? quantity;
  final DateTime? preferredReceiveTime;
  final String receiverFullName;
  final String receiverPhone;
  final String shippingAddress;
  final String shippingNote;
  final String paymentMethod;
  final double transactionFee;
  final String receiverId;

  TransactionRequest({
    required this.itemId,
    required this.message,
    this.quantity,
    this.preferredReceiveTime,
    required this.receiverFullName,
    required this.receiverPhone,
    required this.shippingAddress,
    required this.shippingNote,
    this.paymentMethod = 'CASH',
    this.transactionFee = 0.0,
    required this.receiverId,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'message': message,
      if (quantity != null) 'quantity': quantity,
      if (preferredReceiveTime != null)
        'preferredReceiveTime': preferredReceiveTime?.toIso8601String(),
      'receiverFullName': receiverFullName,
      'receiverPhone': receiverPhone,
      'shippingAddress': shippingAddress,
      'shippingNote': shippingNote,
      'paymentMethod': paymentMethod,
      'transactionFee': transactionFee,
      'receiverId': receiverId,
    };
  }
}

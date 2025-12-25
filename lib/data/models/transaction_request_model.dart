class TransactionRequest {
  final String itemId;
  final String message;
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

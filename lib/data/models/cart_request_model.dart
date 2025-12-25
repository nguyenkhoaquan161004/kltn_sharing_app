/// Model for Cart API request
class CartRequest {
  final String itemId;
  final int quantity;

  CartRequest({
    required this.itemId,
    required this.quantity,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
    };
  }
}

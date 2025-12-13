class ItemModel {
  final int itemId;
  final int userId;
  final String name;
  final String description;
  final int quantity;
  final String status; // 'available', 'pending', 'shared', 'expired'
  final int categoryId;
  final int locationId;
  final DateTime? expirationDate;
  final DateTime createdAt;
  final double price; // 0 for free items

  ItemModel({
    required this.itemId,
    required this.userId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.status,
    required this.categoryId,
    required this.locationId,
    this.expirationDate,
    required this.createdAt,
    this.price = 0,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      itemId: json['item_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? 'available',
      categoryId: json['category_id'] ?? 0,
      locationId: json['location_id'] ?? 0,
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'user_id': userId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'status': status,
      'category_id': categoryId,
      'location_id': locationId,
      if (expirationDate != null)
        'expiration_date': expirationDate!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'price': price,
    };
  }

  ItemModel copyWith({
    int? itemId,
    int? userId,
    String? name,
    String? description,
    int? quantity,
    String? status,
    int? categoryId,
    int? locationId,
    DateTime? expirationDate,
    DateTime? createdAt,
    double? price,
  }) {
    return ItemModel(
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      locationId: locationId ?? this.locationId,
      expirationDate: expirationDate ?? this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
    );
  }

  bool get isExpired =>
      expirationDate != null && DateTime.now().isAfter(expirationDate!);
}

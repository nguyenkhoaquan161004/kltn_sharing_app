class ItemModel {
  final int itemId;
  final String? itemId_str; // Item ID as string (UUID from API)
  final int userId;
  final String name;
  final String? description;
  final int quantity;
  final String status; // 'AVAILABLE', 'PENDING', 'SHARED', 'EXPIRED'
  final int categoryId;
  final String? categoryName;
  final int locationId;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double price; // 0 for free items
  final String? image; // Product image URL
  final String? userId_str; // User ID as string
  final String? categoryId_str; // Category ID as string
  final double? latitude;
  final double? longitude;
  final double? distance; // Distance in km
  final bool isCharityItem;
  final String? donationAmount;

  // Getter for backward compatibility
  DateTime? get expirationDate => expiryDate;

  ItemModel({
    required this.itemId,
    this.itemId_str,
    this.userId = 0,
    required this.name,
    this.description,
    required this.quantity,
    required this.status,
    this.categoryId = 0,
    this.categoryName,
    this.locationId = 0,
    this.expiryDate,
    required this.createdAt,
    this.updatedAt,
    this.price = 0,
    this.image,
    this.userId_str,
    this.categoryId_str,
    this.latitude,
    this.longitude,
    this.distance,
    this.isCharityItem = false,
    this.donationAmount,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      itemId: json['item_id'] ?? json['id']?.hashCode ?? 0,
      userId: json['user_id'] ?? 0,
      userId_str: json['userId'] as String?,
      name: json['name'] ?? '',
      description: json['description'],
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? 'AVAILABLE',
      categoryId: json['category_id'] ?? 0,
      categoryId_str: json['categoryId'],
      categoryName: json['categoryName'] ?? json['category'],
      locationId: json['location_id'] ?? 0,
      expiryDate: json['expiration_date'] != null
          ? DateTime.tryParse(json['expiration_date'])
          : json['expiryDate'] != null
              ? DateTime.tryParse(json['expiryDate'])
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? json['imageUrl'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] ?? json['distanceKm'])?.toDouble(),
      isCharityItem: json['isCharityItem'] as bool? ?? false,
      donationAmount: json['donationAmountFormatted'],
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
      if (expiryDate != null) 'expiration_date': expiryDate!.toIso8601String(),
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
    DateTime? expiryDate,
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
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
    );
  }

  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);
}

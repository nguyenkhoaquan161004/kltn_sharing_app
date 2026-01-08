class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String category;
  final int quantity;
  final int interestedCount;
  final DateTime expiryDate;
  final DateTime createdAt;
  final UserInfo owner;
  final String status; // available, pending, sold
  final bool isFree;
  final String? cartItemId; // Original itemId from cart for deletion

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.quantity,
    required this.interestedCount,
    required this.expiryDate,
    required this.createdAt,
    required this.owner,
    this.status = 'available',
    this.isFree = false,
    this.cartItemId,
  });

  // Computed properties
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  Duration get remainingTime => expiryDate.difference(DateTime.now());

  String get formattedPrice {
    if (isFree || price == 0) return '0 VND';
    // Format price with thousand separators (e.g., 30000 -> 30.000)
    final priceStr = price.toStringAsFixed(0);
    final reversedPrice = priceStr.split('').reversed.toList();
    final formatted = <String>[];
    for (int i = 0; i < reversedPrice.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add('.');
      }
      formatted.add(reversedPrice[i]);
    }
    return '${formatted.reversed.join('')} VND';
  }

  String get formattedCountdown {
    if (isExpired) return 'Hết hạn';

    final duration = remainingTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Factory constructor from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      interestedCount: json['interestedCount'] ?? 0,
      expiryDate: DateTime.parse(
          json['expiryDate'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      owner: UserInfo.fromJson(json['owner'] ?? {}),
      status: json['status'] ?? 'available',
      isFree: json['isFree'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'quantity': quantity,
      'interestedCount': interestedCount,
      'expiryDate': expiryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'owner': owner.toJson(),
      'status': status,
      'isFree': isFree,
    };
  }

  // Copy with
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    List<String>? images,
    String? category,
    int? quantity,
    int? interestedCount,
    DateTime? expiryDate,
    DateTime? createdAt,
    UserInfo? owner,
    String? status,
    bool? isFree,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      interestedCount: interestedCount ?? this.interestedCount,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      isFree: isFree ?? this.isFree,
    );
  }
}

class UserInfo {
  final String id;
  final String name;
  final String avatar;
  final int productsShared;
  final String? address;

  UserInfo({
    required this.id,
    required this.name,
    required this.avatar,
    required this.productsShared,
    this.address,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      productsShared: json['productsShared'] ?? 0,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'productsShared': productsShared,
      if (address != null) 'address': address,
    };
  }
}

class ItemDto {
  final String id;
  final String name;
  final String? description;
  final int? quantity;
  final String? imageUrl;
  final DateTime? expiryDate;
  final String status;
  final String userId;
  final String categoryId;
  final String? categoryName;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? price;
  final bool? isCharityItem;
  final String? donationAmountFormatted;

  ItemDto({
    required this.id,
    required this.name,
    this.description,
    this.quantity,
    this.imageUrl,
    this.expiryDate,
    required this.status,
    required this.userId,
    required this.categoryId,
    this.categoryName,
    this.latitude,
    this.longitude,
    this.distanceKm,
    required this.createdAt,
    this.updatedAt,
    this.price,
    this.isCharityItem,
    this.donationAmountFormatted,
  });

  factory ItemDto.fromJson(Map<String, dynamic> json) {
    return ItemDto(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      description: json['description'] as String?,
      quantity: json['quantity'] as int?,
      imageUrl: json['imageUrl'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      status: json['status'] ?? 'AVAILABLE',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      price: (json['price'] as num?)?.toDouble(),
      isCharityItem: json['isCharityItem'] as bool?,
      donationAmountFormatted: json['donationAmountFormatted'] as String?,
    );
  }
}

class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool isFirst;
  final bool isLast;
  final bool isEmpty;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.isFirst,
    required this.isLast,
    required this.isEmpty,
  });

  factory PageResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final contentList = (json['content'] as List<dynamic>?)
            ?.map((e) => fromJsonT(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PageResponse(
      content: contentList,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
      pageSize: json['pageSize'] ?? 10,
      isFirst: json['isFirst'] ?? false,
      isLast: json['isLast'] ?? false,
      isEmpty: json['isEmpty'] ?? true,
    );
  }
}

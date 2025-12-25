import 'package:kltn_sharing_app/data/models/item_model.dart';

/// Recommendation DTO - matches API response structure
class RecommendationDto {
  final String id;
  final String name;
  final String? description;
  final int quantity;
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
  final double price;
  final bool isCharityItem;
  final String? donationAmountFormatted;

  RecommendationDto({
    required this.id,
    required this.name,
    this.description,
    required this.quantity,
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
    this.price = 0.0,
    this.isCharityItem = false,
    this.donationAmountFormatted,
  });

  factory RecommendationDto.fromJson(Map<String, dynamic> json) {
    return RecommendationDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      status: json['status'] as String? ?? 'AVAILABLE',
      userId: json['userId'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isCharityItem: json['isCharityItem'] as bool? ?? false,
      donationAmountFormatted: json['donationAmountFormatted'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate?.toIso8601String(),
      'status': status,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'price': price,
      'isCharityItem': isCharityItem,
      'donationAmountFormatted': donationAmountFormatted,
    };
  }
}

/// Pagination data wrapper
class PageData<T> {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final List<T> data;

  PageData({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.data,
  });

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageData<T>(
      page: json['page'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// API response wrapper
class RecommendationsResponse {
  final bool success;
  final int status;
  final String code;
  final String message;
  final PageData<RecommendationDto> data;
  final List<dynamic>? errors;
  final Map<String, dynamic>? meta;
  final DateTime? timestamp;
  final String? path;

  RecommendationsResponse({
    required this.success,
    required this.status,
    required this.code,
    required this.message,
    required this.data,
    this.errors,
    this.meta,
    this.timestamp,
    this.path,
  });

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    final dataField = json['data'];

    // Handle two cases:
    // 1. data is a Map<String, dynamic> with pagination info (page, limit, totalItems, totalPages, data)
    // 2. data is a List<dynamic> directly (for endpoints that don't include pagination)
    late PageData<RecommendationDto> pageData;

    if (dataField is Map<String, dynamic>) {
      // Full pagination response
      pageData = PageData<RecommendationDto>.fromJson(
        dataField,
        (itemJson) => RecommendationDto.fromJson(itemJson),
      );
    } else if (dataField is List<dynamic>) {
      // Direct list response - create PageData wrapper
      final items = dataField
          .map((item) =>
              RecommendationDto.fromJson(item as Map<String, dynamic>))
          .toList();
      pageData = PageData<RecommendationDto>(
        page: 0,
        limit: items.length,
        totalItems: items.length,
        totalPages: 1,
        data: items,
      );
    } else {
      // Empty response
      pageData = PageData<RecommendationDto>(
        page: 0,
        limit: 0,
        totalItems: 0,
        totalPages: 0,
        data: [],
      );
    }

    return RecommendationsResponse(
      success: json['success'] as bool? ?? false,
      status: json['status'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: pageData,
      errors: json['errors'] as List<dynamic>?,
      meta: json['meta'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      path: json['path'] as String?,
    );
  }
}

/// Convert RecommendationDto to ItemModel
extension RecommendationToItemModel on RecommendationDto {
  ItemModel toItemModel() => ItemModel(
        itemId: id.hashCode,
        itemId_str: id, // Pass UUID string for API navigation
        userId_str: userId,
        categoryId_str: categoryId,
        name: name,
        description: description,
        price: price,
        image: imageUrl,
        categoryName: categoryName,
        quantity: quantity,
        status: status,
        latitude: latitude,
        longitude: longitude,
        distance: distanceKm,
        expiryDate: expiryDate,
        isCharityItem: isCharityItem,
        donationAmount: donationAmountFormatted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

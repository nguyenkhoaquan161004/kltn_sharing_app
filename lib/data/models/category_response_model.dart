class CategoryDto {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CategoryDto({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      icon: json['icon'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class CategoriesResponse {
  final List<CategoryDto> data;
  final bool success;
  final String? message;

  CategoriesResponse({
    required this.data,
    required this.success,
    this.message,
  });

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
            ?.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CategoriesResponse(
      data: dataList,
      success: json['success'] ?? true,
      message: json['message'],
    );
  }
}

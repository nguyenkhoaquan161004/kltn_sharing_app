class CategoryModel {
  final int categoryId;
  final String name;

  CategoryModel({
    required this.categoryId,
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
    };
  }

  CategoryModel copyWith({
    int? categoryId,
    String? name,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
    );
  }
}

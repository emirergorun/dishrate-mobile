class CategoryModel {
  final int categoryId;
  final String name;

  const CategoryModel({required this.categoryId, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] as int,
      name: json['name'] as String,
    );
  }
}

/// Yemek kategorisi (2.10b). [slug] değişmeyen anahtar: sunucuya giden
/// süzgeç ve ikon buna bağlı. [name] yalnız ekranda görünür; sunucuda
/// değişse de bir şey bozulmaz.
class CategoryModel {
  const CategoryModel({required this.slug, required this.name});

  final String slug;
  final String name;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        slug: json['slug'] as String,
        name: json['name'] as String,
      );
}

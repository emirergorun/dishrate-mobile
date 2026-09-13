import 'menu_item_model.dart';

/// Keşfet akışının bir bölümü (`GET /menu-items/feed`).
///
/// Başlık sunucudan gelmez: [key] istemcideki başlıkla eşleştirilir, böylece
/// metin değişikliği için backend sürümü gerekmez.
class FeedSection {
  const FeedSection({
    required this.key,
    required this.items,
    required this.hasMore,
  });

  /// "top-rated", "weekly", "most-wanted", "cheat-meal", "healthy",
  /// "hidden-gems".
  final String key;
  final List<MenuItemModel> items;

  /// Sunucuda bu bölümün devamı var mı — "Tümünü gör" buna bakar.
  final bool hasMore;

  factory FeedSection.fromJson(Map<String, dynamic> json) => FeedSection(
        key: json['key'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: json['hasMore'] as bool? ?? false,
      );
}

import 'package:flutter/widgets.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../shared/models/category_model.dart';

/// Yemek kategorileri. Liste sunucudan gelir (`categoriesProvider`, 2.10b);
/// burada yalnız ilk açılış ya da bağlantı yokken gösterilen yedek liste ve
/// anahtara bağlı ikonlar var.
///
/// Önceden liste burada sabitti ve Türkçe adla eşleşiyordu: sunucuda bir ad
/// değişince çipler ve Keşfet bölümleri sessizce bozuluyor, yeni kategori
/// uygulama güncellenmeden görünmüyordu.
abstract final class AppCategories {
  /// Sunucudaki başlangıç kategorileri, aynı sırayla.
  static const List<CategoryModel> fallback = [
    CategoryModel(slug: 'burger', name: 'Burger'),
    CategoryModel(slug: 'pizza', name: 'Pizza'),
    CategoryModel(slug: 'turk-mutfagi', name: 'Türk Mutfağı'),
    CategoryModel(slug: 'ev-yemegi', name: 'Ev Yemeği'),
    CategoryModel(slug: 'sushi', name: 'Sushi'),
    CategoryModel(slug: 'tatli', name: 'Tatlı'),
    CategoryModel(slug: 'kahvalti', name: 'Kahvaltı'),
    CategoryModel(slug: 'italyan', name: 'İtalyan'),
    CategoryModel(slug: 'vegan', name: 'Vegan'),
    CategoryModel(slug: 'meze', name: 'Meze'),
    CategoryModel(slug: 'noodle', name: 'Noodle'),
    CategoryModel(slug: 'tavuk', name: 'Tavuk'),
    CategoryModel(slug: 'sandvic', name: 'Sandviç'),
  ];

  /// Kategorinin ikonu, anahtara göre. Sonradan eklenen (ikonu olmayan)
  /// kategoride genel mutfak ikonu. Haritada emoji kullanılıyordu; hem
  /// çocukça duruyordu hem de her yerde aynı tabak çıkıyordu.
  static IconData icon(String? slug) => switch (slug) {
        'burger' => TablerIcons.burger,
        'pizza' => TablerIcons.pizza,
        'turk-mutfagi' => TablerIcons.meat,
        'ev-yemegi' => TablerIcons.soup,
        'sushi' => TablerIcons.fish,
        'tatli' => TablerIcons.cake,
        'kahvalti' => TablerIcons.egg_fried,
        'italyan' => TablerIcons.bowl_spoon,
        'vegan' => TablerIcons.salad,
        'meze' => TablerIcons.cheese,
        'noodle' => TablerIcons.bowl_chopsticks,
        'tavuk' => TablerIcons.grill,
        'sandvic' => TablerIcons.bread,
        _ => TablerIcons.tools_kitchen_2,
      };

  /// Ekrandaki ada karşılık gelen anahtar; listede yoksa null.
  static String? slugOf(List<CategoryModel> list, String? name) {
    if (name == null) return null;
    for (final c in list) {
      if (c.name == name) return c.slug;
    }
    return null;
  }
}

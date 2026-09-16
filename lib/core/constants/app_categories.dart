import 'package:flutter/widgets.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Yemek kategorileri — sunucudaki `categories` tablosuyla aynı adlar.
///
/// Önceden keşfet, arama ve harita ekranlarının her birinde ayrı bir liste
/// vardı ve birbirinden sapmıştı (birinde "Tavuk" yoktu, ötekinde "Sandviç").
abstract final class AppCategories {
  static const List<String> all = [
    'Burger',
    'Pizza',
    'Türk Mutfağı',
    'Ev Yemeği',
    'Sushi',
    'Tatlı',
    'Kahvaltı',
    'İtalyan',
    'Vegan',
    'Meze',
    'Noodle',
    'Tavuk',
    'Sandviç',
  ];

  /// Kategorinin ikonu. Haritada emoji kullanılıyordu; hem çocukça duruyordu
  /// hem de restoranın türü bilinmediği için her yerde aynı tabak çıkıyordu.
  static IconData icon(String? category) => switch (category) {
        'Burger' => TablerIcons.burger,
        'Pizza' => TablerIcons.pizza,
        'Türk Mutfağı' => TablerIcons.meat,
        'Ev Yemeği' => TablerIcons.soup,
        'Sushi' => TablerIcons.fish,
        'Tatlı' => TablerIcons.cake,
        'Kahvaltı' => TablerIcons.egg_fried,
        'İtalyan' => TablerIcons.bowl_spoon,
        'Vegan' => TablerIcons.salad,
        'Meze' => TablerIcons.cheese,
        'Noodle' => TablerIcons.bowl_chopsticks,
        'Tavuk' => TablerIcons.grill,
        'Sandviç' => TablerIcons.bread,
        _ => TablerIcons.tools_kitchen_2,
      };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/wishlist_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../rating/providers/rating_flow_provider.dart';
import '../../rating/screens/add_rating_screen.dart';
import '../widgets/category_chips.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/section_header.dart';
import 'see_all_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _selectedCategory; // null veya 'Tümü' → hepsi gösterilir

  // ── Mock veri (API entegrasyonuna kadar) ─────────────────────────────────
  static const List<MenuItemModel> _nearbyItems = [
    MenuItemModel(
      menuItemId: 1,
      name: 'Smash Burger',
      price: 320,
      averageRating: 4.7,
      photoUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=500&fit=crop',
      restaurantId: 1,
      restaurantName: 'Burger Joint',
      categoryName: 'Burger',
      district: 'Beşiktaş',
    ),
    MenuItemModel(
      menuItemId: 2,
      name: 'Margherita',
      price: 280,
      averageRating: 4.5,
      photoUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=500&fit=crop',
      restaurantId: 2,
      restaurantName: 'Pizza Napoli',
      categoryName: 'Pizza',
      district: 'Nişantaşı',
    ),
    MenuItemModel(
      menuItemId: 3,
      name: 'Adana Kebap',
      price: 350,
      averageRating: 4.8,
      photoUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400&h=500&fit=crop',
      restaurantId: 3,
      restaurantName: 'Ocakbaşı 1969',
      categoryName: 'Kebap',
      district: 'Karaköy',
    ),
    MenuItemModel(
      menuItemId: 4,
      name: 'Tuna Tataki',
      price: 480,
      averageRating: 4.6,
      photoUrl: 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400&h=500&fit=crop',
      restaurantId: 4,
      restaurantName: 'Nobu Istanbul',
      categoryName: 'Sushi',
      district: 'Etiler',
    ),
    MenuItemModel(menuItemId: 28, name: 'Kuzu Şiş', price: 420, averageRating: 4.8, photoUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400&h=500&fit=crop', restaurantId: 9, restaurantName: 'Ocakbaşı 1969', categoryName: 'Kebap', district: 'Karaköy'),
    MenuItemModel(menuItemId: 29, name: 'Dragon Roll', price: 520, averageRating: 4.9, photoUrl: 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400&h=500&fit=crop', restaurantId: 7, restaurantName: 'Sushi Kaito', categoryName: 'Sushi', district: 'Nişantaşı'),
    MenuItemModel(menuItemId: 30, name: 'Tiramisu', price: 240, averageRating: 4.9, photoUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400&h=500&fit=crop', restaurantId: 18, restaurantName: 'La Cucina', categoryName: 'Tatlı', district: 'Cihangir'),
  ];

  static const List<MenuItemModel> _weeklyTop = [
    MenuItemModel(
      menuItemId: 5,
      name: 'Double Smash',
      price: 395,
      averageRating: 4.9,
      photoUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400&h=500&fit=crop',
      restaurantId: 5,
      restaurantName: 'Bun Lab',
      categoryName: 'Burger',
      district: 'Kadıköy',
    ),
    MenuItemModel(
      menuItemId: 6,
      name: 'Truffle Risotto',
      price: 520,
      averageRating: 4.8,
      photoUrl: 'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=400&h=500&fit=crop',
      restaurantId: 6,
      restaurantName: 'La Cucina',
      categoryName: 'İtalyan',
      district: 'Cihangir',
    ),
    MenuItemModel(
      menuItemId: 7,
      name: 'Künefe',
      price: 180,
      averageRating: 4.9,
      photoUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400&h=500&fit=crop',
      restaurantId: 7,
      restaurantName: 'Şanlıurfa Sofrası',
      categoryName: 'Tatlı',
      district: 'Fatih',
    ),
    MenuItemModel(
      menuItemId: 8,
      name: 'Eggs Benedict',
      price: 290,
      averageRating: 4.7,
      photoUrl: 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=400&h=500&fit=crop',
      restaurantId: 8,
      restaurantName: 'Sunday Brunch',
      categoryName: 'Kahvaltı',
      district: 'Moda',
    ),
    MenuItemModel(menuItemId: 31, name: 'İskender Kebap', price: 380, averageRating: 4.8, photoUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400&h=500&fit=crop', restaurantId: 3, restaurantName: 'Ocakbaşı 1969', categoryName: 'Kebap', district: 'Karaköy'),
    MenuItemModel(menuItemId: 32, name: 'Fıstıklı Baklava', price: 130, averageRating: 4.9, photoUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400&h=500&fit=crop', restaurantId: 11, restaurantName: 'Güllüoğlu', categoryName: 'Tatlı', district: 'Karaköy'),
    MenuItemModel(menuItemId: 33, name: 'Vongole Spaghetti', price: 440, averageRating: 4.7, photoUrl: 'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=400&h=500&fit=crop', restaurantId: 6, restaurantName: 'La Cucina', categoryName: 'İtalyan', district: 'Cihangir'),
  ];

  static const List<MenuItemModel> _mostWishlisted = [
    MenuItemModel(
      menuItemId: 9,
      name: 'Wagyu Burger',
      price: 650,
      averageRating: 4.8,
      photoUrl: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400&h=500&fit=crop',
      restaurantId: 9,
      restaurantName: 'The Fat Cow',
      categoryName: 'Burger',
      district: 'Bebek',
    ),
    MenuItemModel(
      menuItemId: 10,
      name: 'Omakase Set',
      price: 1200,
      averageRating: 5.0,
      photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=500&fit=crop',
      restaurantId: 10,
      restaurantName: 'Sushi Kaito',
      categoryName: 'Sushi',
      district: 'Nişantaşı',
    ),
    MenuItemModel(
      menuItemId: 11,
      name: 'Pistachio Baklava',
      price: 120,
      averageRating: 4.9,
      photoUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400&h=500&fit=crop',
      restaurantId: 11,
      restaurantName: 'Güllüoğlu',
      categoryName: 'Tatlı',
      district: 'Karaköy',
    ),
    MenuItemModel(menuItemId: 34, name: 'Taze Mantı', price: 280, averageRating: 4.8, photoUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&h=500&fit=crop', restaurantId: 15, restaurantName: 'Earthly Kitchen', categoryName: 'Vegan', district: 'Beyoğlu'),
    MenuItemModel(menuItemId: 35, name: 'Izgara Köfte', price: 260, averageRating: 4.8, photoUrl: 'https://images.unsplash.com/photo-1561651823-34feb02250e4?w=400&h=500&fit=crop', restaurantId: 17, restaurantName: 'Köfteci Arnavut', categoryName: 'Kebap', district: 'Beşiktaş'),
    MenuItemModel(menuItemId: 36, name: 'Salmon Nigiri', price: 680, averageRating: 4.9, photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=500&fit=crop', restaurantId: 10, restaurantName: 'Sushi Kaito', categoryName: 'Sushi', district: 'Nişantaşı'),
    MenuItemModel(menuItemId: 37, name: 'Smoked BBQ Burger', price: 460, averageRating: 4.7, photoUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400&h=500&fit=crop', restaurantId: 9, restaurantName: 'The Fat Cow', categoryName: 'Burger', district: 'Bebek'),
  ];

  static const List<MenuItemModel> _cheatMeal = [
    MenuItemModel(
      menuItemId: 12,
      name: 'Triple Smash',
      price: 420,
      averageRating: 4.9,
      photoUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&h=500&fit=crop',
      restaurantId: 12,
      restaurantName: 'Smoke & Grill',
      categoryName: 'Burger',
      district: 'Şişli',
    ),
    MenuItemModel(
      menuItemId: 13,
      name: 'Pepperoni Calzone',
      price: 380,
      averageRating: 4.7,
      photoUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=500&fit=crop',
      restaurantId: 13,
      restaurantName: 'Forno di Napoli',
      categoryName: 'Pizza',
      district: 'Galata',
    ),
    MenuItemModel(
      menuItemId: 14,
      name: 'Truffle Carbonara',
      price: 460,
      averageRating: 4.8,
      photoUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400&h=500&fit=crop',
      restaurantId: 6,
      restaurantName: 'La Cucina',
      categoryName: 'İtalyan',
      district: 'Cihangir',
    ),
    MenuItemModel(
      menuItemId: 15,
      name: 'Loaded Fries',
      price: 220,
      averageRating: 4.6,
      photoUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&h=500&fit=crop',
      restaurantId: 5,
      restaurantName: 'Bun Lab',
      categoryName: 'Burger',
      district: 'Kadıköy',
    ),
    MenuItemModel(menuItemId: 38, name: 'Kokoreç Ekmek', price: 160, averageRating: 4.8, photoUrl: 'https://images.unsplash.com/photo-1561651823-34feb02250e4?w=400&h=500&fit=crop', restaurantId: 16, restaurantName: 'Şampiyon Kokoreç', categoryName: 'Sandviç', district: 'Beyoğlu'),
    MenuItemModel(menuItemId: 39, name: 'Nutella Krep', price: 185, averageRating: 4.7, photoUrl: 'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400&h=500&fit=crop', restaurantId: 8, restaurantName: 'Sunday Brunch', categoryName: 'Tatlı', district: 'Moda'),
    MenuItemModel(menuItemId: 40, name: 'Döner Dürüm', price: 180, averageRating: 4.6, photoUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400&h=500&fit=crop', restaurantId: 17, restaurantName: 'Karadeniz Döner', categoryName: 'Kebap', district: 'Beşiktaş'),
  ];

  static const List<MenuItemModel> _healthy = [
    MenuItemModel(
      menuItemId: 16,
      name: 'Quinoa Power Bowl',
      price: 280,
      averageRating: 4.6,
      photoUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=500&fit=crop',
      restaurantId: 14,
      restaurantName: 'Green Bowl',
      categoryName: 'Vegan',
      district: 'Nişantaşı',
    ),
    MenuItemModel(
      menuItemId: 17,
      name: 'Avocado Toast',
      price: 220,
      averageRating: 4.5,
      photoUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&h=500&fit=crop',
      restaurantId: 8,
      restaurantName: 'Sunday Brunch',
      categoryName: 'Kahvaltı',
      district: 'Moda',
    ),
    MenuItemModel(
      menuItemId: 18,
      name: 'Mercimek Köftesi',
      price: 160,
      averageRating: 4.7,
      photoUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=500&fit=crop',
      restaurantId: 15,
      restaurantName: 'Earthly Kitchen',
      categoryName: 'Vegan',
      district: 'Beyoğlu',
    ),
    MenuItemModel(
      menuItemId: 19,
      name: 'Açık Sandviç',
      price: 195,
      averageRating: 4.4,
      photoUrl: 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=400&h=500&fit=crop',
      restaurantId: 14,
      restaurantName: 'Green Bowl',
      categoryName: 'Sandviç',
      district: 'Nişantaşı',
    ),
    MenuItemModel(menuItemId: 41, name: 'Buddha Bowl', price: 310, averageRating: 4.6, photoUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=500&fit=crop', restaurantId: 14, restaurantName: 'Green Bowl', categoryName: 'Vegan', district: 'Nişantaşı'),
    MenuItemModel(menuItemId: 42, name: 'Ton Balığı Salata', price: 270, averageRating: 4.5, photoUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=500&fit=crop', restaurantId: 21, restaurantName: 'Sahil Meyhane', categoryName: 'Meze', district: 'Ortaköy'),
    MenuItemModel(menuItemId: 43, name: 'Chia Pudding', price: 180, averageRating: 4.5, photoUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&h=500&fit=crop', restaurantId: 15, restaurantName: 'Earthly Kitchen', categoryName: 'Vegan', district: 'Beyoğlu'),
  ];

  static const List<MenuItemModel> _budget = [
    MenuItemModel(
      menuItemId: 20,
      name: 'Islak Burger',
      price: 100,
      averageRating: 4.6,
      photoUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=500&fit=crop',
      restaurantId: 16,
      restaurantName: 'Bambi',
      categoryName: 'Sandviç',
      district: 'Beyoğlu',
    ),
    MenuItemModel(
      menuItemId: 21,
      name: 'Dürüm Döner',
      price: 120,
      averageRating: 4.5,
      photoUrl: 'https://images.unsplash.com/photo-1561651823-34feb02250e4?w=400&h=500&fit=crop',
      restaurantId: 17,
      restaurantName: 'Karadeniz Döner',
      categoryName: 'Kebap',
      district: 'Beşiktaş',
    ),
    MenuItemModel(
      menuItemId: 22,
      name: 'Karışık Gözleme',
      price: 95,
      averageRating: 4.7,
      photoUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&h=500&fit=crop',
      restaurantId: 18,
      restaurantName: 'Gözlemeci Hanım',
      categoryName: 'Kahvaltı',
      district: 'Üsküdar',
    ),
    MenuItemModel(
      menuItemId: 23,
      name: 'Mercimek Çorbası',
      price: 85,
      averageRating: 4.8,
      photoUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=500&fit=crop',
      restaurantId: 19,
      restaurantName: 'Ev Yemekleri',
      categoryName: 'Vegan',
      district: 'Fatih',
    ),
    MenuItemModel(menuItemId: 44, name: 'Lahmacun', price: 75, averageRating: 4.7, photoUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&h=500&fit=crop', restaurantId: 20, restaurantName: 'Lahmacun Ustası', categoryName: 'Kebap', district: 'Fatih'),
    MenuItemModel(menuItemId: 45, name: 'Kuru Fasulye', price: 95, averageRating: 4.8, photoUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=500&fit=crop', restaurantId: 19, restaurantName: 'Tarihi Kuru Fasulye', categoryName: 'Vegan', district: 'Fatih'),
    MenuItemModel(menuItemId: 46, name: 'Pide Kaşarlı', price: 130, averageRating: 4.6, photoUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=500&fit=crop', restaurantId: 22, restaurantName: 'Karadeniz Fırını', categoryName: 'Kahvaltı', district: 'Sarıyer'),
  ];

  static const List<MenuItemModel> _hidden = [
    MenuItemModel(
      menuItemId: 24,
      name: 'Tantuni',
      price: 180,
      averageRating: 4.9,
      photoUrl: 'https://images.unsplash.com/photo-1561651823-34feb02250e4?w=400&h=500&fit=crop',
      restaurantId: 20,
      restaurantName: 'Mersin Tantunisi',
      categoryName: 'Kebap',
      district: 'Bağcılar',
    ),
    MenuItemModel(
      menuItemId: 25,
      name: 'Midye Dolma',
      price: 250,
      averageRating: 4.7,
      photoUrl: 'https://images.unsplash.com/photo-1559742811-822873691df8?w=400&h=500&fit=crop',
      restaurantId: 21,
      restaurantName: 'Sahil Meyhane',
      categoryName: 'Meze',
      district: 'Ortaköy',
    ),
    MenuItemModel(
      menuItemId: 26,
      name: 'Çiğ Börek',
      price: 140,
      averageRating: 4.8,
      photoUrl: 'https://images.unsplash.com/photo-1517244683847-7456b63c5969?w=400&h=500&fit=crop',
      restaurantId: 22,
      restaurantName: 'Kırım Mutfağı',
      categoryName: 'Meze',
      district: 'Sarıyer',
    ),
    MenuItemModel(
      menuItemId: 27,
      name: 'Ramen',
      price: 320,
      averageRating: 4.8,
      photoUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&h=500&fit=crop',
      restaurantId: 23,
      restaurantName: 'Noodle Bar',
      categoryName: 'Noodle',
      district: 'Karaköy',
    ),
    MenuItemModel(menuItemId: 47, name: 'Balık Ekmek', price: 200, averageRating: 4.9, photoUrl: 'https://images.unsplash.com/photo-1559742811-822873691df8?w=400&h=500&fit=crop', restaurantId: 21, restaurantName: 'Galata Balıkçısı', categoryName: 'Meze', district: 'Galata'),
    MenuItemModel(menuItemId: 48, name: 'Çiğ Börek', price: 145, averageRating: 4.8, photoUrl: 'https://images.unsplash.com/photo-1517244683847-7456b63c5969?w=400&h=500&fit=crop', restaurantId: 22, restaurantName: 'Kırım Mutfağı', categoryName: 'Meze', district: 'Sarıyer'),
    MenuItemModel(menuItemId: 49, name: 'Pad Thai', price: 340, averageRating: 4.7, photoUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&h=500&fit=crop', restaurantId: 23, restaurantName: 'Noodle Bar', categoryName: 'Noodle', district: 'Karaköy'),
  ];

  static const List<String> _categories = [
    'Tümü',
    'Burger',
    'Pizza',
    'Kebap',
    'Sushi',
    'Tatlı',
    'Kahvaltı',
    'İtalyan',
    'Vegan',
    'Meze',
    'Sandviç',
    'Noodle',
  ];

  List<MenuItemModel> _filtered(List<MenuItemModel> src) {
    if (_selectedCategory == null || _selectedCategory == 'Tümü') return src;
    return src
        .where((item) => item.categoryName == _selectedCategory)
        .toList();
  }

  void _seeAll(String title, List<MenuItemModel> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeeAllScreen(title: title, items: items),
      ),
    );
  }

  Future<void> _showItemSheet(MenuItemModel item) async {
    final shouldRate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuItemSheet(item: item),
    );
    if (shouldRate == true && mounted) {
      final restaurant = RestaurantModel(
        restaurantId: item.restaurantId,
        name: item.restaurantName,
        city: item.city ?? 'İstanbul',
        district: item.district,
        fullAddress:
            '${item.restaurantName}, ${item.district ?? item.city ?? "İstanbul"}',
        latitude: item.restaurantLatitude,
        longitude: item.restaurantLongitude,
        categoryName: item.categoryName,
      );
      ref.read(ratingFlowProvider.notifier).jumpToRateItem(restaurant, item);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _DiscoverRatingSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          _DiscoverAppBar(),

          // ── Kategori Chip'leri ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                CategoryChips(
                  categories: _categories,
                  onSelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
              ],
            ),
          ),

          // ── Yakınındaki En İyiler ──────────────────────────────────────
          if (_filtered(_nearbyItems).isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'İstanbul\'da En İyiler',
                    subtitle: 'Konumuna yakın, yüksek puanlı lezzetler',
                    onSeeAll: () => _seeAll('İstanbul\'da En İyiler', _filtered(_nearbyItems)),
                  ),
                  _HorizontalCardList(onItemTap: _showItemSheet, items: _filtered(_nearbyItems)),
                ],
              ),
            ),

          // ── Bu Haftanın Favorileri ─────────────────────────────────────
          if (_filtered(_weeklyTop).isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Bu Haftanın Favorileri',
                    subtitle: 'Son 7 günün en çok puan alan menü öğeleri',
                    onSeeAll: () => _seeAll('Bu Haftanın Favorileri', _filtered(_weeklyTop)),
                  ),
                  _HorizontalCardList(onItemTap: _showItemSheet, items: _filtered(_weeklyTop)),
                ],
              ),
            ),

          // ── En Çok İstek Listesinde ───────────────────────────────────
          if (_filtered(_mostWishlisted).isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Herkes Denemek İstiyor',
                    subtitle: 'En çok istek listesine eklenen yemekler',
                    onSeeAll: () => _seeAll('Herkes Denemek İstiyor', _filtered(_mostWishlisted)),
                  ),
                  _HorizontalCardList(onItemTap: _showItemSheet, items: _filtered(_mostWishlisted)),
                ],
              ),
            ),

          // ── Diyeti Bozmaya Değer ──────────────────────────────────────
          if (_filtered(_cheatMeal).isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Diyeti Bozmaya Değer',
                    subtitle: 'Pişman olmayacağın kalorili şaheserler',
                    onSeeAll: () => _seeAll('Diyeti Bozmaya Değer', _filtered(_cheatMeal)),
                  ),
                  _HorizontalCardList(onItemTap: _showItemSheet, items: _filtered(_cheatMeal)),
                ],
              ),
            ),

          // ── Sağlıklı & Fit Seçenekler ────────────────────────────────
          if (_filtered(_healthy).isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Sağlıklı & Fit Seçenekler',
                    subtitle: 'Hem lezzetli hem de hafif alternatifler',
                    onSeeAll: () => _seeAll('Sağlıklı & Fit Seçenekler', _filtered(_healthy)),
                  ),
                  _HorizontalCardList(onItemTap: _showItemSheet, items: _filtered(_healthy)),
                ],
              ),
            ),

          // ── Bütçe Dostu Lezzetler ─────────────────────────────────────
          if (_filtered(_budget).isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Bütçe Dostu Lezzetler',
                    subtitle: 'Cüzdanı yakmadan dolu dolu lezzet',
                    onSeeAll: () => _seeAll('Bütçe Dostu Lezzetler', _filtered(_budget)),
                  ),
                  _HorizontalCardList(onItemTap: _showItemSheet, items: _filtered(_budget)),
                ],
              ),
            ),

          // ── Şehrin Gizli Mücevherleri ─────────────────────────────────
          if (_filtered(_hidden).isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Şehrin Gizli Mücevherleri',
                    subtitle: 'Az bilinen ama çok sevilecek mekanlar',
                    onSeeAll: () => _seeAll('Şehrin Gizli Mücevherleri', _filtered(_hidden)),
                  ),
                  _HorizontalCardList(onItemTap: _showItemSheet, items: _filtered(_hidden)),
                ],
              ),
            ),

          // ── Hiç sonuç yoksa ───────────────────────────────────────────
          if (_filtered(_nearbyItems).isEmpty &&
              _filtered(_weeklyTop).isEmpty &&
              _filtered(_mostWishlisted).isEmpty &&
              _filtered(_cheatMeal).isEmpty &&
              _filtered(_healthy).isEmpty &&
              _filtered(_budget).isEmpty &&
              _filtered(_hidden).isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        color: AppColors.textDisabled, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Bu kategoride içerik yok',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          // ── Alt boşluk (bottom nav ile çakışmasın) ────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _DiscoverAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: context.bgColor,
      expandedHeight: 100,
      collapsedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Builder(
          builder: (ctx) => Container(color: ctx.bgColor),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Logo alanı — logo gelince Image.asset ile değiştirilecek
            Text(
              'dishrate',
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 28,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
            const Spacer(),
            // Konum satırı
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  'İstanbul',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Builder(
          builder: (ctx) => Container(height: 0.5, color: ctx.dividerColor),
        ),
      ),
    );
  }
}

// ── Yatay kaydırmalı kart listesi ─────────────────────────────────────────────

class _HorizontalCardList extends StatelessWidget {
  const _HorizontalCardList({
    required this.items,
    required this.onItemTap,
  });
  final List<MenuItemModel> items;
  final void Function(MenuItemModel) onItemTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) => MenuItemCard(
          item: items[index],
          onTap: () => onItemTap(items[index]),
        ),
      ),
    );
  }
}

// ── Yemek öğesi detay sheet'i ─────────────────────────────────────────────────

class _MenuItemSheet extends ConsumerStatefulWidget {
  const _MenuItemSheet({required this.item});
  final MenuItemModel item;

  @override
  ConsumerState<_MenuItemSheet> createState() => _MenuItemSheetState();
}

class _MenuItemSheetState extends ConsumerState<_MenuItemSheet> {
  bool _inWishlist = false;
  bool _wishlistLoading = true;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    try {
      final list = await WishlistRepository.instance.getWishlist(1);
      if (!mounted) return;
      setState(() {
        _inWishlist =
            list.any((w) => w.menuItemId == widget.item.menuItemId);
        _wishlistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  Future<void> _toggleWishlist() async {
    setState(() => _wishlistLoading = true);
    try {
      if (_inWishlist) {
        await WishlistRepository.instance
            .removeByMenuItemId(1, widget.item.menuItemId);
      } else {
        await WishlistRepository.instance
            .addToWishlist(1, widget.item.menuItemId);
      }
      if (!mounted) return;
      setState(() {
        _inWishlist = !_inWishlist;
        _wishlistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Fotoğraf ─────────────────────────────────────────────────
          if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.photoUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        color: AppColors.textDisabled, size: 48),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Bilgiler ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim + puan
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: AppTextStyles.titleLarge),
                    ),
                    if (item.averageRating > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppColors.star.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.star, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              item.averageRating.toStringAsFixed(1),
                              style: AppTextStyles.ratingSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Restoran + konum
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.restaurantName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.district != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.textSecondary, size: 12),
                      const SizedBox(width: 2),
                      Text(item.district!,
                          style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Butonlar ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
            child: Row(
              children: [
                // İstek listesi
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _wishlistLoading ? null : _toggleWishlist,
                    icon: _wishlistLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            _inWishlist
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _inWishlist
                          ? 'Listeden Çıkar'
                          : 'İstek Listesi\'ne Ekle',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Değerlendir
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Değerlendir',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Değerlendirme modal wrapper ───────────────────────────────────────────────

class _DiscoverRatingSheet extends StatelessWidget {
  const _DiscoverRatingSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: const Column(
        children: [
          SizedBox(height: 12),
          SizedBox(
            width: 40,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(child: AddRatingScreen()),
        ],
      ),
    );
  }
}

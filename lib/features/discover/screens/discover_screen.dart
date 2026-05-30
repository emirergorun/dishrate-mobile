import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../widgets/category_chips.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/section_header.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    // TODO: API'dan kategoriye göre filtrele
                  },
                ),
              ],
            ),
          ),

          // ── Yakınındaki En İyiler ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'İstanbul\'da En İyiler',
                  subtitle: 'Konumuna yakın, yüksek puanlı lezzetler',
                  onSeeAll: () {},
                ),
                _HorizontalCardList(items: _nearbyItems),
              ],
            ),
          ),

          // ── Bu Haftanın Favorileri ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Bu Haftanın Favorileri',
                  subtitle: 'Son 7 günün en çok puan alan menü öğeleri',
                  onSeeAll: () {},
                ),
                _HorizontalCardList(items: _weeklyTop),
              ],
            ),
          ),

          // ── En Çok İstek Listesinde ───────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Herkes Denemek İstiyor',
                  subtitle: 'En çok istek listesine eklenen yemekler',
                  onSeeAll: () {},
                ),
                _HorizontalCardList(items: _mostWishlisted),
              ],
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
      backgroundColor: AppColors.background,
      expandedHeight: 100,
      collapsedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(color: AppColors.background),
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
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }
}

// ── Yatay kaydırmalı kart listesi ─────────────────────────────────────────────

class _HorizontalCardList extends StatelessWidget {
  const _HorizontalCardList({required this.items});
  final List<MenuItemModel> items;

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
          onTap: () {
            // TODO: Menü öğesi detay sayfasına git
          },
        ),
      ),
    );
  }
}

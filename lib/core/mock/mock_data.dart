import '../../shared/models/restaurant_model.dart';
import '../../shared/models/menu_item_model.dart';
import '../../shared/models/rating_model.dart';
import '../../shared/models/wishlist_model.dart';
import '../../shared/models/user_model.dart';

/// Geliştirme aşaması için geçici mock data.
///
/// Kaldırmak için:
///   1. Bu dosyayı sil.
///   2. RestaurantRepository/RatingRepository/WishlistRepository'deki
///      `MockData.enabled` kontrollerini kaldır.
class MockData {
  MockData._();

  /// false yap → gerçek API'ye geç. true iken backend'e istek atmaz.
  static const bool enabled = false;

  // ── Mock kullanıcı ────────────────────────────────────────────────────────
  static const UserModel mockUser = UserModel(
    userId: 1,
    username: 'emir_test',
    email: 'emir@dishrate.app',
    bio: 'Yemek tutkunu 🤩',
    profilePhotoUrl: null,
  );

  // ── Fotoğraf URL'leri (Unsplash) ────────────────────────────────────────────
  static const _burger1 =
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&h=300&fit=crop';
  static const _burger2 =
      'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400&h=300&fit=crop';
  static const _burger3 =
      'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&h=300&fit=crop';
  static const _burger4 =
      'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400&h=300&fit=crop';
  static const _pizza1 =
      'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&h=300&fit=crop';
  static const _pizza2 =
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&h=300&fit=crop';
  static const _sushi1 =
      'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400&h=300&fit=crop';
  static const _sushi2 =
      'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop';
  static const _kebap1 =
      'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400&h=300&fit=crop';
  static const _kebap2 =
      'https://images.unsplash.com/photo-1561651823-34feb02250e4?w=400&h=300&fit=crop';
  static const _tavuk =
      'https://images.unsplash.com/photo-1532550884612-72b92802ec04?w=400&h=300&fit=crop';
  static const _kahvalti1 =
      'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=400&h=300&fit=crop';
  static const _kahvalti2 =
      'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&h=300&fit=crop';
  static const _tatli =
      'https://images.unsplash.com/photo-1519676867240-f03562e64548?w=400&h=300&fit=crop';
  static const _italyan1 =
      'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400&h=300&fit=crop';
  static const _italyan2 =
      'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=400&h=300&fit=crop';
  static const _noodle =
      'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&h=300&fit=crop';
  static const _vegan1 =
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&h=300&fit=crop';
  static const _vegan2 =
      'https://images.unsplash.com/photo-1547592180-85f173990554?w=400&h=300&fit=crop';
  static const _fries =
      'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&h=300&fit=crop';

  // ── Restoranlar ──────────────────────────────────────────────────────────────

  static const List<RestaurantModel> restaurants = [
    // ── Burger ──
    RestaurantModel(
      restaurantId: 1,
      name: 'Bun Lab',
      city: 'İstanbul',
      district: 'Kadıköy',
      fullAddress: 'Moda Cad. No:5, Kadıköy',
      latitude: 40.9907,
      longitude: 29.0262,
      categoryName: 'Burger',
    ),
    RestaurantModel(
      restaurantId: 2,
      name: 'Smoke & Grill',
      city: 'İstanbul',
      district: 'Şişli',
      fullAddress: 'Halaskargazi Cad. No:21, Şişli',
      latitude: 41.0602,
      longitude: 28.9877,
      categoryName: 'Burger',
    ),
    RestaurantModel(
      restaurantId: 3,
      name: 'The Fat Cow',
      city: 'İstanbul',
      district: 'Bebek',
      fullAddress: 'Bebek Cad. No:14, Bebek',
      latitude: 41.0774,
      longitude: 29.0396,
      categoryName: 'Burger',
    ),
    RestaurantModel(
      restaurantId: 4,
      name: 'Burger Joint',
      city: 'İstanbul',
      district: 'Beşiktaş',
      fullAddress: 'Sinanpaşa Mah. No:8, Beşiktaş',
      latitude: 41.0422,
      longitude: 29.0056,
      categoryName: 'Burger',
    ),
    // ── Pizza ──
    RestaurantModel(
      restaurantId: 5,
      name: 'Forno di Napoli',
      city: 'İstanbul',
      district: 'Galata',
      fullAddress: 'Galata Kulesi Sok. No:3, Beyoğlu',
      latitude: 41.0256,
      longitude: 28.9744,
      categoryName: 'Pizza',
    ),
    RestaurantModel(
      restaurantId: 6,
      name: 'Pizza Napoli',
      city: 'İstanbul',
      district: 'Nişantaşı',
      fullAddress: 'Abdi İpekçi Cad. No:44, Nişantaşı',
      latitude: 41.0503,
      longitude: 28.9998,
      categoryName: 'Pizza',
    ),
    // ── Sushi ──
    RestaurantModel(
      restaurantId: 7,
      name: 'Sushi Kaito',
      city: 'İstanbul',
      district: 'Nişantaşı',
      fullAddress: 'Teşvikiye Cad. No:18, Nişantaşı',
      latitude: 41.0492,
      longitude: 29.0008,
      categoryName: 'Sushi',
    ),
    RestaurantModel(
      restaurantId: 8,
      name: 'Nobu Istanbul',
      city: 'İstanbul',
      district: 'Etiler',
      fullAddress: 'Nispetiye Cad. No:76, Etiler',
      latitude: 41.0794,
      longitude: 29.0235,
      categoryName: 'Sushi',
    ),
    // ── Kebap ──
    RestaurantModel(
      restaurantId: 9,
      name: 'Ocakbaşı 1969',
      city: 'İstanbul',
      district: 'Karaköy',
      fullAddress: 'Kemankeş Cad. No:11, Karaköy',
      latitude: 41.0231,
      longitude: 28.9766,
      categoryName: 'Kebap',
    ),
    RestaurantModel(
      restaurantId: 10,
      name: 'Karadeniz Döner',
      city: 'İstanbul',
      district: 'Beşiktaş',
      fullAddress: 'Barbaros Blv. No:3, Beşiktaş',
      latitude: 41.0430,
      longitude: 29.0030,
      categoryName: 'Kebap',
    ),
    RestaurantModel(
      restaurantId: 11,
      name: 'Mersin Tantunisi',
      city: 'İstanbul',
      district: 'Bağcılar',
      fullAddress: 'Fevzi Paşa Cad. No:55, Bağcılar',
      latitude: 41.0353,
      longitude: 28.8560,
      categoryName: 'Kebap',
    ),
    // ── Tavuk ──
    RestaurantModel(
      restaurantId: 12,
      name: 'Tavukçu Mehmet',
      city: 'İstanbul',
      district: 'Kadıköy',
      fullAddress: 'Söğütlüçeşme Cad. No:22, Kadıköy',
      latitude: 40.9920,
      longitude: 29.0284,
      categoryName: 'Tavuk',
    ),
    RestaurantModel(
      restaurantId: 13,
      name: 'Pilav Evi',
      city: 'İstanbul',
      district: 'Fatih',
      fullAddress: 'Millet Cad. No:9, Fatih',
      latitude: 41.0198,
      longitude: 28.9397,
      categoryName: 'Tavuk',
    ),
    // ── Kahvaltı ──
    RestaurantModel(
      restaurantId: 14,
      name: 'Sunday Brunch',
      city: 'İstanbul',
      district: 'Moda',
      fullAddress: 'Moda Cad. No:42, Kadıköy',
      latitude: 40.9877,
      longitude: 29.0290,
      categoryName: 'Kahvaltı',
    ),
    RestaurantModel(
      restaurantId: 15,
      name: 'Gözlemeci Hanım',
      city: 'İstanbul',
      district: 'Üsküdar',
      fullAddress: 'Hakimiyeti Milliye Cad. No:7, Üsküdar',
      latitude: 41.0234,
      longitude: 29.0152,
      categoryName: 'Kahvaltı',
    ),
    // ── Tatlı ──
    RestaurantModel(
      restaurantId: 16,
      name: 'Güllüoğlu',
      city: 'İstanbul',
      district: 'Karaköy',
      fullAddress: 'Rıhtım Cad. No:3, Karaköy',
      latitude: 41.0240,
      longitude: 28.9770,
      categoryName: 'Tatlı',
    ),
    RestaurantModel(
      restaurantId: 17,
      name: 'Şanlıurfa Sofrası',
      city: 'İstanbul',
      district: 'Fatih',
      fullAddress: 'Ordu Cad. No:12, Fatih',
      latitude: 41.0188,
      longitude: 28.9410,
      categoryName: 'Tatlı',
    ),
    // ── İtalyan ──
    RestaurantModel(
      restaurantId: 18,
      name: 'La Cucina',
      city: 'İstanbul',
      district: 'Cihangir',
      fullAddress: 'Cihangir Cad. No:29, Beyoğlu',
      latitude: 41.0330,
      longitude: 28.9820,
      categoryName: 'İtalyan',
    ),
    // ── Noodle ──
    RestaurantModel(
      restaurantId: 19,
      name: 'Noodle Bar',
      city: 'İstanbul',
      district: 'Karaköy',
      fullAddress: 'Tersane Cad. No:6, Karaköy',
      latitude: 41.0215,
      longitude: 28.9758,
      categoryName: 'Noodle',
    ),
    // ── Vegan ──
    RestaurantModel(
      restaurantId: 20,
      name: 'Green Bowl',
      city: 'İstanbul',
      district: 'Nişantaşı',
      fullAddress: 'Maçka Cad. No:15, Nişantaşı',
      latitude: 41.0490,
      longitude: 28.9988,
      categoryName: 'Vegan',
    ),
    RestaurantModel(
      restaurantId: 21,
      name: 'Earthly Kitchen',
      city: 'İstanbul',
      district: 'Beyoğlu',
      fullAddress: 'İstiklal Cad. No:82, Beyoğlu',
      latitude: 41.0357,
      longitude: 28.9769,
      categoryName: 'Vegan',
    ),
    // ── Meze ──
    RestaurantModel(
      restaurantId: 22,
      name: 'Sahil Meyhane',
      city: 'İstanbul',
      district: 'Ortaköy',
      fullAddress: 'Muallim Naci Cad. No:4, Ortaköy',
      latitude: 41.0530,
      longitude: 29.0289,
      categoryName: 'Meze',
    ),
    RestaurantModel(
      restaurantId: 23,
      name: 'Kırım Mutfağı',
      city: 'İstanbul',
      district: 'Sarıyer',
      fullAddress: 'Büyükdere Cad. No:33, Sarıyer',
      latitude: 41.1668,
      longitude: 29.0582,
      categoryName: 'Meze',
    ),
  ];

  // ── Menüler ──────────────────────────────────────────────────────────────────

  static final Map<int, List<MenuItemModel>> _menus = {
    // ── 1: Bun Lab (Burger, Kadıköy) ─────────────────────────────────────────
    1: [
      const MenuItemModel(menuItemId: 101, name: 'Double Smash', price: 395, averageRating: 4.9, photoUrl: _burger2, restaurantId: 1, restaurantName: 'Bun Lab', categoryName: 'Burger', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9907, restaurantLongitude: 29.0262),
      const MenuItemModel(menuItemId: 102, name: 'Crispy Chicken Burger', price: 340, averageRating: 4.7, photoUrl: _burger1, restaurantId: 1, restaurantName: 'Bun Lab', categoryName: 'Burger', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9907, restaurantLongitude: 29.0262),
      const MenuItemModel(menuItemId: 103, name: 'Loaded Fries', price: 180, averageRating: 4.6, photoUrl: _fries, restaurantId: 1, restaurantName: 'Bun Lab', categoryName: 'Burger', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9907, restaurantLongitude: 29.0262),
      const MenuItemModel(menuItemId: 104, name: 'Oreo Shake', price: 150, averageRating: 4.5, photoUrl: _tatli, restaurantId: 1, restaurantName: 'Bun Lab', categoryName: 'Tatlı', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9907, restaurantLongitude: 29.0262),
    ],

    // ── 2: Smoke & Grill (Burger, Şişli) ─────────────────────────────────────
    2: [
      const MenuItemModel(menuItemId: 105, name: 'Triple Smash', price: 420, averageRating: 4.9, photoUrl: _burger3, restaurantId: 2, restaurantName: 'Smoke & Grill', categoryName: 'Burger', city: 'İstanbul', district: 'Şişli', restaurantLatitude: 41.0602, restaurantLongitude: 28.9877),
      const MenuItemModel(menuItemId: 106, name: 'BBQ Bacon Burger', price: 380, averageRating: 4.8, photoUrl: _burger1, restaurantId: 2, restaurantName: 'Smoke & Grill', categoryName: 'Burger', city: 'İstanbul', district: 'Şişli', restaurantLatitude: 41.0602, restaurantLongitude: 28.9877),
      const MenuItemModel(menuItemId: 107, name: 'Smoke Ribs', price: 550, averageRating: 4.7, photoUrl: _burger4, restaurantId: 2, restaurantName: 'Smoke & Grill', categoryName: 'Burger', city: 'İstanbul', district: 'Şişli', restaurantLatitude: 41.0602, restaurantLongitude: 28.9877),
      const MenuItemModel(menuItemId: 108, name: 'Peynirli Patates', price: 160, averageRating: 4.6, photoUrl: _fries, restaurantId: 2, restaurantName: 'Smoke & Grill', categoryName: 'Burger', city: 'İstanbul', district: 'Şişli', restaurantLatitude: 41.0602, restaurantLongitude: 28.9877),
    ],

    // ── 3: The Fat Cow (Burger, Bebek) ────────────────────────────────────────
    3: [
      const MenuItemModel(menuItemId: 109, name: 'Wagyu Burger', price: 650, averageRating: 4.8, photoUrl: _burger4, restaurantId: 3, restaurantName: 'The Fat Cow', categoryName: 'Burger', city: 'İstanbul', district: 'Bebek', restaurantLatitude: 41.0774, restaurantLongitude: 29.0396),
      const MenuItemModel(menuItemId: 110, name: 'Truffle Fries', price: 220, averageRating: 4.9, photoUrl: _fries, restaurantId: 3, restaurantName: 'The Fat Cow', categoryName: 'Burger', city: 'İstanbul', district: 'Bebek', restaurantLatitude: 41.0774, restaurantLongitude: 29.0396),
      const MenuItemModel(menuItemId: 111, name: 'Burrata Salatası', price: 280, averageRating: 4.7, photoUrl: _vegan1, restaurantId: 3, restaurantName: 'The Fat Cow', categoryName: 'Vegan', city: 'İstanbul', district: 'Bebek', restaurantLatitude: 41.0774, restaurantLongitude: 29.0396),
      const MenuItemModel(menuItemId: 112, name: 'Çikolata Fondanı', price: 190, averageRating: 4.6, photoUrl: _tatli, restaurantId: 3, restaurantName: 'The Fat Cow', categoryName: 'Tatlı', city: 'İstanbul', district: 'Bebek', restaurantLatitude: 41.0774, restaurantLongitude: 29.0396),
    ],

    // ── 4: Burger Joint (Burger, Beşiktaş) ───────────────────────────────────
    4: [
      const MenuItemModel(menuItemId: 113, name: 'Smash Burger', price: 320, averageRating: 4.7, photoUrl: _burger1, restaurantId: 4, restaurantName: 'Burger Joint', categoryName: 'Burger', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0422, restaurantLongitude: 29.0056),
      const MenuItemModel(menuItemId: 114, name: 'Jalapeno Burger', price: 350, averageRating: 4.6, photoUrl: _burger2, restaurantId: 4, restaurantName: 'Burger Joint', categoryName: 'Burger', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0422, restaurantLongitude: 29.0056),
      const MenuItemModel(menuItemId: 115, name: 'Mushroom Swiss Burger', price: 360, averageRating: 4.5, photoUrl: _burger3, restaurantId: 4, restaurantName: 'Burger Joint', categoryName: 'Burger', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0422, restaurantLongitude: 29.0056),
      const MenuItemModel(menuItemId: 116, name: 'Sweet Potato Fries', price: 140, averageRating: 4.4, photoUrl: _fries, restaurantId: 4, restaurantName: 'Burger Joint', categoryName: 'Burger', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0422, restaurantLongitude: 29.0056),
    ],

    // ── 5: Forno di Napoli (Pizza, Galata) ───────────────────────────────────
    5: [
      const MenuItemModel(menuItemId: 117, name: 'Pepperoni Calzone', price: 380, averageRating: 4.7, photoUrl: _pizza2, restaurantId: 5, restaurantName: 'Forno di Napoli', categoryName: 'Pizza', city: 'İstanbul', district: 'Galata', restaurantLatitude: 41.0256, restaurantLongitude: 28.9744),
      const MenuItemModel(menuItemId: 118, name: 'Margherita DOC', price: 320, averageRating: 4.8, photoUrl: _pizza1, restaurantId: 5, restaurantName: 'Forno di Napoli', categoryName: 'Pizza', city: 'İstanbul', district: 'Galata', restaurantLatitude: 41.0256, restaurantLongitude: 28.9744),
      const MenuItemModel(menuItemId: 119, name: 'Quattro Formaggi', price: 360, averageRating: 4.6, photoUrl: _pizza1, restaurantId: 5, restaurantName: 'Forno di Napoli', categoryName: 'Pizza', city: 'İstanbul', district: 'Galata', restaurantLatitude: 41.0256, restaurantLongitude: 28.9744),
      const MenuItemModel(menuItemId: 120, name: 'Tiramisu', price: 180, averageRating: 4.9, photoUrl: _tatli, restaurantId: 5, restaurantName: 'Forno di Napoli', categoryName: 'Tatlı', city: 'İstanbul', district: 'Galata', restaurantLatitude: 41.0256, restaurantLongitude: 28.9744),
    ],

    // ── 6: Pizza Napoli (Pizza, Nişantaşı) ───────────────────────────────────
    6: [
      const MenuItemModel(menuItemId: 121, name: 'Diavola', price: 350, averageRating: 4.7, photoUrl: _pizza1, restaurantId: 6, restaurantName: 'Pizza Napoli', categoryName: 'Pizza', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0503, restaurantLongitude: 28.9998),
      const MenuItemModel(menuItemId: 122, name: 'Prosciutto e Funghi', price: 370, averageRating: 4.6, photoUrl: _pizza2, restaurantId: 6, restaurantName: 'Pizza Napoli', categoryName: 'Pizza', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0503, restaurantLongitude: 28.9998),
      const MenuItemModel(menuItemId: 123, name: 'Burrata Bruschetta', price: 220, averageRating: 4.5, photoUrl: _vegan1, restaurantId: 6, restaurantName: 'Pizza Napoli', categoryName: 'İtalyan', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0503, restaurantLongitude: 28.9998),
      const MenuItemModel(menuItemId: 124, name: 'Panna Cotta', price: 160, averageRating: 4.4, photoUrl: _tatli, restaurantId: 6, restaurantName: 'Pizza Napoli', categoryName: 'Tatlı', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0503, restaurantLongitude: 28.9998),
    ],

    // ── 7: Sushi Kaito (Sushi, Nişantaşı) ────────────────────────────────────
    7: [
      const MenuItemModel(menuItemId: 125, name: 'Omakase Set (10 pcs)', price: 1200, averageRating: 5.0, photoUrl: _sushi2, restaurantId: 7, restaurantName: 'Sushi Kaito', categoryName: 'Sushi', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0492, restaurantLongitude: 29.0008),
      const MenuItemModel(menuItemId: 126, name: 'Salmon Nigiri (8 adet)', price: 480, averageRating: 4.8, photoUrl: _sushi1, restaurantId: 7, restaurantName: 'Sushi Kaito', categoryName: 'Sushi', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0492, restaurantLongitude: 29.0008),
      const MenuItemModel(menuItemId: 127, name: 'Dragon Roll', price: 520, averageRating: 4.9, photoUrl: _sushi1, restaurantId: 7, restaurantName: 'Sushi Kaito', categoryName: 'Sushi', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0492, restaurantLongitude: 29.0008),
      const MenuItemModel(menuItemId: 128, name: 'Miso Çorbası', price: 120, averageRating: 4.5, photoUrl: _vegan2, restaurantId: 7, restaurantName: 'Sushi Kaito', categoryName: 'Noodle', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0492, restaurantLongitude: 29.0008),
    ],

    // ── 8: Nobu Istanbul (Sushi, Etiler) ─────────────────────────────────────
    8: [
      const MenuItemModel(menuItemId: 129, name: 'Tuna Tataki', price: 480, averageRating: 4.6, photoUrl: _sushi1, restaurantId: 8, restaurantName: 'Nobu Istanbul', categoryName: 'Sushi', city: 'İstanbul', district: 'Etiler', restaurantLatitude: 41.0794, restaurantLongitude: 29.0235),
      const MenuItemModel(menuItemId: 130, name: 'Black Cod Miso', price: 750, averageRating: 4.9, photoUrl: _sushi2, restaurantId: 8, restaurantName: 'Nobu Istanbul', categoryName: 'Sushi', city: 'İstanbul', district: 'Etiler', restaurantLatitude: 41.0794, restaurantLongitude: 29.0235),
      const MenuItemModel(menuItemId: 131, name: 'Yellowtail Jalapeño', price: 620, averageRating: 4.8, photoUrl: _sushi1, restaurantId: 8, restaurantName: 'Nobu Istanbul', categoryName: 'Sushi', city: 'İstanbul', district: 'Etiler', restaurantLatitude: 41.0794, restaurantLongitude: 29.0235),
      const MenuItemModel(menuItemId: 132, name: 'Wagyu Gyoza', price: 560, averageRating: 4.7, photoUrl: _sushi2, restaurantId: 8, restaurantName: 'Nobu Istanbul', categoryName: 'Sushi', city: 'İstanbul', district: 'Etiler', restaurantLatitude: 41.0794, restaurantLongitude: 29.0235),
    ],

    // ── 9: Ocakbaşı 1969 (Kebap, Karaköy) ────────────────────────────────────
    9: [
      const MenuItemModel(menuItemId: 133, name: 'Adana Kebap', price: 350, averageRating: 4.8, photoUrl: _kebap1, restaurantId: 9, restaurantName: 'Ocakbaşı 1969', categoryName: 'Kebap', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0231, restaurantLongitude: 28.9766),
      const MenuItemModel(menuItemId: 134, name: 'Urfa Kebap', price: 340, averageRating: 4.7, photoUrl: _kebap1, restaurantId: 9, restaurantName: 'Ocakbaşı 1969', categoryName: 'Kebap', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0231, restaurantLongitude: 28.9766),
      const MenuItemModel(menuItemId: 135, name: 'Kuzu Şiş', price: 420, averageRating: 4.9, photoUrl: _kebap1, restaurantId: 9, restaurantName: 'Ocakbaşı 1969', categoryName: 'Kebap', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0231, restaurantLongitude: 28.9766),
      const MenuItemModel(menuItemId: 136, name: 'Patlıcan Kebabı', price: 380, averageRating: 4.6, photoUrl: _kebap1, restaurantId: 9, restaurantName: 'Ocakbaşı 1969', categoryName: 'Kebap', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0231, restaurantLongitude: 28.9766),
    ],

    // ── 10: Karadeniz Döner (Kebap, Beşiktaş) ────────────────────────────────
    10: [
      const MenuItemModel(menuItemId: 137, name: 'Dürüm Döner', price: 120, averageRating: 4.5, photoUrl: _kebap2, restaurantId: 10, restaurantName: 'Karadeniz Döner', categoryName: 'Kebap', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0430, restaurantLongitude: 29.0030),
      const MenuItemModel(menuItemId: 138, name: 'Ekmek Arası Döner', price: 100, averageRating: 4.4, photoUrl: _kebap2, restaurantId: 10, restaurantName: 'Karadeniz Döner', categoryName: 'Kebap', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0430, restaurantLongitude: 29.0030),
      const MenuItemModel(menuItemId: 139, name: 'Yarım Porsiyon', price: 80, averageRating: 4.3, photoUrl: _kebap2, restaurantId: 10, restaurantName: 'Karadeniz Döner', categoryName: 'Kebap', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0430, restaurantLongitude: 29.0030),
      const MenuItemModel(menuItemId: 140, name: 'Tavuk Dürüm', price: 110, averageRating: 4.4, photoUrl: _tavuk, restaurantId: 10, restaurantName: 'Karadeniz Döner', categoryName: 'Tavuk', city: 'İstanbul', district: 'Beşiktaş', restaurantLatitude: 41.0430, restaurantLongitude: 29.0030),
    ],

    // ── 11: Mersin Tantunisi (Kebap, Bağcılar) ───────────────────────────────
    11: [
      const MenuItemModel(menuItemId: 141, name: 'Tantuni', price: 180, averageRating: 4.9, photoUrl: _kebap2, restaurantId: 11, restaurantName: 'Mersin Tantunisi', categoryName: 'Kebap', city: 'İstanbul', district: 'Bağcılar', restaurantLatitude: 41.0353, restaurantLongitude: 28.8560),
      const MenuItemModel(menuItemId: 142, name: 'Dürüm Tantuni', price: 200, averageRating: 4.8, photoUrl: _kebap2, restaurantId: 11, restaurantName: 'Mersin Tantunisi', categoryName: 'Kebap', city: 'İstanbul', district: 'Bağcılar', restaurantLatitude: 41.0353, restaurantLongitude: 28.8560),
      const MenuItemModel(menuItemId: 143, name: 'Acılı Tantuni', price: 190, averageRating: 4.7, photoUrl: _kebap1, restaurantId: 11, restaurantName: 'Mersin Tantunisi', categoryName: 'Kebap', city: 'İstanbul', district: 'Bağcılar', restaurantLatitude: 41.0353, restaurantLongitude: 28.8560),
      const MenuItemModel(menuItemId: 144, name: 'Şalgam Suyu', price: 30, averageRating: 4.5, photoUrl: _vegan2, restaurantId: 11, restaurantName: 'Mersin Tantunisi', categoryName: 'Vegan', city: 'İstanbul', district: 'Bağcılar', restaurantLatitude: 41.0353, restaurantLongitude: 28.8560),
    ],

    // ── 12: Tavukçu Mehmet (Tavuk, Kadıköy) ──────────────────────────────────
    12: [
      const MenuItemModel(menuItemId: 145, name: 'Izgara Tavuk', price: 280, averageRating: 4.7, photoUrl: _tavuk, restaurantId: 12, restaurantName: 'Tavukçu Mehmet', categoryName: 'Tavuk', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9920, restaurantLongitude: 29.0284),
      const MenuItemModel(menuItemId: 146, name: 'Tavuk Şiş', price: 260, averageRating: 4.6, photoUrl: _tavuk, restaurantId: 12, restaurantName: 'Tavukçu Mehmet', categoryName: 'Tavuk', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9920, restaurantLongitude: 29.0284),
      const MenuItemModel(menuItemId: 147, name: 'Kanat (8 adet)', price: 240, averageRating: 4.8, photoUrl: _tavuk, restaurantId: 12, restaurantName: 'Tavukçu Mehmet', categoryName: 'Tavuk', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9920, restaurantLongitude: 29.0284),
      const MenuItemModel(menuItemId: 148, name: 'Pilav Üstü Tavuk', price: 220, averageRating: 4.5, photoUrl: _tavuk, restaurantId: 12, restaurantName: 'Tavukçu Mehmet', categoryName: 'Tavuk', city: 'İstanbul', district: 'Kadıköy', restaurantLatitude: 40.9920, restaurantLongitude: 29.0284),
    ],

    // ── 13: Pilav Evi (Tavuk, Fatih) ─────────────────────────────────────────
    13: [
      const MenuItemModel(menuItemId: 149, name: 'Tavuklu Pilav', price: 130, averageRating: 4.6, photoUrl: _tavuk, restaurantId: 13, restaurantName: 'Pilav Evi', categoryName: 'Tavuk', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0198, restaurantLongitude: 28.9397),
      const MenuItemModel(menuItemId: 150, name: 'İzgara + Pilav', price: 200, averageRating: 4.5, photoUrl: _tavuk, restaurantId: 13, restaurantName: 'Pilav Evi', categoryName: 'Tavuk', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0198, restaurantLongitude: 28.9397),
      const MenuItemModel(menuItemId: 151, name: 'Mercimek Çorbası', price: 80, averageRating: 4.8, photoUrl: _vegan2, restaurantId: 13, restaurantName: 'Pilav Evi', categoryName: 'Vegan', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0198, restaurantLongitude: 28.9397),
      const MenuItemModel(menuItemId: 152, name: 'Sütlaç', price: 90, averageRating: 4.7, photoUrl: _tatli, restaurantId: 13, restaurantName: 'Pilav Evi', categoryName: 'Tatlı', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0198, restaurantLongitude: 28.9397),
    ],

    // ── 14: Sunday Brunch (Kahvaltı, Moda) ───────────────────────────────────
    14: [
      const MenuItemModel(menuItemId: 153, name: 'Eggs Benedict', price: 290, averageRating: 4.7, photoUrl: _kahvalti1, restaurantId: 14, restaurantName: 'Sunday Brunch', categoryName: 'Kahvaltı', city: 'İstanbul', district: 'Moda', restaurantLatitude: 40.9877, restaurantLongitude: 29.0290),
      const MenuItemModel(menuItemId: 154, name: 'Avocado Toast', price: 220, averageRating: 4.5, photoUrl: _kahvalti2, restaurantId: 14, restaurantName: 'Sunday Brunch', categoryName: 'Kahvaltı', city: 'İstanbul', district: 'Moda', restaurantLatitude: 40.9877, restaurantLongitude: 29.0290),
      const MenuItemModel(menuItemId: 155, name: 'French Pancakes', price: 250, averageRating: 4.8, photoUrl: _tatli, restaurantId: 14, restaurantName: 'Sunday Brunch', categoryName: 'Tatlı', city: 'İstanbul', district: 'Moda', restaurantLatitude: 40.9877, restaurantLongitude: 29.0290),
      const MenuItemModel(menuItemId: 156, name: 'Granola Bowl', price: 200, averageRating: 4.4, photoUrl: _vegan1, restaurantId: 14, restaurantName: 'Sunday Brunch', categoryName: 'Kahvaltı', city: 'İstanbul', district: 'Moda', restaurantLatitude: 40.9877, restaurantLongitude: 29.0290),
    ],

    // ── 15: Gözlemeci Hanım (Kahvaltı, Üsküdar) ──────────────────────────────
    15: [
      const MenuItemModel(menuItemId: 157, name: 'Karışık Gözleme', price: 95, averageRating: 4.7, photoUrl: _kahvalti1, restaurantId: 15, restaurantName: 'Gözlemeci Hanım', categoryName: 'Kahvaltı', city: 'İstanbul', district: 'Üsküdar', restaurantLatitude: 41.0234, restaurantLongitude: 29.0152),
      const MenuItemModel(menuItemId: 158, name: 'Peynirli Gözleme', price: 80, averageRating: 4.6, photoUrl: _kahvalti1, restaurantId: 15, restaurantName: 'Gözlemeci Hanım', categoryName: 'Kahvaltı', city: 'İstanbul', district: 'Üsküdar', restaurantLatitude: 41.0234, restaurantLongitude: 29.0152),
      const MenuItemModel(menuItemId: 159, name: 'Ispanaklı Gözleme', price: 85, averageRating: 4.5, photoUrl: _vegan1, restaurantId: 15, restaurantName: 'Gözlemeci Hanım', categoryName: 'Vegan', city: 'İstanbul', district: 'Üsküdar', restaurantLatitude: 41.0234, restaurantLongitude: 29.0152),
      const MenuItemModel(menuItemId: 160, name: 'Çay', price: 15, averageRating: 4.9, photoUrl: _kahvalti2, restaurantId: 15, restaurantName: 'Gözlemeci Hanım', categoryName: 'Kahvaltı', city: 'İstanbul', district: 'Üsküdar', restaurantLatitude: 41.0234, restaurantLongitude: 29.0152),
    ],

    // ── 16: Güllüoğlu (Tatlı, Karaköy) ──────────────────────────────────────
    16: [
      const MenuItemModel(menuItemId: 161, name: 'Fıstıklı Baklava', price: 120, averageRating: 4.9, photoUrl: _tatli, restaurantId: 16, restaurantName: 'Güllüoğlu', categoryName: 'Tatlı', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0240, restaurantLongitude: 28.9770),
      const MenuItemModel(menuItemId: 162, name: 'Sütlü Nuriye', price: 100, averageRating: 4.8, photoUrl: _tatli, restaurantId: 16, restaurantName: 'Güllüoğlu', categoryName: 'Tatlı', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0240, restaurantLongitude: 28.9770),
      const MenuItemModel(menuItemId: 163, name: 'Cevizli Baklava', price: 110, averageRating: 4.7, photoUrl: _tatli, restaurantId: 16, restaurantName: 'Güllüoğlu', categoryName: 'Tatlı', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0240, restaurantLongitude: 28.9770),
      const MenuItemModel(menuItemId: 164, name: 'Burma Kadayıf', price: 115, averageRating: 4.8, photoUrl: _tatli, restaurantId: 16, restaurantName: 'Güllüoğlu', categoryName: 'Tatlı', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0240, restaurantLongitude: 28.9770),
    ],

    // ── 17: Şanlıurfa Sofrası (Tatlı, Fatih) ─────────────────────────────────
    17: [
      const MenuItemModel(menuItemId: 165, name: 'Künefe', price: 180, averageRating: 4.9, photoUrl: _tatli, restaurantId: 17, restaurantName: 'Şanlıurfa Sofrası', categoryName: 'Tatlı', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0188, restaurantLongitude: 28.9410),
      const MenuItemModel(menuItemId: 166, name: 'Sütlü Künefe', price: 190, averageRating: 4.8, photoUrl: _tatli, restaurantId: 17, restaurantName: 'Şanlıurfa Sofrası', categoryName: 'Tatlı', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0188, restaurantLongitude: 28.9410),
      const MenuItemModel(menuItemId: 167, name: 'Adana Kebap', price: 320, averageRating: 4.7, photoUrl: _kebap1, restaurantId: 17, restaurantName: 'Şanlıurfa Sofrası', categoryName: 'Kebap', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0188, restaurantLongitude: 28.9410),
      const MenuItemModel(menuItemId: 168, name: 'Ayran', price: 25, averageRating: 4.5, photoUrl: _vegan2, restaurantId: 17, restaurantName: 'Şanlıurfa Sofrası', categoryName: 'Vegan', city: 'İstanbul', district: 'Fatih', restaurantLatitude: 41.0188, restaurantLongitude: 28.9410),
    ],

    // ── 18: La Cucina (İtalyan, Cihangir) ────────────────────────────────────
    18: [
      const MenuItemModel(menuItemId: 169, name: 'Truffle Risotto', price: 520, averageRating: 4.8, photoUrl: _italyan2, restaurantId: 18, restaurantName: 'La Cucina', categoryName: 'İtalyan', city: 'İstanbul', district: 'Cihangir', restaurantLatitude: 41.0330, restaurantLongitude: 28.9820),
      const MenuItemModel(menuItemId: 170, name: 'Truffle Carbonara', price: 460, averageRating: 4.8, photoUrl: _italyan1, restaurantId: 18, restaurantName: 'La Cucina', categoryName: 'İtalyan', city: 'İstanbul', district: 'Cihangir', restaurantLatitude: 41.0330, restaurantLongitude: 28.9820),
      const MenuItemModel(menuItemId: 171, name: 'Burrata & Pomodoro', price: 380, averageRating: 4.7, photoUrl: _vegan1, restaurantId: 18, restaurantName: 'La Cucina', categoryName: 'İtalyan', city: 'İstanbul', district: 'Cihangir', restaurantLatitude: 41.0330, restaurantLongitude: 28.9820),
      const MenuItemModel(menuItemId: 172, name: 'Tiramisu della Casa', price: 240, averageRating: 4.9, photoUrl: _tatli, restaurantId: 18, restaurantName: 'La Cucina', categoryName: 'Tatlı', city: 'İstanbul', district: 'Cihangir', restaurantLatitude: 41.0330, restaurantLongitude: 28.9820),
    ],

    // ── 19: Noodle Bar (Noodle, Karaköy) ─────────────────────────────────────
    19: [
      const MenuItemModel(menuItemId: 173, name: 'Ramen', price: 320, averageRating: 4.8, photoUrl: _noodle, restaurantId: 19, restaurantName: 'Noodle Bar', categoryName: 'Noodle', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0215, restaurantLongitude: 28.9758),
      const MenuItemModel(menuItemId: 174, name: 'Spicy Miso Ramen', price: 340, averageRating: 4.7, photoUrl: _noodle, restaurantId: 19, restaurantName: 'Noodle Bar', categoryName: 'Noodle', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0215, restaurantLongitude: 28.9758),
      const MenuItemModel(menuItemId: 175, name: 'Pad Thai', price: 300, averageRating: 4.6, photoUrl: _noodle, restaurantId: 19, restaurantName: 'Noodle Bar', categoryName: 'Noodle', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0215, restaurantLongitude: 28.9758),
      const MenuItemModel(menuItemId: 176, name: 'Gyoza (6 adet)', price: 180, averageRating: 4.5, photoUrl: _sushi1, restaurantId: 19, restaurantName: 'Noodle Bar', categoryName: 'Noodle', city: 'İstanbul', district: 'Karaköy', restaurantLatitude: 41.0215, restaurantLongitude: 28.9758),
    ],

    // ── 20: Green Bowl (Vegan, Nişantaşı) ────────────────────────────────────
    20: [
      const MenuItemModel(menuItemId: 177, name: 'Quinoa Power Bowl', price: 280, averageRating: 4.6, photoUrl: _vegan1, restaurantId: 20, restaurantName: 'Green Bowl', categoryName: 'Vegan', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0490, restaurantLongitude: 28.9988),
      const MenuItemModel(menuItemId: 178, name: 'Açık Avocado Sandviç', price: 220, averageRating: 4.5, photoUrl: _kahvalti2, restaurantId: 20, restaurantName: 'Green Bowl', categoryName: 'Vegan', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0490, restaurantLongitude: 28.9988),
      const MenuItemModel(menuItemId: 179, name: 'Mercimek Köftesi', price: 160, averageRating: 4.7, photoUrl: _vegan2, restaurantId: 20, restaurantName: 'Green Bowl', categoryName: 'Vegan', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0490, restaurantLongitude: 28.9988),
      const MenuItemModel(menuItemId: 180, name: 'Chia Pudding', price: 140, averageRating: 4.4, photoUrl: _tatli, restaurantId: 20, restaurantName: 'Green Bowl', categoryName: 'Vegan', city: 'İstanbul', district: 'Nişantaşı', restaurantLatitude: 41.0490, restaurantLongitude: 28.9988),
    ],

    // ── 21: Earthly Kitchen (Vegan, Beyoğlu) ─────────────────────────────────
    21: [
      const MenuItemModel(menuItemId: 181, name: 'Vegan Burger', price: 260, averageRating: 4.5, photoUrl: _burger1, restaurantId: 21, restaurantName: 'Earthly Kitchen', categoryName: 'Vegan', city: 'İstanbul', district: 'Beyoğlu', restaurantLatitude: 41.0357, restaurantLongitude: 28.9769),
      const MenuItemModel(menuItemId: 182, name: 'Buddha Bowl', price: 290, averageRating: 4.6, photoUrl: _vegan1, restaurantId: 21, restaurantName: 'Earthly Kitchen', categoryName: 'Vegan', city: 'İstanbul', district: 'Beyoğlu', restaurantLatitude: 41.0357, restaurantLongitude: 28.9769),
      const MenuItemModel(menuItemId: 183, name: 'Falafel Tabağı', price: 200, averageRating: 4.7, photoUrl: _vegan2, restaurantId: 21, restaurantName: 'Earthly Kitchen', categoryName: 'Vegan', city: 'İstanbul', district: 'Beyoğlu', restaurantLatitude: 41.0357, restaurantLongitude: 28.9769),
      const MenuItemModel(menuItemId: 184, name: 'Raw Cheesecake', price: 170, averageRating: 4.4, photoUrl: _tatli, restaurantId: 21, restaurantName: 'Earthly Kitchen', categoryName: 'Vegan', city: 'İstanbul', district: 'Beyoğlu', restaurantLatitude: 41.0357, restaurantLongitude: 28.9769),
    ],

    // ── 22: Sahil Meyhane (Meze, Ortaköy) ────────────────────────────────────
    22: [
      const MenuItemModel(menuItemId: 185, name: 'Midye Dolma (12 adet)', price: 250, averageRating: 4.7, photoUrl: _sushi1, restaurantId: 22, restaurantName: 'Sahil Meyhane', categoryName: 'Meze', city: 'İstanbul', district: 'Ortaköy', restaurantLatitude: 41.0530, restaurantLongitude: 29.0289),
      const MenuItemModel(menuItemId: 186, name: 'Enginar Zeytinyağlı', price: 180, averageRating: 4.6, photoUrl: _vegan1, restaurantId: 22, restaurantName: 'Sahil Meyhane', categoryName: 'Meze', city: 'İstanbul', district: 'Ortaköy', restaurantLatitude: 41.0530, restaurantLongitude: 29.0289),
      const MenuItemModel(menuItemId: 187, name: 'Balık Tava', price: 420, averageRating: 4.8, photoUrl: _sushi2, restaurantId: 22, restaurantName: 'Sahil Meyhane', categoryName: 'Meze', city: 'İstanbul', district: 'Ortaköy', restaurantLatitude: 41.0530, restaurantLongitude: 29.0289),
      const MenuItemModel(menuItemId: 188, name: 'Cacık', price: 90, averageRating: 4.5, photoUrl: _vegan2, restaurantId: 22, restaurantName: 'Sahil Meyhane', categoryName: 'Meze', city: 'İstanbul', district: 'Ortaköy', restaurantLatitude: 41.0530, restaurantLongitude: 29.0289),
    ],

    // ── 23: Kırım Mutfağı (Meze, Sarıyer) ────────────────────────────────────
    23: [
      const MenuItemModel(menuItemId: 189, name: 'Çiğ Börek', price: 140, averageRating: 4.8, photoUrl: _kahvalti1, restaurantId: 23, restaurantName: 'Kırım Mutfağı', categoryName: 'Meze', city: 'İstanbul', district: 'Sarıyer', restaurantLatitude: 41.1668, restaurantLongitude: 29.0582),
      const MenuItemModel(menuItemId: 190, name: 'Çerkes Tavuğu', price: 280, averageRating: 4.7, photoUrl: _tavuk, restaurantId: 23, restaurantName: 'Kırım Mutfağı', categoryName: 'Meze', city: 'İstanbul', district: 'Sarıyer', restaurantLatitude: 41.1668, restaurantLongitude: 29.0582),
      const MenuItemModel(menuItemId: 191, name: 'Hamur Kızartması', price: 120, averageRating: 4.6, photoUrl: _kahvalti2, restaurantId: 23, restaurantName: 'Kırım Mutfağı', categoryName: 'Meze', city: 'İstanbul', district: 'Sarıyer', restaurantLatitude: 41.1668, restaurantLongitude: 29.0582),
      const MenuItemModel(menuItemId: 192, name: 'Elma Kompostosu', price: 60, averageRating: 4.4, photoUrl: _tatli, restaurantId: 23, restaurantName: 'Kırım Mutfağı', categoryName: 'Meze', city: 'İstanbul', district: 'Sarıyer', restaurantLatitude: 41.1668, restaurantLongitude: 29.0582),
    ],
  };

  // ── Mock yazma işlemleri için in-memory storage ───────────────────────────────

  static final List<RatingModel> _mockRatings = [];
  static int _nextRatingId = 1000;

  static final List<WishlistModel> _mockWishlist = [];
  static int _nextWishId = 1000;

  // ── Yardımcı metodlar ────────────────────────────────────────────────────────

  static List<MenuItemModel> getMenu(int restaurantId) =>
      _menus[restaurantId] ?? [];

  /// Tüm menüler içinde ID ile ürün ara
  static MenuItemModel? getMenuItemById(int id) {
    for (final items in _menus.values) {
      for (final item in items) {
        if (item.menuItemId == id) return item;
      }
    }
    return null;
  }

  static List<RestaurantModel> searchRestaurants(String name) {
    final q = name.toLowerCase();
    return restaurants
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.district?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  static List<MenuItemModel> searchMenuItems(String query) {
    final all = _menus.values.expand((items) => items).toList();
    final q = query.toLowerCase();
    return all
        .where((item) =>
            item.name.toLowerCase().contains(q) ||
            (item.categoryName?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ── Rating mock işlemleri ─────────────────────────────────────────────────────

  static List<RatingModel> getMockRatings(int userId) =>
      List.unmodifiable(_mockRatings);

  static void addMockRating({
    required int userId,
    required int menuItemId,
    required double score,
    String? comment,
  }) {
    // Aynı item için önceki puanı sil (upsert davranışı)
    _mockRatings.removeWhere(
      (r) => r.userId == userId && r.menuItemId == menuItemId,
    );
    final item = getMenuItemById(menuItemId);
    _mockRatings.add(RatingModel(
      ratingId: _nextRatingId++,
      userId: userId,
      username: 'emir_test',
      menuItemId: menuItemId,
      menuItemName: item?.name ?? 'Bilinmeyen Yemek',
      photoUrl: item?.photoUrl,
      restaurantName: item?.restaurantName ?? 'Bilinmeyen Restoran',
      categoryName: item?.categoryName,
      score: score,
      comment: (comment?.isEmpty ?? true) ? null : comment,
      ratedAt: DateTime.now(),
    ));
  }

  static void removeMockRating(int ratingId) =>
      _mockRatings.removeWhere((r) => r.ratingId == ratingId);

  // ── Wishlist mock işlemleri ───────────────────────────────────────────────────

  static List<WishlistModel> getMockWishlist() =>
      List.unmodifiable(_mockWishlist);

  static void addMockWishlistItem(int menuItemId) {
    // Zaten varsa tekrar ekleme
    if (_mockWishlist.any((w) => w.menuItemId == menuItemId)) return;
    final item = getMenuItemById(menuItemId);
    _mockWishlist.add(WishlistModel(
      wishId: _nextWishId++,
      menuItemId: menuItemId,
      menuItemName: item?.name ?? 'Bilinmeyen Yemek',
      restaurantId: item?.restaurantId ?? 0,
      restaurantName: item?.restaurantName ?? 'Bilinmeyen Restoran',
      averageRating: item?.averageRating ?? 0.0,
      price: item?.price,
    ));
  }

  static void removeMockWishlistItem(int wishId) =>
      _mockWishlist.removeWhere((w) => w.wishId == wishId);

  static void removeMockWishlistByMenuItemId(int menuItemId) =>
      _mockWishlist.removeWhere((w) => w.menuItemId == menuItemId);
}

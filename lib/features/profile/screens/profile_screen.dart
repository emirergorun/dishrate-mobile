import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_info.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/constants/app_links.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/network/user_repository.dart';
import '../../../core/network/wishlist_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/rating_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/wishlist_model.dart';
import '../../../shared/providers/data_refresh.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/swipe_to_delete.dart';
import '../../../shared/widgets/main_scaffold.dart';
import '../widgets/profile_photo_editor.dart';

import '../../../core/utils/password_validator.dart';
import '../../rating/providers/rating_flow_provider.dart';
import '../../rating/screens/add_rating_screen.dart';
import '../../settings/screens/settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _user;
  List<RatingModel> _ratings = [];
  List<WishlistModel> _wishlist = [];
  bool _isLoading = true;

  /// İlk yükleme başarısız oldu; ekranda boş profil yerine hata mesajı çıkar.
  bool _failed = false;

  /// Başlıktaki avatardan başlatılan fotoğraf işlemi sürüyor mu?
  bool _photoBusy = false;

  /// En yüksek puanlı 5 değerlendirme (favori yemekler).
  List<RatingModel> get _topFavorites {
    final sorted = [..._ratings]..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Başlıktaki avatardan fotoğraf değiştirme. "Profili Düzenle" panelinden
  /// farklı olarak burada Kaydet adımı yok — seçim yapılır yapılmaz kaydedilir.
  Future<void> _editPhoto(UserModel user) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final result = await ProfilePhotoEditor.edit(context, user: user);
      if (!mounted || result == null) return;

      final updated = await UserRepository.instance.updateUser(
        user.userId,
        profilePhotoUrl: result.photoUrl,
        profilePhotoOriginalUrl: result.originalUrl,
        profilePhotoCrop: result.crop,
      );
      if (!mounted) return;
      setState(() => _user = updated);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf güncellenemedi, tekrar dene.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _load({bool silent = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (!silent) {
      setState(() {
        _isLoading = true;
        _failed = false;
      });
    }
    try {
      final results = await Future.wait([
        UserRepository.instance.getUser(userId),
        RatingRepository.instance.getRatingsByUser(userId),
        WishlistRepository.instance.getWishlist(userId),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0] as UserModel;
          _ratings = results[1] as List<RatingModel>;
          _wishlist = results[2] as List<WishlistModel>;
          _failed = false;
        });
      }
    } catch (_) {
      // Eldeki profil varsa (sessiz tazeleme) o kalır. Yoksa önceden ad "—",
      // sayılar 0 görünüyordu; kullanıcı verisinin silindiğini sanabilirdi.
      if (mounted && _user == null) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Sheet açıcılar ──────────────────────────────────────────────────────────

  /// Panel eldeki listeyle hemen açılır. Önceden sunucudan tazeleme beklenirdi;
  /// bağlantı yokken zaman aşımı dolana kadar (10 sn) düğme tepkisiz kalıyordu.
  /// Tazeleme arka planda döner; sayaç ve bir sonraki açılış güncellenir.
  ///
  /// [waitForFresh] yemek panelindeki "Tümünü gör" içindir: liste, az önce
  /// eklenen ürünü içermeli. Orada da tazeleme sınırsız beklenmez.
  Future<void> _showWishlist({bool waitForFresh = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final refresh = _refreshWishlist(userId);
    if (waitForFresh) {
      await refresh.timeout(const Duration(seconds: 2), onTimeout: () {});
      if (!mounted) return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => _WishlistSheet(
        wishlist: _wishlist,
        onRemove: (wishId) async {
          await WishlistRepository.instance.removeFromWishlist(wishId);
          if (mounted) {
            setState(() => _wishlist.removeWhere((w) => w.wishId == wishId));
          }
        },
        onRate: _openRatingForWishlistItem,
        onRemoveFailedAfterClose: _notifyRemoveFailed,
      ),
    );
  }

  /// Panel kapandıktan sonra düşen çıkarma isteği: ürün listede kaldı.
  void _notifyRemoveFailed(WishlistModel item) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.menuItemName} listeden çıkarılamadı, '
            'tekrar dene.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// İstek listesini arka planda tazeler; ulaşılamazsa eldeki liste kalır.
  Future<void> _refreshWishlist(int userId) async {
    try {
      final fresh = await WishlistRepository.instance.getWishlist(userId);
      if (mounted) setState(() => _wishlist = fresh);
    } catch (_) {
      // Sessiz: açık panel eldeki listeyi göstermeye devam eder.
    }
  }

  /// İstek listesindeki bir ürünü doğrudan puanlama ekranına gönderir.
  void _openRatingForWishlistItem(WishlistModel wish) {
    final menuItem = MenuItemModel(
      menuItemId: wish.menuItemId,
      name: wish.menuItemName,
      averageRating: wish.averageRating,
      restaurantId: wish.restaurantId,
      restaurantName: wish.restaurantName,
    );

    final restaurant = RestaurantModel(
      restaurantId: wish.restaurantId,
      name: wish.restaurantName,
      city: 'İstanbul',
      fullAddress: wish.restaurantName,
    );

    ref.read(ratingFlowProvider.notifier).jumpToRateItem(restaurant, menuItem);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfileRatingSheet(),
    );
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => _FavoritesSheet(favorites: _topFavorites),
    );
  }

  void _showEditProfile() {
    if (_user == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => _EditProfileSheet(
        user: _user!,
        onSave: (updated) {
          setState(() => _user = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil güncellendi.')),
          );
        },
      ),
    );
  }

  void _showChangePassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  /// "Bize ulaş": posta uygulamasını destek adresiyle açar. Önceden bir
  /// panel açılıyor, satırlara basınca yalnızca adres şerit olarak
  /// görünüyordu (1.6). Posta uygulaması yoksa adres panoya kopyalanır.
  Future<void> _contactUs() async {
    // Sürüm destek için işe yarıyor; okunamazsa posta onsuz açılır.
    String? version;
    try {
      version = await ref.read(appVersionProvider.future);
    } catch (_) {}
    final uri = Uri(
      scheme: 'mailto',
      path: AppLinks.supportEmail,
      // `queryParameters` boşlukları "+" yapıyor, posta uygulaması da "+"
      // olarak gösteriyor; elle kodlanır.
      query: [
        'subject=${Uri.encodeComponent('Dishrate Geri Bildirimi')}',
        if (version != null)
          'body=${Uri.encodeComponent('\n\n—\nSürüm: $version')}',
      ].join('&'),
    );
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
    if (opened || !mounted) return;
    await Clipboard.setData(const ClipboardData(text: AppLinks.supportEmail));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('E-posta adresi kopyalandı: ${AppLinks.supportEmail}'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showTerms() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => const _TermsSheet(),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: const Text('Çıkış Yap', style: AppTextStyles.titleSmall),
        content: Text(
          'Çıkış yapmak istediğine emin misin?',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Oturumu kapat → _AuthGate otomatik giriş ekranına yönlendirir
              ref.read(authProvider.notifier).logout();
            },
            style:
                TextButton.styleFrom(foregroundColor: context.errorTextColor),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
  }

  void _openDeleteAccount() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => _DeleteAccountSheet(
        onDeleted: () => ref.read(authProvider.notifier).clearDeletedAccount(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Dışarıdan (puanlama, sekme değişimi) tetiklenen sessiz yenileme.
    ref.listen<int>(userDataRefreshProvider, (_, __) => _load(silent: true));
    // Yemek panelindeki "Tümünü gör": panel ve üstteki sayfalar kapandıktan
    // sonra istek listesi açılsın diye bir sonraki kareye bırakılıyor.
    ref.listen<int>(wishlistOpenRequestProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWishlist(waitForFresh: true);
      });
    });

    return Scaffold(
      backgroundColor: context.bgColor,
      body: _isLoading
          ? const SafeArea(child: _ProfileSkeleton())
          : _failed
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.screen, AppSpace.xxl, AppSpace.screen, 0),
                    child: StateMessage(
                      title: 'Profil yüklenemedi',
                      message: 'Bağlantını kontrol edip tekrar dene.',
                      actionLabel: 'Tekrar dene',
                      onAction: _load,
                    ),
                  ),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── App Bar ────────────────────────────────────────────
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: context.bgColor,
                      title: const Text('Profil',
                          style: AppTextStyles.headlineMedium),
                      actions: [
                        IconButton(
                          icon: Icon(TablerIcons.settings,
                              color: context.textSecondaryColor),
                          onPressed: () => _openSettings(context),
                          tooltip: 'Ayarlar',
                        ),
                        const SizedBox(width: AppSpace.xs),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(0.5),
                        child:
                            Container(height: 0.5, color: context.dividerColor),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Profil başlığı ──────────────────────────────
                          _ProfileHeader(
                            user: _user,
                            ratingCount: _ratings.length,
                            wishlistCount: _wishlist.length,
                            // Sayaçlara dokununca ilgili yere git
                            onRatingsTap: () => ref
                                .read(selectedTabProvider.notifier)
                                .state = 2, // Günlük sekmesi
                            onWishlistTap: _showWishlist,
                            // Avatara dokununca fotoğrafı doğrudan değiştir
                            onPhotoTap:
                                _user == null ? null : () => _editPhoto(_user!),
                            photoBusy: _photoBusy,
                          ),

                          const SizedBox(height: AppSpace.sm),

                          // ── YEMEKLERİN ───────────────────────────────────
                          const _SectionLabel('YEMEKLERİN'),
                          _ProfileItem(
                            icon: TablerIcons.heart,
                            label: 'Favori yemekler',
                            subtitle: _topFavorites.isEmpty
                                ? 'Henüz puan verilmedi'
                                : 'En yüksek puanlı ${_topFavorites.length} yemeğin',
                            onTap: _showFavorites,
                          ),
                          _ProfileItem(
                            icon: TablerIcons.bookmark,
                            label: 'İstek Listesi',
                            subtitle: _wishlist.isEmpty
                                ? 'Boş'
                                : '${_wishlist.length} yemek kaydedildi',
                            onTap: _showWishlist,
                          ),

                          // ── HESAP ───────────────────────────────────────
                          const _SectionLabel('HESAP'),
                          _ProfileItem(
                            icon: TablerIcons.pencil,
                            label: 'Profili düzenle',
                            subtitle: 'Kullanıcı adı ve biyografi',
                            onTap: _showEditProfile,
                          ),
                          // Önceki "Gizlilik ve güvenlik" panelinde kaydedilmeyen
                          // bir "Profili gizle" anahtarı ve bu satır vardı;
                          // "Bildirimler" paneli de hiçbir şey kaydetmiyordu.
                          // İkisi 1.6'da kalktı (bildirimler 6.4 ile döner).
                          _ProfileItem(
                            icon: TablerIcons.key,
                            label: 'Şifre değiştir',
                            subtitle: 'Hesap güvenliğini artır',
                            onTap: _showChangePassword,
                          ),

                          // ── DESTEK ──────────────────────────────────────
                          const _SectionLabel('DESTEK'),
                          _ProfileItem(
                            icon: TablerIcons.message_circle,
                            label: 'Bize ulaş',
                            subtitle: AppLinks.supportEmail,
                            onTap: _contactUs,
                          ),
                          _ProfileItem(
                            icon: TablerIcons.file_text,
                            label: 'Kullanım şartları',
                            onTap: _showTerms,
                          ),

                          const SizedBox(height: AppSpace.xl),

                          // ── Oturum ve hesap ─────────────────────────────
                          // "Tehlikeli bölge" başlığı yerine boşlukla ayrılıyor;
                          // kırmızı yazı zaten uyarıyor.
                          _ProfileItem(
                            icon: TablerIcons.logout,
                            label: 'Çıkış yap',
                            onTap: _confirmSignOut,
                            showChevron: false,
                          ),
                          _ProfileItem(
                            icon: TablerIcons.trash,
                            label: 'Hesabı sil',
                            destructive: true,
                            onTap: _openDeleteAccount,
                            showChevron: false,
                          ),

                          const SizedBox(height: AppSpace.section),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Yükleniyor ────────────────────────────────────────────────────────────────

/// Profil başlığının iskeleti: avatar, ad satırları ve sayaç kutusu.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.xxl + AppSpace.xl, AppSpace.screen, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SkeletonBox(width: 72, height: 72, radius: 36),
                SizedBox(width: AppSpace.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: AppSpace.sm),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            const SkeletonBox(height: 72, radius: AppRadius.md),
            const SizedBox(height: AppSpace.xl),
            for (var i = 0; i < 4; i++) ...[
              const SkeletonBox(width: 200, height: 14),
              const SizedBox(height: AppSpace.xl),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Profil başlığı ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.ratingCount,
    required this.wishlistCount,
    this.onRatingsTap,
    this.onWishlistTap,
    this.onPhotoTap,
    this.photoBusy = false,
  });

  final UserModel? user;
  final int ratingCount;
  final int wishlistCount;
  final VoidCallback? onRatingsTap;
  final VoidCallback? onWishlistTap;

  /// Avatara dokunulduğunda fotoğrafı değiştirme akışını başlatır.
  final VoidCallback? onPhotoTap;
  final bool photoBusy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.screen, AppSpace.screen, AppSpace.lg),
      child: Column(
        children: [
          // Avatar + bilgi
          Row(
            children: [
              // Avatara dokunmak fotoğrafı doğrudan değiştirir —
              // "Profili Düzenle"ye girmeye gerek yok.
              Semantics(
                button: true,
                label: 'Profil fotoğrafını değiştir',
                child: GestureDetector(
                  onTap: user == null ? null : onPhotoTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: context.surfaceElevatedColor,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: context.dividerColor, width: 2),
                        ),
                        child: user?.profilePhotoUrl != null
                            ? ClipOval(
                                child: Image.network(user!.profilePhotoUrl!,
                                    fit: BoxFit.cover),
                              )
                            : Icon(TablerIcons.user,
                                color: context.textTertiaryColor, size: 34),
                      ),
                      // Dokunulabilir olduğunu belli eden küçük rozet
                      if (user != null)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: context.bgColor, width: 2),
                            ),
                            child: photoBusy
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(TablerIcons.camera,
                                    size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '—',
                        style: AppTextStyles.titleMedium),
                    if (user != null) ...[
                      const SizedBox(height: AppSpace.xxs),
                      Text('@${user!.username}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondaryColor,
                          )),
                    ],
                    if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(user!.bio!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: context.textSecondaryColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          // İstatistikler
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                _StatItem(
                  value: '$ratingCount',
                  label: 'Değerlendirme',
                  onTap: onRatingsTap,
                ),
                Container(width: 1, height: 32, color: context.dividerColor),
                _StatItem(
                  value: '$wishlistCount',
                  label: 'İstek Listesi',
                  onTap: onWishlistTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.onTap,
  });
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Column(
            children: [
              Text(value,
                  style: AppTextStyles.ratingLarge
                      .copyWith(fontSize: 22, color: context.textPrimaryColor)),
              const SizedBox(height: AppSpace.xxs),
              Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.textSecondaryColor)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xs),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: context.textTertiaryColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Profil liste öğesi ────────────────────────────────────────────────────────

/// Profil menüsü satırı. Renkli ikon kutuları kalktı: her satır başka renkte
/// olunca ekranda vurgu kalmıyordu. İkon tek renk, yalnızca yıkıcı eylem
/// (Hesabı Sil) kırmızı.
class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        destructive ? context.errorTextColor : context.textSecondaryColor;
    final labelColor =
        destructive ? context.errorTextColor : context.textPrimaryColor;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSize.minTap + 8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.screen, vertical: AppSpace.sm),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: labelColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(subtitle!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: context.textTertiaryColor)),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(TablerIcons.chevron_right,
                  color: context.textTertiaryColor, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Profili düzenle sheet ─────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.user,
    required this.onSave,
  });

  final UserModel user;
  final void Function(UserModel updated) onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;

  /// Hata panelin içinde gösterilir (bkz. [_SheetError]). SnackBar panelin
  /// arkasında kalıyordu; "kullanıcı adı alınmış" uyarısı panel kapanınca
  /// görünüyordu (24 Eylül).
  String? _errorText;

  // Profil fotoğrafı (seçilip yüklenir, Kaydet ile kalıcı olur)
  String? _photoUrl;
  String? _photoOriginalUrl;
  String? _photoCrop;
  bool _uploadingPhoto = false;

  bool get _canChangeName => widget.user.canChangeName;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user.lastName ?? '');
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _photoUrl = widget.user.profilePhotoUrl;
    _photoOriginalUrl = widget.user.profilePhotoOriginalUrl;
    _photoCrop = widget.user.profilePhotoCrop;
    // Kullanıcı hatayı düzeltmeye başlayınca uyarı kalkar.
    for (final c in [_firstNameCtrl, _lastNameCtrl, _usernameCtrl]) {
      c.addListener(_clearError);
    }
  }

  void _clearError() {
    if (_errorText != null) setState(() => _errorText = null);
  }

  Future<void> _pickPhoto() async {
    if (_uploadingPhoto) return;
    setState(() {
      _uploadingPhoto = true;
      _errorText = null;
    });
    final result = await ProfilePhotoEditor.edit(
      context,
      // Panel açıldıktan sonra seçilen fotoğraf da yeniden çerçevelenebilsin
      // diye kullanıcıyı yerel durumla güncel tutuyoruz.
      user: _draftUser,
      onError: _error,
    );
    if (!mounted) return;
    setState(() {
      _uploadingPhoto = false;
      if (result != null) {
        _photoUrl = result.photoUrl;
        _photoOriginalUrl = result.originalUrl;
        _photoCrop = result.crop;
      }
    });
  }

  /// Panel açıkken yapılan fotoğraf değişiklikleri henüz kaydedilmedi;
  /// "Mevcut fotoğrafı düzenle" seçeneğinin doğru çalışması için
  /// kullanıcının taslak hâlini veriyoruz.
  UserModel get _draftUser => UserModel(
        userId: widget.user.userId,
        username: widget.user.username,
        firstName: widget.user.firstName,
        lastName: widget.user.lastName,
        email: widget.user.email,
        profilePhotoUrl: _photoUrl,
        profilePhotoOriginalUrl: _photoOriginalUrl,
        profilePhotoCrop: _photoCrop,
        bio: widget.user.bio,
        role: widget.user.role,
        nameChangeAvailableAt: widget.user.nameChangeAvailableAt,
      );

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  InputDecoration _nameDecoration(
      BuildContext context, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySmall,
      prefixIcon: Icon(icon, size: 18, color: context.textSecondaryColor),
      filled: true,
      fillColor:
          _canChangeName ? context.surfaceElevatedColor : context.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.dividerColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: context.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  void _error(String msg) => setState(() => _errorText = msg);

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    if (username.isEmpty) {
      _error('Kullanıcı adı boş olamaz.');
      return;
    }
    if (_canChangeName && (firstName.isEmpty || lastName.isEmpty)) {
      _error('Ad ve soyad boş olamaz.');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final updated = await UserRepository.instance.updateUser(
        widget.user.userId,
        username: username,
        // İsim alanları yalnızca değiştirilebilir durumdaysa gönderilir.
        firstName: _canChangeName ? firstName : null,
        lastName: _canChangeName ? lastName : null,
        bio: _bioCtrl.text.trim(),
        // Fotoğraf değiştiyse üç alanı birlikte gönder — özgün görsel ve
        // kırpma dikdörtgeni olmadan sonradan yeniden çerçeveleme yapılamaz.
        profilePhotoUrl:
            _photoUrl != widget.user.profilePhotoUrl ? _photoUrl : null,
        profilePhotoOriginalUrl:
            _photoOriginalUrl != widget.user.profilePhotoOriginalUrl
                ? _photoOriginalUrl
                : null,
        profilePhotoCrop:
            _photoCrop != widget.user.profilePhotoCrop ? _photoCrop : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSave(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _error(_parseError(e));
    }
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      // Doğrulama hatasında genel mesaj ("alanları kontrol et") neyin yanlış
      // olduğunu söylemiyor; alana özel olanı ("username: …") gösterilir.
      final details = data is Map ? data['validationErrors'] : null;
      if (details is List && details.isNotEmpty && details.first is String) {
        final first = details.first as String;
        final i = first.indexOf(': ');
        return i == -1 ? first : first.substring(i + 2);
      }
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.response?.statusCode == 409) {
        return 'Bu kullanıcı adı zaten kullanımda.';
      }
    }
    return 'Güncellenemedi, tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          // Avatar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.screen),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.pencil,
                        color: context.textSecondaryColor, size: 20),
                    const SizedBox(width: AppSpace.sm),
                    const Text('Profili Düzenle',
                        style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpace.screen),
                // Profil fotoğrafı — tıkla → galeriden seç → yükle
                Semantics(
                  button: true,
                  label: 'Profil fotoğrafı seç',
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.surfaceElevatedColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: context.dividerColor, width: 2),
                          ),
                          child: _uploadingPhoto
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary),
                                  ),
                                )
                              : _photoUrl != null
                                  ? ClipOval(
                                      child: Image.network(_photoUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover))
                                  : Icon(TablerIcons.user,
                                      color: context.textTertiaryColor,
                                      size: 38),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(TablerIcons.camera,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.screen),
                // İsim + Soyisim (15 günde bir değiştirilebilir)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameCtrl,
                        enabled: _canChangeName,
                        style: AppTextStyles.bodyMedium,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            _nameDecoration(context, 'Ad', TablerIcons.id),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: TextField(
                        controller: _lastNameCtrl,
                        enabled: _canChangeName,
                        style: AppTextStyles.bodyMedium,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            _nameDecoration(context, 'Soyad', TablerIcons.id),
                      ),
                    ),
                  ],
                ),
                if (!_canChangeName) ...[
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Icon(TablerIcons.clock,
                          size: 14, color: context.textSecondaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ad ve soyad 15 günde bir değiştirilebilir. ',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: context.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                // Kullanıcı adı
                TextField(
                  controller: _usernameCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı adı',
                    labelStyle: AppTextStyles.bodySmall,
                    prefixIcon: Icon(TablerIcons.at,
                        size: 18, color: context.textSecondaryColor),
                    filled: true,
                    fillColor: context.surfaceElevatedColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                // Biyografi
                TextField(
                  controller: _bioCtrl,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'Biyografi',
                    labelStyle: AppTextStyles.bodySmall,
                    hintText: 'Kendinden biraz bahset…',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: context.textTertiaryColor),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 44),
                      child: Icon(TablerIcons.align_left,
                          size: 18, color: context.textSecondaryColor),
                    ),
                    filled: true,
                    fillColor: context.surfaceElevatedColor,
                    counterStyle:
                        AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  _SheetError(_errorText!),
                ],
                const SizedBox(height: AppSpace.lg),
                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Kaydet',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
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

// ── Kullanım şartları sheet ───────────────────────────────────────────────────

class _TermsSheet extends StatelessWidget {
  const _TermsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.md),
            child: Row(
              children: [
                Icon(TablerIcons.file_text,
                    color: context.textSecondaryColor, size: 20),
                const SizedBox(width: AppSpace.sm),
                const Text('Kullanım Şartları',
                    style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.lg, AppSpace.screen, 40),
              children: [
                const _TermsSection(
                  title: '1. Kabul',
                  body:
                      'Dishrate\'i kullanarak bu kullanım şartlarını kabul etmiş olursunuz. Şartları kabul etmiyorsanız uygulamayı kullanmayı bırakınız.',
                ),
                const _TermsSection(
                  title: '2. Kullanıcı İçeriği',
                  body:
                      'Paylaştığınız değerlendirmeler ve yorumlar size aittir. Ancak Dishrate, bu içerikleri platform içinde görüntüleme ve analiz etme hakkına sahiptir. Yanıltıcı, hakaret içerikli veya yasadışı içerik paylaşmak yasaktır.',
                ),
                const _TermsSection(
                  title: '3. Gizlilik',
                  body:
                      'Kişisel verileriniz 6698 sayılı KVKK kapsamında korunmaktadır. Verileriniz üçüncü şahıslarla paylaşılmaz. Ayrıntılı bilgi için Gizlilik Politikamızı inceleyiniz.',
                ),
                const _TermsSection(
                  title: '4. Hesap Güvenliği',
                  body:
                      'Hesabınızın güvenliğinden siz sorumlusunuz. Şifrenizi güçlü tutun ve başkalarıyla paylaşmayın. Yetkisiz erişim şüphesinde derhal bizimle iletişime geçin.',
                ),
                const _TermsSection(
                  title: '5. Hizmet Değişiklikleri',
                  body:
                      'Dishrate, herhangi bir bildirim yapmaksızın hizmeti geçici veya kalıcı olarak değiştirme ya da sonlandırma hakkını saklı tutar.',
                ),
                const _TermsSection(
                  title: '6. İletişim',
                  body:
                      'Sorularınız için destek@dishrate.app adresine e-posta gönderebilirsiniz.',
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Son güncelleme: Mayıs 2026',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textTertiaryColor,
                    fontStyle: FontStyle.italic,
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

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.titleSmall
                  .copyWith(color: context.textPrimaryColor)),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ── Wishlist popup ────────────────────────────────────────────────────────────

class _WishlistSheet extends StatefulWidget {
  const _WishlistSheet({
    required this.wishlist,
    required this.onRemove,
    required this.onRate,
    required this.onRemoveFailedAfterClose,
  });
  final List<WishlistModel> wishlist;
  final Future<void> Function(int wishId) onRemove;
  final void Function(WishlistModel) onRate;

  /// Panel kapandıktan sonra çıkarma başarısız olursa: şerit gösterecek panel
  /// kalmadığı için haber profil ekranına verilir.
  final void Function(WishlistModel) onRemoveFailedAfterClose;

  @override
  State<_WishlistSheet> createState() => _WishlistSheetState();
}

class _WishlistSheetState extends State<_WishlistSheet> {
  late List<WishlistModel> _items;

  /// Çıkarılıp "Geri al" süresi dolmamış öğeler, eskiden yeniye. Öğe
  /// `_items`'tan çıkmaz, yalnızca gizlenir; geri alınınca tam eski yerine
  /// döner. Sunucuya istek her birinin kendi süresi dolunca gider.
  final List<_PendingRemoval> _pendingRemovals = [];

  /// Çıkarma başarısız olursa kısa süre görünen, eylemsiz şeritler.
  final List<_SheetNotice> _notices = [];
  int _noticeSeq = 0;

  /// Listeye geri dönen öğeler; satırları bir kez açılarak girer.
  final Set<int> _restoredIds = {};

  static const _undoWindow = Duration(seconds: 5);

  /// Sunucudan çıkarma isteğinin beklendiği süre.
  static const _removeDeadline = Duration(seconds: 4);

  List<WishlistModel> get _visibleItems {
    final hidden = {for (final p in _pendingRemovals) p.item.wishId};
    return _items.where((w) => !hidden.contains(w.wishId)).toList();
  }

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.wishlist);
  }

  @override
  void dispose() {
    // Panel kapanıyorsa bekleyen çıkarmalar artık geri alınamaz; hemen gönderilir.
    // Başarısız olursa şerit gösterecek panel kalmadığı için profil haber verir.
    for (final pending in _pendingRemovals) {
      pending.timer.cancel();
      final item = pending.item;
      widget
          .onRemove(item.wishId)
          .timeout(_removeDeadline)
          .catchError((Object _) => widget.onRemoveFailedAfterClose(item));
    }
    for (final notice in _notices) {
      notice.timer.cancel();
    }
    super.dispose();
  }

  /// "Listeden çıkar" düğmesi ve kaydırma buraya gelir.
  void _remove(WishlistModel item) {
    if (_pendingRemovals.any((p) => p.item.wishId == item.wishId)) return;
    late final _PendingRemoval pending;
    pending =
        _PendingRemoval(item, Timer(_undoWindow, () => _commitRemove(pending)));
    setState(() => _pendingRemovals.add(pending));
  }

  void _undoRemove(_PendingRemoval pending) {
    pending.timer.cancel();
    _markRestored(pending.item.wishId);
    setState(() => _pendingRemovals.remove(pending));
  }

  /// Satır yeniden oluşurken açılma animasyonu oynasın; bir kare sonra iz
  /// silinir ki sonraki yeniden çizimlerde tekrar oynamasın.
  void _markRestored(int wishId) {
    _restoredIds.add(wishId);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _restoredIds.remove(wishId));
  }

  Future<void> _commitRemove(_PendingRemoval pending) async {
    pending.timer.cancel();
    if (!mounted || !_pendingRemovals.contains(pending)) return;
    final item = pending.item;
    final index = _items.indexWhere((w) => w.wishId == item.wishId);
    setState(() {
      _pendingRemovals.remove(pending);
      _items.removeWhere((w) => w.wishId == item.wishId);
    });
    try {
      // Bağlantı zaman aşımı (10 sn) beklenmez; o kadar süre öğe silinmiş
      // görünürdü. Süre dolarsa öğe listeye döner, kayıt sunucuda kalır.
      await widget.onRemove(item.wishId).timeout(_removeDeadline);
    } catch (_) {
      if (!mounted) return;
      _markRestored(item.wishId);
      setState(() => _items.insert(index.clamp(0, _items.length), item));
      _showNotice('Listeden çıkarılamadı, tekrar dene.');
    }
  }

  void _showNotice(String message) {
    late final _SheetNotice notice;
    notice = _SheetNotice(
        _noticeSeq++,
        message,
        Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _notices.remove(notice));
        }));
    setState(() => _notices.add(notice));
  }

  List<Widget> _buildBanners() => [
        for (final pending in _pendingRemovals)
          InfoBanner(
            key: ValueKey('removed_${pending.item.wishId}'),
            icon: TablerIcons.bookmark_off,
            message:
                '${pending.item.menuItemName} listeden çıkarıldı.',
            actionLabel: 'Geri al',
            onAction: () => _undoRemove(pending),
          ),
        for (final notice in _notices)
          InfoBanner(
            key: ValueKey('notice_${notice.id}'),
            icon: TablerIcons.alert_circle,
            message: notice.message,
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final banners = _buildBanners();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.md),
            child: Row(
              children: [
                Icon(TablerIcons.bookmark,
                    color: context.textSecondaryColor, size: 20),
                const SizedBox(width: AppSpace.sm),
                const Text('İstek Listesi', style: AppTextStyles.titleSmall),
                const Spacer(),
                Text('${items.length} yemek', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(
                        AppSpace.screen, AppSpace.xl, AppSpace.screen, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: StateMessage(
                        title: 'İstek Listesi boş',
                        message:
                            'Denemek istediğin yemekleri unutmamak için İstek Listesi’ne ekleyebilirsin.',
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(
                        AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xl),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return SwipeToDelete(
                        key: Key('wish_${item.wishId}'),
                        radius: 12,
                        bottomGap: 8,
                        revealWidth: 72,
                        iconSize: 22,
                        animateIn: _restoredIds.contains(item.wishId),
                        onDelete: () => _remove(item),
                        // "Listeden çıkar" de aynı kayma ve kapanmayı oynatır.
                        builder: (_, swipeAway) => _WishlistItemRow(
                          item: item,
                          onRemove: swipeAway,
                          onRate: () {
                            Navigator.pop(context);
                            widget.onRate(item);
                          },
                        ),
                      );
                    },
                  ),
          ),
          // Çıkarma şeritleri — panelin altında, en yenisi en altta.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: InfoBannerStack(
              banners: banners,
              trailingGap: 12 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

/// Geri alma süresindeki çıkarma ve süresi dolunca onu gönderecek zamanlayıcı.
class _PendingRemoval {
  _PendingRemoval(this.item, this.timer);
  final WishlistModel item;
  final Timer timer;
}

/// Kısa süre görünen eylemsiz şerit mesajı.
class _SheetNotice {
  _SheetNotice(this.id, this.message, this.timer);
  final int id;
  final String message;
  final Timer timer;
}

class _WishlistItemRow extends StatelessWidget {
  const _WishlistItemRow({
    required this.item,
    required this.onRate,
    required this.onRemove,
  });
  final WishlistModel item;
  final VoidCallback onRate;

  /// Sağ üstteki "Listeden çıkar". Kaydırarak çıkarma ilk kullanımda
  /// keşfedilmiyordu; görünür bir yol da var.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.fromLTRB(14, AppSpace.md, 14, 10),
      // Günlük kartıyla aynı: zemin yüzey rengi, ayrım kenarlıkla.
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Yemek bilgisi ─────────────────────────────────────────────
          Row(
            children: [
              DishPhoto(
                url: item.photoUrl,
                width: 40,
                height: 40,
                radius: 10,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.menuItemName, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpace.xxs),
                    Text(item.restaurantName, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondaryColor,
                  textStyle: AppTextStyles.label,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  minimumSize: const Size(44, 36),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: const Text('Listeden çıkar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── "Sonunda denedim!" butonu ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side:
                    BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
                // Düğme stili temadan birleşmiyor, yerine geçiyor: font ailesi
                // verilmezse yazı sistem fontuna düşüyordu.
                textStyle: AppTextStyles.label,
              ),
              icon: const Icon(TablerIcons.star, size: 16),
              label: const Text('Sonunda denedim!'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Favori yemekler popup ─────────────────────────────────────────────────────

class _FavoritesSheet extends StatelessWidget {
  const _FavoritesSheet({required this.favorites});
  final List<RatingModel> favorites;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      builder: (_, controller) => Column(
        children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.md),
            child: Row(
              children: [
                Icon(TablerIcons.heart,
                    color: context.textSecondaryColor, size: 20),
                const SizedBox(width: AppSpace.sm),
                const Text('Favori Yemekler', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xl),
              itemCount: favorites.length,
              itemBuilder: (_, i) =>
                  _FavoriteItemRow(rank: i + 1, rating: favorites[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteItemRow extends StatelessWidget {
  const _FavoriteItemRow({required this.rank, required this.rating});
  final int rank;
  final RatingModel rating;

  /// İlk üç sıra dolgulu rozet. Soluk tonlar açık zeminde seçilmiyordu;
  /// gümüş de 4-5'in nötr grisiyle karışıyordu, mavimsi tona çekildi.
  static const _podiumColors = [
    Color(0xFFE0A100), // 1 — altın
    Color(0xFF8E9AAB), // 2 — gümüş
    Color(0xFFB8662E), // 3 — bronz
  ];

  @override
  Widget build(BuildContext context) {
    final podium = rank <= _podiumColors.length;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.md),
      // İstek listesi ve günlük kartlarıyla aynı yüzey.
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: podium ? _podiumColors[rank - 1] : context.fillColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTextStyles.label.copyWith(
                  color: podium ? Colors.white : context.textSecondaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          _RatingThumb(photoUrl: rating.photoUrl, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rating.menuItemName, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpace.xxs),
                Text(rating.restaurantName, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRow(rating: rating.score, size: 13),
              const SizedBox(width: AppSpace.xs),
              Text(
                rating.score.toStringAsFixed(1),
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Şifre kuralları göstergesi ────────────────────────────────────────────────

/// Şifre yazılırken hangi kuralların sağlandığını canlı gösterir.
class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: PasswordValidator.rules.map((rule) {
        final ok = rule.test(value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? TablerIcons.circle_check : TablerIcons.circle,
              size: 14,
              color: ok ? AppColors.success : context.textSecondaryColor,
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              rule.label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: ok ? AppColors.success : context.textSecondaryColor,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Şifre değiştir sheet ──────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  /// Hata mesajı sheet'İN İÇİNDE gösterilir. SnackBar kullanılamaz:
  /// ScaffoldMessenger sheet'in ALTINDAKİ Scaffold'a bağlı olduğu için
  /// mesaj bu panelin arkasında kalıp görünmez oluyordu.
  String? _error;

  @override
  void initState() {
    super.initState();
    // Kural listesi yazdıkça güncellensin
    _newCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || next.isEmpty) {
      setState(() => _error = 'Tüm alanları doldur.');
      return;
    }
    final ruleError = PasswordValidator.validate(next);
    if (ruleError != null) {
      setState(() => _error = 'Yeni şifre: ${ruleError.toLowerCase()}');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'Yeni şifreler eşleşmiyor.');
      return;
    }
    if (next == current) {
      setState(() => _error = 'Yeni şifre eskisiyle aynı olamaz.');
      return;
    }

    final userId = await TokenStorage.instance.getUserId();
    if (userId == null) {
      setState(() => _error = 'Oturum bulunamadı.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await UserRepository.instance.changePassword(
        userId,
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;
      Navigator.pop(context);
      // Sheet kapandıktan sonra başarı mesajı artık görünür
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Şifren güncellendi.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _parseError(e);
      });
    }
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Şifre değiştirilemedi, tekrar dene.';
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        prefixIcon:
            Icon(TablerIcons.lock, size: 18, color: context.textSecondaryColor),
        filled: true,
        fillColor: context.surfaceElevatedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: context.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(TablerIcons.key,
                        color: context.textSecondaryColor, size: 20),
                    const SizedBox(width: AppSpace.sm),
                    const Text('Şifre Değiştir',
                        style: AppTextStyles.titleSmall),
                    const Spacer(),
                    IconButton(
                      tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                      icon: Icon(
                        _obscure ? TablerIcons.eye_off : TablerIcons.eye,
                        size: 20,
                        color: context.textSecondaryColor,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: _currentCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.bodyMedium,
                  decoration: _dec('Mevcut şifre'),
                ),
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: _newCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.bodyMedium,
                  decoration: _dec('Yeni şifre'),
                ),
                // Kurallar — yazdıkça yeşile döner
                if (_newCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _PasswordRules(value: _newCtrl.text),
                ],
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.bodyMedium,
                  decoration: _dec('Yeni şifre (tekrar)'),
                ),

                // Hata — sheet'in İÇİNDE, arkada kalmıyor
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _SheetError(_error!),
                ],

                const SizedBox(height: AppSpace.screen),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Güncelle',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white)),
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

// ── Hesabı sil sheet ──────────────────────────────────────────────────────────

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.onDeleted});

  /// Sunucuda silme başarılı olunca çağrılır (cihazdaki oturumu temizler).
  final VoidCallback onDeleted;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Şifreni gir.');
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await UserRepository.instance.deleteAccount(password: password);
      if (!mounted) return;
      // Mesaj uygulamanın kök ScaffoldMessenger'ına gidiyor; profil ekranı
      // kapanıp giriş ekranı açıldığında da görünür kalır.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      widget.onDeleted();
      messenger.showSnackBar(const SnackBar(
        content: Text('Hesabın ve bütün verilerin silindi.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = _parseError(e);
      });
    }
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Hesap silinemedi, tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(TablerIcons.trash, color: AppColors.error, size: 20),
                    SizedBox(width: AppSpace.sm),
                    Text('Hesabı Sil', style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                const Text(
                  'Hesabın kalıcı olarak silinecek. Bu işlem geri alınamaz.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 10),
                for (final bullet in const [
                  'Bütün puanların, yorumların ve yorum fotoğrafların',
                  'İstek listen',
                  'Profil bilgilerin ve profil fotoğrafın',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.xxs),
                          child: Icon(TablerIcons.circle_minus,
                              size: 16, color: context.textSecondaryColor),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(bullet, style: AppTextStyles.bodySmall),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  enabled: !_deleting,
                  autofillHints: const [AutofillHints.password],
                  style: AppTextStyles.bodyMedium,
                  onSubmitted: (_) => _delete(),
                  decoration: InputDecoration(
                    labelText: 'Onaylamak için şifren',
                    labelStyle: AppTextStyles.bodySmall,
                    prefixIcon: Icon(TablerIcons.lock,
                        size: 18, color: context.textSecondaryColor),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Şifreyi göster' : 'Şifreyi gizle',
                      icon: Icon(
                        _obscure ? TablerIcons.eye_off : TablerIcons.eye,
                        size: 20,
                        color: context.textSecondaryColor,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: context.surfaceElevatedColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _SheetError(_error!),
                ],
                const SizedBox(height: AppSpace.screen),
                FilledButton(
                  onPressed:
                      _deleting || _passwordCtrl.text.isEmpty ? null : _delete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor:
                        AppColors.error.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Hesabımı kalıcı olarak sil',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white)),
                ),
                const SizedBox(height: AppSpace.xs),
                TextButton(
                  onPressed: _deleting ? null : () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ortak yardımcı widget'lar ─────────────────────────────────────────────────

/// Değerlendirme/yemek fotoğrafı küçük resmi — yoksa ikon gösterir.
///
/// Önbellekli [DishPhoto] kullanıyor: `Image.network` her açılışta yeniden
/// indiriyor, yavaş bağlantıda bazı küçük resimler hiç gelmiyordu.
class _RatingThumb extends StatelessWidget {
  const _RatingThumb({required this.photoUrl, this.size = 44});
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DishPhoto(
      url: photoUrl,
      width: size,
      height: size,
      radius: 10,
      iconSize: 20,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.dividerColor,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}

// ── Değerlendirme modal wrapper (profil akışı) ────────────────────────────────

class _ProfileRatingSheet extends StatelessWidget {
  const _ProfileRatingSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: 40,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRadius.xs)),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.screen),
          const Expanded(child: AddRatingScreen()),
        ],
      ),
    );
  }
}

/// Panelin içindeki hata kutusu. Panellerde SnackBar kullanılmaz:
/// ScaffoldMessenger panelin altındaki Scaffold'a bağlı, mesaj panelin
/// arkasında kalıyor.
class _SheetError extends StatelessWidget {
  const _SheetError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(TablerIcons.alert_circle,
                color: AppColors.error, size: 18),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

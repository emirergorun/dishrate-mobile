import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/network/user_repository.dart';
import '../../../core/network/wishlist_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/rating_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/wishlist_model.dart';
import '../../../shared/providers/data_refresh.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/info_banner.dart';
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
    if (!silent) setState(() => _isLoading = true);
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
        });
      }
    } catch (_) {
      // Sessizce devam et
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Sheet açıcılar ──────────────────────────────────────────────────────────

  Future<void> _showWishlist() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    // Profil tab'ına döndükten sonra güncel veriyi çek
    final fresh = await WishlistRepository.instance.getWishlist(userId);
    if (mounted) setState(() => _wishlist = fresh);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _WishlistSheet(
        wishlist: _wishlist,
        onRemove: (wishId) async {
          await WishlistRepository.instance.removeFromWishlist(wishId);
          if (mounted) {
            setState(() => _wishlist.removeWhere((w) => w.wishId == wishId));
          }
        },
        onRate: _openRatingForWishlistItem,
      ),
    );
  }

  /// İstek listesindeki bir ürünü doğrudan puanlama ekranına gönderir.
  void _openRatingForWishlistItem(WishlistModel wish) {
    final menuItem = MenuItemModel(
      menuItemId: wish.menuItemId,
      name: wish.menuItemName,
      price: wish.price,
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditProfileSheet(
        user: _user!,
        onSave: (updated) {
          setState(() => _user = updated);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Profil güncellendi.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
      ),
    );
  }

  void _showPrivacy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _PrivacySheet(),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _showContactUs() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ContactSheet(),
    );
  }

  void _showTerms() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _TermsSheet(),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: const Text('Oturumu Kapat', style: AppTextStyles.titleSmall),
        content: Text(
          'Oturumunu kapatmak istediğine emin misin?',
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
            child: const Text('Çıkış Yap',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String title, String subtitle, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: Text(title, style: AppTextStyles.titleSmall),
        content: Text(subtitle, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(title, style: const TextStyle(color: AppColors.error)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
        if (mounted) _showWishlist();
      });
    });

    return Scaffold(
      backgroundColor: context.bgColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: context.bgColor,
                  title:
                      const Text('Profil', style: AppTextStyles.headlineMedium),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.settings_outlined,
                          color: context.textSecondaryColor),
                      onPressed: () => _openSettings(context),
                      tooltip: 'Ayarlar',
                    ),
                    const SizedBox(width: 4),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(0.5),
                    child: Container(height: 0.5, color: context.dividerColor),
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

                      const SizedBox(height: 8),

                      // ── KEŞFEDİN ───────────────────────────────────
                      const _SectionLabel('KEŞFEDİN'),
                      _ProfileItem(
                        icon: Icons.favorite_rounded,
                        iconColor: const Color(0xFFE57373),
                        label: 'Favori Yemekler',
                        subtitle: _topFavorites.isEmpty
                            ? 'Henüz puan verilmedi'
                            : 'En yüksek puanlı ${_topFavorites.length} yemeğin',
                        onTap: _showFavorites,
                      ),
                      _ProfileItem(
                        icon: Icons.bookmark_rounded,
                        iconColor: const Color(0xFF81C784),
                        label: 'İstek Listesi',
                        subtitle: _wishlist.isEmpty
                            ? 'Boş'
                            : '${_wishlist.length} ürün kaydedildi',
                        onTap: _showWishlist,
                      ),

                      const SizedBox(height: 8),

                      // ── HESAP ───────────────────────────────────────
                      const _SectionLabel('HESAP'),
                      _ProfileItem(
                        icon: Icons.edit_rounded,
                        label: 'Profili Düzenle',
                        subtitle: 'Kullanıcı adı ve biyografi',
                        onTap: _showEditProfile,
                      ),
                      _ProfileItem(
                        icon: Icons.lock_rounded,
                        label: 'Gizlilik ve Güvenlik',
                        subtitle: 'Şifre, hesap gizliliği',
                        onTap: _showPrivacy,
                      ),
                      _ProfileItem(
                        icon: Icons.notifications_rounded,
                        label: 'Bildirimler',
                        subtitle: 'Bildirim tercihlerini yönet',
                        onTap: _showNotifications,
                      ),

                      const SizedBox(height: 8),

                      // ── DESTEK ──────────────────────────────────────
                      const _SectionLabel('DESTEK'),
                      _ProfileItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Bize Ulaş',
                        subtitle: 'Öneri ve şikayetlerin için',
                        onTap: _showContactUs,
                      ),
                      _ProfileItem(
                        icon: Icons.description_rounded,
                        label: 'Kullanım Şartları',
                        onTap: _showTerms,
                      ),
                      _ProfileItem(
                        icon: Icons.info_rounded,
                        label: 'Uygulama Hakkında',
                        subtitle: 'v1.0.0',
                        onTap: () {},
                        showChevron: false,
                      ),

                      const SizedBox(height: 8),

                      // ── Oturumu kapat ───────────────────────────────
                      _ProfileItem(
                        icon: Icons.logout_rounded,
                        iconColor: context.textSecondaryColor,
                        label: 'Oturumu Kapat',
                        labelColor: context.textSecondaryColor,
                        onTap: _confirmSignOut,
                        showChevron: false,
                      ),

                      const SizedBox(height: 8),

                      // ── TEHLİKELİ BÖLGE ─────────────────────────────
                      const _SectionLabel('TEHLİKELİ BÖLGE',
                          color: AppColors.error),
                      _ProfileItem(
                        icon: Icons.ac_unit_rounded,
                        iconColor: AppColors.error,
                        label: 'Hesabı Dondur',
                        labelColor: AppColors.error,
                        onTap: () => _confirmDelete(
                          'Hesabı Dondur',
                          'Hesabın dondurulacak ve giriş yapılamayacak. Devam etmek istiyor musun?',
                          () {},
                        ),
                      ),
                      _ProfileItem(
                        icon: Icons.delete_forever_rounded,
                        iconColor: AppColors.error,
                        label: 'Hesabı Sil',
                        labelColor: AppColors.error,
                        onTap: _openDeleteAccount,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          // Avatar + bilgi
          Row(
            children: [
              // Avatara dokunmak fotoğrafı doğrudan değiştirir —
              // "Profili Düzenle"ye girmeye gerek yok.
              GestureDetector(
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
                          : const Icon(Icons.person_rounded,
                              color: AppColors.textDisabled, size: 36),
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
                              : const Icon(Icons.camera_alt_rounded,
                                  size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? '—',
                        style: AppTextStyles.titleMedium),
                    if (user != null) ...[
                      const SizedBox(height: 2),
                      Text('@${user!.username}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.textSecondaryColor,
                          )),
                    ],
                    if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(user!.bio!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // İstatistikler
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(value,
                  style: AppTextStyles.ratingLarge
                      .copyWith(fontSize: 22, color: context.textPrimaryColor)),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color ?? AppColors.textDisabled,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Profil liste öğesi ────────────────────────────────────────────────────────

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.labelColor,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: labelColor ?? context.textPrimaryColor,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textDisabled)),
                  ],
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right_rounded,
                    color: onTap != null
                        ? AppColors.textDisabled
                        : AppColors.textDisabled.withValues(alpha: 0.4),
                    size: 20),
            ],
          ),
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
  }

  Future<void> _pickPhoto() async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);
    final result = await ProfilePhotoEditor.edit(
      context,
      // Panel açıldıktan sonra seçilen fotoğraf da yeniden çerçevelenebilsin
      // diye kullanıcıyı yerel durumla güncel tutuyoruz.
      user: _draftUser,
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.dividerColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();

    if (username.isEmpty) {
      _error('Kullanıcı adı boş olamaz.');
      return;
    }
    if (_canChangeName && (firstName.isEmpty || lastName.isEmpty)) {
      _error('İsim ve soyisim boş olamaz.');
      return;
    }

    setState(() => _saving = true);
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Profili Düzenle', style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: 20),
                // Profil fotoğrafı — tıkla → galeriden seç → yükle
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.surfaceElevatedColor,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: context.dividerColor, width: 2),
                        ),
                        child: _uploadingPhoto
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            : _photoUrl != null
                                ? ClipOval(
                                    child: Image.network(_photoUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover))
                                : const Icon(Icons.person_rounded,
                                    color: AppColors.textDisabled, size: 38),
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
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                        decoration: _nameDecoration(
                            context, 'İsim', Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastNameCtrl,
                        enabled: _canChangeName,
                        style: AppTextStyles.bodyMedium,
                        textCapitalization: TextCapitalization.words,
                        decoration: _nameDecoration(
                            context, 'Soyisim', Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
                if (!_canChangeName) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.lock_clock_rounded,
                          size: 14, color: context.textSecondaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'İsim ve soyisim 15 günde bir değiştirilebilir. ',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: context.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Kullanıcı adı
                TextField(
                  controller: _usernameCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı adı',
                    labelStyle: AppTextStyles.bodySmall,
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                        size: 18, color: context.textSecondaryColor),
                    filled: true,
                    fillColor: context.surfaceElevatedColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Biyografi
                TextField(
                  controller: _bioCtrl,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'Biyografi',
                    labelStyle: AppTextStyles.bodySmall,
                    hintText: 'Kendinizi tanıtın...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textDisabled),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.short_text_rounded,
                          size: 18, color: context.textSecondaryColor),
                    ),
                    filled: true,
                    fillColor: context.surfaceElevatedColor,
                    counterStyle:
                        AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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

// ── Gizlilik ve güvenlik sheet ────────────────────────────────────────────────

class _PrivacySheet extends StatefulWidget {
  const _PrivacySheet();

  @override
  State<_PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<_PrivacySheet> {
  bool _privateProfile = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.75,
      builder: (_, __) => Column(
        children: [
          _SheetHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Gizlilik ve Güvenlik', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          // Şifre değiştir
          _SheetItem(
            icon: Icons.key_rounded,
            label: 'Şifre Değiştir',
            subtitle: 'Hesap güvenliğini artır',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: context.surfaceColor,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => const _ChangePasswordSheet(),
              );
            },
          ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 0.5,
              color: context.dividerColor),
          // Profil gizliliği toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.visibility_off_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profili Gizle',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: context.textPrimaryColor)),
                      Text('Değerlendirmelerin sadece sana görünür',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textDisabled)),
                    ],
                  ),
                ),
                Switch(
                  value: _privateProfile,
                  onChanged: (v) => setState(() => _privateProfile = v),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bildirimler sheet ─────────────────────────────────────────────────────────

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _newFeatures = true;
  bool _recommendations = false;
  bool _comments = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.7,
      builder: (_, __) => Column(
        children: [
          _SheetHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Icon(Icons.notifications_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Bildirimler', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          _NotifToggle(
            icon: Icons.new_releases_rounded,
            label: 'Yeni Özellikler',
            subtitle: 'Güncellemeler ve yenilikler hakkında bilgi al',
            value: _newFeatures,
            onChanged: (v) => setState(() => _newFeatures = v),
          ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 0.5,
              color: context.dividerColor),
          _NotifToggle(
            icon: Icons.restaurant_menu_rounded,
            label: 'Dishrate Önerileri',
            subtitle: 'Konumuna yakın lezzetleri keşfet',
            value: _recommendations,
            onChanged: (v) => setState(() => _recommendations = v),
          ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 0.5,
              color: context.dividerColor),
          _NotifToggle(
            icon: Icons.comment_rounded,
            label: 'Yorum Bildirimleri',
            subtitle: 'Yakında geliyor',
            value: _comments,
            onChanged: (v) => setState(() => _comments = v),
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.textPrimaryColor)),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textDisabled)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bize ulaş sheet ───────────────────────────────────────────────────────────

class _ContactSheet extends StatelessWidget {
  const _ContactSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.65,
      builder: (_, __) => Column(
        children: [
          _SheetHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Bize Ulaş', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          const SizedBox(height: 8),
          _SheetItem(
            icon: Icons.email_rounded,
            label: 'E-posta',
            subtitle: 'destek@dishrate.app',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('destek@dishrate.app'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 0.5,
              color: context.dividerColor),
          _SheetItem(
            icon: Icons.camera_alt_rounded,
            label: 'Instagram',
            subtitle: '@dishrate_app',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('@dishrate_app'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 0.5,
              color: context.dividerColor),
          _SheetItem(
            icon: Icons.forum_rounded,
            label: 'Geri Bildirim Gönder',
            subtitle: 'Öneri ve şikayetlerin için',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Geri bildirim formu yakında geliyor.'),
                behavior: SnackBarBehavior.floating,
              ));
            },
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Icon(Icons.description_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Kullanım Şartları', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
                const SizedBox(height: 8),
                Text(
                  'Son güncelleme: Mayıs 2026',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textDisabled,
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
      padding: const EdgeInsets.only(bottom: 20),
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
  });
  final List<WishlistModel> wishlist;
  final Future<void> Function(int wishId) onRemove;
  final void Function(WishlistModel) onRate;

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
    for (final pending in _pendingRemovals) {
      pending.timer.cancel();
      widget.onRemove(pending.item.wishId).ignore();
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
    pending = _PendingRemoval(
        item, Timer(_undoWindow, () => _commitRemove(pending)));
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
      await widget.onRemove(item.wishId);
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
            icon: Icons.bookmark_remove_outlined,
            message:
                '${pending.item.restaurantName} - ${pending.item.menuItemName} listeden çıkarıldı.',
            actionLabel: 'Geri al',
            onAction: () => _undoRemove(pending),
          ),
        for (final notice in _notices)
          InfoBanner(
            key: ValueKey('notice_${notice.id}'),
            icon: Icons.error_outline_rounded,
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.bookmark_rounded,
                    color: Color(0xFF81C784), size: 20),
                const SizedBox(width: 8),
                const Text('İstek Listesi', style: AppTextStyles.titleSmall),
                const Spacer(),
                Text('${items.length} ürün', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('İstek listesi boş',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: context.textSecondaryColor)),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      // Günlük kartıyla aynı: zemin yüzey rengi, ayrım kenarlıkla.
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.menuItemName, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 2),
                    Text(item.restaurantName, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  foregroundColor: context.textSecondaryColor,
                  textStyle: AppTextStyles.label,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                // Düğme stili temadan birleşmiyor, yerine geçiyor: font ailesi
                // verilmezse yazı sistem fontuna düşüyordu.
                textStyle: AppTextStyles.label,
              ),
              icon: const Icon(Icons.star_rounded, size: 16),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded,
                    color: Color(0xFFE57373), size: 20),
                SizedBox(width: 8),
                Text('Favori Yemekler', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      // İstek listesi ve günlük kartlarıyla aynı yüzey.
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 12),
          _RatingThumb(photoUrl: rating.photoUrl, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rating.menuItemName, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(rating.restaurantName, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBarIndicator(
                rating: rating.score,
                itemSize: 13,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star_rounded, color: AppColors.star),
              ),
              const SizedBox(width: 4),
              Text(
                rating.score.toStringAsFixed(1),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.star,
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
              ok ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: ok ? AppColors.success : context.textSecondaryColor,
            ),
            const SizedBox(width: 4),
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
        prefixIcon: Icon(Icons.lock_outline_rounded,
            size: 18, color: context.textSecondaryColor),
        filled: true,
        fillColor: context.surfaceElevatedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Şifre Değiştir',
                        style: AppTextStyles.titleSmall),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: context.textSecondaryColor,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _currentCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.bodyMedium,
                  decoration: _dec('Mevcut şifre'),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  style: AppTextStyles.bodyMedium,
                  decoration: _dec('Yeni şifre (tekrar)'),
                ),

                // Hata — sheet'in İÇİNDE, arkada kalmıyor
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Hesabı Sil', style: AppTextStyles.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
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
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(Icons.remove_circle_outline_rounded,
                              size: 16, color: context.textSecondaryColor),
                        ),
                        const SizedBox(width: 8),
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
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        size: 18, color: context.textSecondaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: context.textSecondaryColor,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: context.surfaceElevatedColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed:
                      _deleting || _passwordCtrl.text.isEmpty ? null : _delete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor:
                        AppColors.error.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                const SizedBox(height: 4),
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
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// Sheet içi tek satır öğe
class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: context.textPrimaryColor)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textDisabled)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDisabled, size: 20),
            ],
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: 40,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(child: AddRatingScreen()),
        ],
      ),
    );
  }
}


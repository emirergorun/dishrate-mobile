import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/mock/mock_data.dart';
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
import '../../../shared/widgets/image_crop_dialog.dart';
import '../../../shared/widgets/main_scaffold.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/file_repository.dart';
import '../../../core/utils/password_validator.dart';
import '../../admin/screens/admin_panel_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../owner/screens/application_status_screen.dart';
import '../../owner/screens/owner_dashboard_screen.dart';
import '../../rating/providers/rating_flow_provider.dart';
import '../../rating/screens/add_rating_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Değeri her arttığında profil verisi sessizce yeniden yüklenir.
/// (Puan verince / profil sekmesine geçince MainScaffold tetikler.)
final profileRefreshProvider = StateProvider<int>((ref) => 0);

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
          setState(() => _wishlist.removeWhere((w) => w.wishId == wishId));
        },
        onRate: _openRatingForWishlistItem,
      ),
    );
  }

  /// İstek listesindeki bir ürünü doğrudan puanlama ekranına gönderir.
  void _openRatingForWishlistItem(WishlistModel wish) {
    // MockData'dan tam ürün bilgisini çekmeye çalış (foto, kategori, konum)
    final fullItem = MockData.getMenuItemById(wish.menuItemId);

    final menuItem = fullItem ??
        MenuItemModel(
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
      city: fullItem?.city ?? 'İstanbul',
      district: fullItem?.district,
      fullAddress: fullItem?.district != null
          ? '${wish.restaurantName}, ${fullItem!.district}'
          : wish.restaurantName,
      latitude: fullItem?.restaurantLatitude,
      longitude: fullItem?.restaurantLongitude,
      categoryName: fullItem?.categoryName,
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
        title: Text('Oturumu Kapat', style: AppTextStyles.titleSmall),
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
    ref.listen<int>(profileRefreshProvider, (_, __) => _load(silent: true));

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
                  title: Text('Profil', style: AppTextStyles.headlineMedium),
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
                      ),

                      const SizedBox(height: 8),

                      // ── YÖNETİM (admin) ────────────────────────────
                      if (_user != null && _user!.isAdmin) ...[
                        _SectionLabel('YÖNETİM'),
                        _ProfileItem(
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: AppColors.error,
                          label: 'Admin Paneli',
                          subtitle: 'Başvurular ve kullanıcı yönetimi',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminPanelScreen()),
                          ),
                        ),
                      ],

                      // ── RESTORAN (rol bazlı) ───────────────────────
                      if (_user != null &&
                          (_user!.isRestaurantOwner || _user!.isUser)) ...[
                        _SectionLabel('RESTORAN'),
                        if (_user!.isRestaurantOwner) ...[
                          _ProfileItem(
                            icon: Icons.storefront_rounded,
                            iconColor: AppColors.primary,
                            label: 'Restoranım',
                            subtitle: 'Menünü ve bilgilerini yönet',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OwnerDashboardScreen()),
                            ),
                          ),
                          _ProfileItem(
                            icon: Icons.notifications_rounded,
                            iconColor: AppColors.star,
                            label: 'Bildirimler',
                            subtitle: 'Ürünlerine gelen değerlendirmeler',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationsScreen()),
                            ),
                          ),
                        ] else
                          _ProfileItem(
                            icon: Icons.assignment_rounded,
                            iconColor: AppColors.primary,
                            label: 'Başvuru Durumum',
                            subtitle: 'Restoran sahibi başvurunu takip et',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ApplicationStatusScreen()),
                            ),
                          ),
                      ],

                      // ── KEŞFEDİN ───────────────────────────────────
                      _SectionLabel('KEŞFEDİN'),
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
                      _SectionLabel('HESAP'),
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
                      _SectionLabel('DESTEK'),
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
                        iconColor: AppColors.textSecondary,
                        label: 'Oturumu Kapat',
                        labelColor: AppColors.textSecondary,
                        onTap: _confirmSignOut,
                        showChevron: false,
                      ),

                      const SizedBox(height: 8),

                      // ── TEHLİKELİ BÖLGE ─────────────────────────────
                      _SectionLabel('TEHLİKELİ BÖLGE', color: AppColors.error),
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
                        onTap: () => _confirmDelete(
                          'Hesabı Sil',
                          'Tüm verilerin kalıcı olarak silinecek. Bu işlem geri alınamaz.',
                          () {},
                        ),
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
  });

  final UserModel? user;
  final int ratingCount;
  final int wishlistCount;
  final VoidCallback? onRatingsTap;
  final VoidCallback? onWishlistTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          // Avatar + bilgi
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.surfaceElevatedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.dividerColor, width: 2),
                ),
                child: user?.profilePhotoUrl != null
                    ? ClipOval(
                        child: Image.network(user!.profilePhotoUrl!,
                            fit: BoxFit.cover),
                      )
                    : const Icon(Icons.person_rounded,
                        color: AppColors.textDisabled, size: 36),
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

  // Profil fotoğrafı (galeriden seçilip yüklenir, Kaydet ile kalıcı olur)
  String? _photoUrl;
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
  }

  Future<void> _pickPhoto() async {
    if (_uploadingPhoto) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    // Yüklemeden önce kırpma/konumlandırma
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final cropped = await ImageCropDialog.show(
      context,
      imageBytes: bytes,
      circular: true,
      title: 'Profil Fotoğrafı',
    );
    if (cropped == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await FileRepository.instance.uploadBytes(
        cropped,
        filename: 'avatar.png',
      );
      if (mounted) {
        setState(() {
          _photoUrl = url;
          _uploadingPhoto = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _error(_parseError(e));
    }
  }

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
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
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
        // Yeni foto seçildiyse gönder
        profilePhotoUrl:
            _photoUrl != widget.user.profilePhotoUrl ? _photoUrl : null,
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
                Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
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
                      const Icon(Icons.lock_clock_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'İsim ve soyisim 15 günde bir değiştirilebilir. ',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
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
                    prefixIcon: const Icon(Icons.alternate_email_rounded,
                        size: 18, color: AppColors.textSecondary),
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
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.short_text_rounded,
                          size: 18, color: AppColors.textSecondary),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.description_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
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
                _TermsSection(
                  title: '1. Kabul',
                  body:
                      'Dishrate\'i kullanarak bu kullanım şartlarını kabul etmiş olursunuz. Şartları kabul etmiyorsanız uygulamayı kullanmayı bırakınız.',
                ),
                _TermsSection(
                  title: '2. Kullanıcı İçeriği',
                  body:
                      'Paylaştığınız değerlendirmeler ve yorumlar size aittir. Ancak Dishrate, bu içerikleri platform içinde görüntüleme ve analiz etme hakkına sahiptir. Yanıltıcı, hakaret içerikli veya yasadışı içerik paylaşmak yasaktır.',
                ),
                _TermsSection(
                  title: '3. Gizlilik',
                  body:
                      'Kişisel verileriniz 6698 sayılı KVKK kapsamında korunmaktadır. Verileriniz üçüncü şahıslarla paylaşılmaz. Ayrıntılı bilgi için Gizlilik Politikamızı inceleyiniz.',
                ),
                _TermsSection(
                  title: '4. Hesap Güvenliği',
                  body:
                      'Hesabınızın güvenliğinden siz sorumlusunuz. Şifrenizi güçlü tutun ve başkalarıyla paylaşmayın. Yetkisiz erişim şüphesinde derhal bizimle iletişime geçin.',
                ),
                _TermsSection(
                  title: '5. Hizmet Değişiklikleri',
                  body:
                      'Dishrate, herhangi bir bildirim yapmaksızın hizmeti geçici veya kalıcı olarak değiştirme ya da sonlandırma hakkını saklı tutar.',
                ),
                _TermsSection(
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

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.wishlist);
  }

  @override
  Widget build(BuildContext context) {
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
                Text('İstek Listesi', style: AppTextStyles.titleSmall),
                const Spacer(),
                Text('${_items.length} ürün', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text('İstek listesi boş',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return _WishlistSwipeItem(
                        key: Key('wish_${item.wishId}'),
                        onDelete: () async {
                          await widget.onRemove(item.wishId);
                          if (mounted) setState(() => _items.removeAt(i));
                        },
                        child: _WishlistItemRow(
                          item: item,
                          onRate: () {
                            Navigator.pop(context);
                            widget.onRate(item);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WishlistItemRow extends StatelessWidget {
  const _WishlistItemRow({required this.item, required this.onRate});
  final WishlistModel item;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Yemek bilgisi ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: AppColors.textDisabled, size: 18),
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
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE57373), size: 20),
                const SizedBox(width: 8),
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

  static const _rankColors = [
    Color(0xFFFFD700), // 1 — altın
    Color(0xFFC0C0C0), // 2 — gümüş
    Color(0xFFCD7F32), // 3 — bronz
    Color(0xFF9E9E9E), // 4
    Color(0xFF9E9E9E), // 5
  ];

  Color get _rankColor =>
      _rankColors[(rank - 1).clamp(0, _rankColors.length - 1)];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: _rankColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Şifren güncellendi.'),
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
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 18, color: AppColors.textSecondary),
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
                    Text('Şifre Değiştir', style: AppTextStyles.titleSmall),
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

// ── Ortak yardımcı widget'lar ─────────────────────────────────────────────────

/// Değerlendirme/yemek fotoğrafı küçük resmi — yoksa ikon gösterir.
class _RatingThumb extends StatelessWidget {
  const _RatingThumb({required this.photoUrl, this.size = 44});
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: context.surfaceColor,
      child: const Icon(Icons.restaurant_rounded,
          color: AppColors.textDisabled, size: 20),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: (photoUrl != null && photoUrl!.isNotEmpty)
          ? Image.network(
              photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
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
              Icon(Icons.chevron_right_rounded,
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

// ── İstek listesi swipe-to-delete ────────────────────────────────────────────

class _WishlistSwipeItem extends StatefulWidget {
  const _WishlistSwipeItem({
    super.key,
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final VoidCallback onDelete;

  @override
  State<_WishlistSwipeItem> createState() => _WishlistSwipeItemState();
}

class _WishlistSwipeItemState extends State<_WishlistSwipeItem>
    with SingleTickerProviderStateMixin {
  static const _revealWidth = 72.0;

  late final AnimationController _ctrl;
  double _offset = 0;
  double _animStart = 0;
  double _animEnd = 0;
  bool _deleting = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )
      ..addListener(() {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        if (mounted) {
          setState(() => _offset = _animStart + (_animEnd - _animStart) * t);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _deleting && mounted) {
          widget.onDelete();
        }
      });
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _animateTo(double target, {bool delete = false}) {
    _deleting = delete;
    _animStart = _offset;
    _animEnd = target;
    _ctrl.forward(from: 0);
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _snapBack,
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _snapBack() {
    _removeOverlay();
    _animateTo(0);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_deleting) return;
    _ctrl.stop();
    setState(() => _offset = (_offset + d.delta.dx).clamp(-300.0, 0.0));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_deleting) return;
    final velocity = d.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (velocity < -1200 || _offset < -(screenWidth * 0.5)) {
      _removeOverlay();
      _animateTo(-(screenWidth + 40), delete: true);
    } else if (_offset < -(_revealWidth * 0.35) || velocity < -300) {
      _animateTo(-_revealWidth);
      _showOverlay();
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        if (_offset < -1)
          Positioned(
            top: 0,
            right: 0,
            bottom: 8,
            child: SizedBox(
              width: _revealWidth,
              child: GestureDetector(
                onTap: widget.onDelete,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(_offset, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

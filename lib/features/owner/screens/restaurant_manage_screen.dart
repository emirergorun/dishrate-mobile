import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/file_repository.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/widgets/image_crop_dialog.dart';
import '../../reviews/screens/menu_item_reviews_screen.dart';

class RestaurantManageScreen extends StatefulWidget {
  const RestaurantManageScreen({super.key, required this.restaurant});
  final RestaurantModel restaurant;

  @override
  State<RestaurantManageScreen> createState() => _RestaurantManageScreenState();
}

class _RestaurantManageScreenState extends State<RestaurantManageScreen> {
  late RestaurantModel _restaurant;
  List<MenuItemModel> _menu = [];
  List<CategoryModel> _categories = [];
  bool _loading = true;
  String? _error;

  final _repo = RestaurantRepository.instance;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getRestaurantMenu(_restaurant.restaurantId),
        _repo.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _menu = results[0] as List<MenuItemModel>;
          _categories = results[1] as List<CategoryModel>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Menü yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _parseError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
    }
    return fallback;
  }

  // ── Menü öğesi ekle/düzenle ─────────────────────────────────────────────────
  Future<void> _openMenuItemForm({MenuItemModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MenuItemFormSheet(
        restaurantId: _restaurant.restaurantId,
        categories: _categories,
        existing: existing,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteItem(MenuItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        title: Text('Ürünü Sil', style: AppTextStyles.titleSmall),
        content: Text('"${item.name}" silinsin mi?', style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteMenuItem(item.menuItemId);
      _snack('Ürün silindi.');
      _load();
    } catch (e) {
      _snack(_parseError(e, 'Silinemedi, tekrar dene.'), error: true);
    }
  }

  // ── Restoran bilgisi düzenle ────────────────────────────────────────────────
  Future<void> _editRestaurantInfo() async {
    final updated = await showModalBottomSheet<RestaurantModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RestaurantEditSheet(restaurant: _restaurant),
    );
    if (updated != null && mounted) {
      setState(() => _restaurant = updated);
      _snack('Restoran bilgileri güncellendi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(_restaurant.name, style: AppTextStyles.titleMedium),
        iconTheme: IconThemeData(color: context.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            tooltip: 'Restoran bilgisini düzenle',
            onPressed: _editRestaurantInfo,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openMenuItemForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ürün Ekle'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _centered(Icons.cloud_off_rounded, _error!,
          OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')));
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Restoran bilgi kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _restaurant.fullAddress.isNotEmpty
                      ? _restaurant.fullAddress
                      : [_restaurant.district, _restaurant.city]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(', '),
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Menü', style: AppTextStyles.titleSmall),
            const SizedBox(width: 8),
            Text('(${_menu.length})',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        if (_menu.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Henüz ürün yok. "Ürün Ekle" ile başla.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._menu.map((item) => _MenuManageRow(
                item: item,
                onEdit: () => _openMenuItemForm(existing: item),
                onDelete: () => _deleteItem(item),
                onReviews: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuItemReviewsScreen(
                      menuItemId: item.menuItemId,
                      menuItemName: item.name,
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _centered(IconData icon, String msg, Widget? action) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }
}

// ── Menü satırı (yönetim) ─────────────────────────────────────────────────────

class _MenuManageRow extends StatelessWidget {
  const _MenuManageRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onReviews,
  });
  final MenuItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReviews;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 52,
      height: 52,
      color: context.surfaceElevatedColor,
      child: const Icon(Icons.fastfood_rounded,
          color: AppColors.textDisabled, size: 22),
    );
    return GestureDetector(
      onTap: onReviews,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                ? Image.network(item.photoUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => placeholder)
                : placeholder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.categoryName != null) ...[
                  const SizedBox(height: 2),
                  Text(item.categoryName!, style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
              const PopupMenuItem(value: 'delete', child: Text('Sil')),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ── Menü öğesi ekle/düzenle sheet ─────────────────────────────────────────────

class _MenuItemFormSheet extends StatefulWidget {
  const _MenuItemFormSheet({
    required this.restaurantId,
    required this.categories,
    this.existing,
  });
  final int restaurantId;
  final List<CategoryModel> categories;
  final MenuItemModel? existing;

  @override
  State<_MenuItemFormSheet> createState() => _MenuItemFormSheetState();
}

class _MenuItemFormSheetState extends State<_MenuItemFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _photoCtrl;
  CategoryModel? _category;
  bool _saving = false;
  bool _uploadingPhoto = false;

  bool get _isEdit => widget.existing != null;

  Future<void> _pickAndUploadPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final cropped = await ImageCropDialog.show(
      context,
      imageBytes: bytes,
      circular: false,
      title: 'Ürün Fotoğrafı',
    );
    if (cropped == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await FileRepository.instance
          .uploadBytes(cropped, filename: 'menu-item.png');
      if (mounted) {
        setState(() {
          _photoCtrl.text = url;
          _uploadingPhoto = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      String msg = 'Görsel yüklenemedi.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          msg = data['message'] as String;
        }
      }
      _snack(msg);
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _photoCtrl = TextEditingController(text: e?.photoUrl ?? '');
    if (e?.categoryName != null) {
      for (final c in widget.categories) {
        if (c.name == e!.categoryName) {
          _category = c;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Ürün adı boş olamaz.');
      return;
    }

    setState(() => _saving = true);
    final repo = RestaurantRepository.instance;
    final photo = _photoCtrl.text.trim();
    try {
      if (_isEdit) {
        await repo.updateMenuItem(
          widget.existing!.menuItemId,
          name: name,
          categoryId: _category?.categoryId,
          photoUrl: photo,
        );
      } else {
        await repo.createMenuItem(
          restaurantId: widget.restaurantId,
          name: name,
          categoryId: _category?.categoryId,
          photoUrl: photo,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      String msg = 'Kaydedilemedi, tekrar dene.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) msg = data['message'] as String;
      }
      _snack(msg);
    }
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.bodySmall,
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(_isEdit ? 'Ürünü Düzenle' : 'Yeni Ürün',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            TextField(
                controller: _nameCtrl,
                style: AppTextStyles.bodyMedium,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Ürün adı')),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoryModel?>(
              initialValue: _category,
              isExpanded: true,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.textPrimaryColor),
              dropdownColor: context.surfaceElevatedColor,
              decoration: _dec('Kategori (opsiyonel)'),
              items: [
                const DropdownMenuItem<CategoryModel?>(
                    value: null, child: Text('Kategori yok')),
                ...widget.categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _photoCtrl,
                style: AppTextStyles.bodyMedium,
                keyboardType: TextInputType.url,
                decoration: _dec('Fotoğraf URL (opsiyonel)',
                    hint: 'https://...')),
            const SizedBox(height: 8),
            // Galeriden yükle → URL alanını otomatik doldurur
            OutlinedButton.icon(
              onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
              icon: _uploadingPhoto
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(
                  _uploadingPhoto ? 'Yükleniyor...' : 'Galeriden Yükle'),
            ),
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
                    : Text(_isEdit ? 'Kaydet' : 'Ekle',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Restoran bilgisi düzenle sheet ────────────────────────────────────────────

class _RestaurantEditSheet extends StatefulWidget {
  const _RestaurantEditSheet({required this.restaurant});
  final RestaurantModel restaurant;

  @override
  State<_RestaurantEditSheet> createState() => _RestaurantEditSheetState();
}

class _RestaurantEditSheetState extends State<_RestaurantEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  // Restoran logosu
  String? _logoUrl;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _nameCtrl = TextEditingController(text: r.name);
    _cityCtrl = TextEditingController(text: r.city);
    _districtCtrl = TextEditingController(text: r.district ?? '');
    _addressCtrl = TextEditingController(text: r.fullAddress);
    _logoUrl = r.logoUrl;
  }

  Future<void> _pickLogo() async {
    if (_uploadingLogo) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final cropped = await ImageCropDialog.show(
      context,
      imageBytes: bytes,
      circular: false,
      title: 'Restoran Logosu',
    );
    if (cropped == null || !mounted) return;

    setState(() => _uploadingLogo = true);
    try {
      final url = await FileRepository.instance
          .uploadBytes(cropped, filename: 'logo.png');
      if (mounted) {
        setState(() {
          _logoUrl = url;
          _uploadingLogo = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingLogo = false);
      _snack('Logo yüklenemedi.');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Restoran adı boş olamaz.');
      return;
    }
    if (city.isEmpty) {
      _snack('Şehir boş olamaz.');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await RestaurantRepository.instance.updateRestaurant(
        widget.restaurant.restaurantId,
        name: name,
        city: city,
        district: _districtCtrl.text.trim(),
        fullAddress: _addressCtrl.text.trim(),
        // Yeni logo seçildiyse gönder
        logoUrl:
            _logoUrl != widget.restaurant.logoUrl ? _logoUrl : null,
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      String msg = 'Güncellenemedi, tekrar dene.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) msg = data['message'] as String;
      }
      _snack(msg);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Restoran Bilgisi', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            // Logo — tıkla → galeriden seç → yükle
            Row(
              children: [
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: context.surfaceElevatedColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.dividerColor),
                    ),
                    child: _uploadingLogo
                        ? const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary)),
                          )
                        : (_logoUrl != null && _logoUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.network(_logoUrl!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover),
                              )
                            : const Icon(Icons.add_a_photo_outlined,
                                color: AppColors.textSecondary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Restoran logosu\nDeğiştirmek için tıkla',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _nameCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: _dec('Restoran adı')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: _cityCtrl,
                      style: AppTextStyles.bodyMedium,
                      decoration: _dec('Şehir')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                      controller: _districtCtrl,
                      style: AppTextStyles.bodyMedium,
                      decoration: _dec('İlçe')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _addressCtrl,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                decoration: _dec('Açık adres')),
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
                    : Text('Kaydet',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

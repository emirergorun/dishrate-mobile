import 'package:flutter/material.dart';

import '../../../core/network/claim_repository.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_model.dart';

/// Restoran sahipliği talebi.
///
/// Model şu: katalogdaki her restoran sahipsiz doğar, sahiplik sonradan
/// talep edilir. Bu yüzden ekran tek bir işe hizmet eder — kendi restoranını
/// bul ve "burası benim" de. Yeni restoran oluşturma yolu bilinçli olarak
/// yok: kullanıcının açtığı kayıt katalogda çift girdi ve bölünmüş puan
/// demek. Katalogda olmayan bir restoran şu an admin tarafından ekleniyor.
class RestaurantClaimScreen extends StatefulWidget {
  const RestaurantClaimScreen({super.key});

  @override
  State<RestaurantClaimScreen> createState() => _RestaurantClaimScreenState();
}

class _RestaurantClaimScreenState extends State<RestaurantClaimScreen> {
  final _aramaCtrl = TextEditingController();

  List<RestaurantModel> _sonuclar = const [];
  bool _araniyor = false;
  bool _arandi = false;
  bool _gonderiliyor = false;

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _ara() async {
    final q = _aramaCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _araniyor = true);
    try {
      final r = await RestaurantRepository.instance.searchRestaurants(q);
      if (!mounted) return;
      setState(() {
        _sonuclar = r;
        _araniyor = false;
        _arandi = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _araniyor = false;
        _arandi = true;
        _sonuclar = const [];
      });
      _hata('Arama yapılamadı, tekrar dene.');
    }
  }

  Future<void> _talepEt(RestaurantModel r) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Sahiplik talebi', style: AppTextStyles.titleMedium),
        content: Text(
          '"${r.name}" senin restoranın mı? Talebin incelendikten sonra '
          'menüsünü yönetebileceksin.',
          style:
              AppTextStyles.bodyMedium.copyWith(color: ctx.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Evet, benim'),
          ),
        ],
      ),
    );
    if (onay != true) return;

    setState(() => _gonderiliyor = true);
    try {
      await ClaimRepository.instance.claim(r.restaurantId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _gonderiliyor = false);
      _hata(_mesaj(e));
    }
  }

  String _mesaj(Object e) {
    final s = e.toString();
    // Sunucu 409'da neden bilgisini gövdede veriyor ama Dio hata metnine
    // koymuyor; en olası iki nedeni ayrı ayrı söylemek yerine ikisini
    // kapsayan bir cümle kuruyoruz.
    if (s.contains('409')) {
      return 'Bu restoran için talep açılamadı — sahibi olabilir ya da '
          'bekleyen bir talep olabilir.';
    }
    if (s.contains('404')) return 'Restoran bulunamadı.';
    return 'Talep gönderilemedi, tekrar dene.';
  }

  void _hata(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Restoranımı Sahiplen', style: AppTextStyles.titleMedium),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Restoranını ara ve sahipliğini talep et. Talebin onaylanınca '
            'menüyü, fiyatları ve fotoğrafları sen yönetirsin — mevcut '
            'puanlar ve yorumlar olduğu gibi kalır.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: context.textSecondaryColor),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _aramaCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _ara(),
            decoration: InputDecoration(
              hintText: 'Restoran adı',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                onPressed: _ara,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_araniyor)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            for (final r in _sonuclar) _buildSonuc(r),
            if (_arandi && _sonuclar.isEmpty) _buildBulunamadi(),
          ],
        ],
      ),
    );
  }

  Widget _buildSonuc(RestaurantModel r) {
    final konum =
        [r.district, r.city].where((e) => e != null && e.isNotEmpty).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: ListTile(
        title: Text(r.name, style: AppTextStyles.titleSmall),
        subtitle: Text(konum,
            style: AppTextStyles.bodySmall
                .copyWith(color: context.textSecondaryColor)),
        trailing: _gonderiliyor
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : TextButton(
                onPressed: () => _talepEt(r),
                child: Text('Benim',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primary)),
              ),
      ),
    );
  }

  Widget _buildBulunamadi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bu adla kayıtlı restoran bulunamadı.',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 6),
          Text(
            'Restoranın henüz Dishrate’de yoksa bize yaz — ekleyip '
            'sahipliğini sana verelim.',
            style: AppTextStyles.bodySmall
                .copyWith(color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

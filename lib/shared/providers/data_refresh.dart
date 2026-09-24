import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcının kendi verisi değişti: puan eklendi, düzenlendi ya da silindi.
///
/// Değer her arttığında profil ve günlük sessizce yenilenir. Önceden yalnızca
/// profil dinliyordu; günlük uygulama açılışında bir kez yükleniyor, sonradan
/// verilen puanlar aşağı çekip yenileyene kadar görünmüyordu (profilde 7
/// değerlendirme, günlükte 4 yemek).
final userDataRefreshProvider = StateProvider<int>((ref) => 0);

/// Günlükte vurgulanacak değerlendirmenin kimliği (yoksa `null`).
///
/// Yemek panelindeki "Günlüğe git" bu değeri koyar, Günlük ekranı o karta
/// kaydırıp kısa süre aydınlatır ve değeri sıfırlar.
final diaryFocusProvider = StateProvider<int?>((ref) => null);

/// "İstek listesini aç" isteği. Her artış bir istek: yemek panelindeki
/// "Tümünü gör" bunu artırır, Profil ekranı istek listesi panelini açar.
/// Sayaç kullanılıyor; aynı istek art arda gelirse bool değişiklik saymazdı.
final wishlistOpenRequestProvider = StateProvider<int>((ref) => 0);

/// Günlükte silinmiş ama "Geri al" süresi dolmadığı için sunucuya henüz
/// gitmemiş değerlendirmeler, yemek kimliğine göre.
///
/// Silme isteği şerit kapanınca gidiyor; o 5 saniye içinde sunucu kaydı hâlâ
/// döndürüyor. Yemek paneli bu kayda bakıp "Bu yemeği daha önce denedin."
/// diyordu, kullanıcı az önce sildiği yemeği İstek Listesi'ne ekleyemiyordu
/// (24 Eylül). Kullanıcının kendi puanına bakan her yer, burada olan yemeği
/// puanlanmamış sayar.
final pendingRatingDeletesProvider =
    NotifierProvider<PendingRatingDeletes, Map<int, PendingRatingDelete>>(
        PendingRatingDeletes.new);

class PendingRatingDelete {
  const PendingRatingDelete({
    required this.ratingId,
    required this.menuItemId,
    required this.commitNow,
  });

  final int ratingId;
  final int menuItemId;

  /// Beklemeyi bırakıp silmeyi hemen gönderir. Sunucu sildiyse `true`.
  final Future<bool> Function() commitNow;
}

class PendingRatingDeletes extends Notifier<Map<int, PendingRatingDelete>> {
  @override
  Map<int, PendingRatingDelete> build() => const {};

  void add(PendingRatingDelete pending) =>
      state = {...state, pending.menuItemId: pending};

  void remove(int ratingId) {
    if (!state.values.any((p) => p.ratingId == ratingId)) return;
    state = {
      for (final e in state.entries)
        if (e.value.ratingId != ratingId) e.key: e.value,
    };
  }

  /// Bu yemeğin bekleyen silmesi varsa hemen gönderir ve sonucunu bekler.
  /// Bekleyen silme yoksa `true` döner.
  Future<bool> commitNow(int menuItemId) async {
    final pending = state[menuItemId];
    if (pending == null) return true;
    return pending.commitNow();
  }
}

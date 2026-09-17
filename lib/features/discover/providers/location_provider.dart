import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/data/turkiye_adres.dart';
import '../../../core/location/location_service.dart';

/// Konum nereden geldi?
enum LocationSource {
  /// Henüz ne izin alındı ne de seçim yapıldı.
  none,

  /// Cihaz konumundan otomatik bulundu.
  gps,

  /// Kullanıcı il/ilçe listesinden kendisi seçti.
  manual,
}

/// Kullanıcının keşfet ekranında baktığı konum.
@immutable
class SelectedLocation {
  const SelectedLocation({
    required this.il,
    this.ilce,
    this.source = LocationSource.none,
    this.latitude,
    this.longitude,
  });

  final String il;

  /// İlçe seçilmemişse il genelinde bakılıyor demektir.
  final String? ilce;

  final LocationSource source;

  /// Yalnızca GPS ile geldiğinde dolu — mesafe sıralaması ve harita
  /// ortalaması için kullanılır.
  final double? latitude;
  final double? longitude;

  bool get hasIlce => ilce != null && ilce!.trim().isNotEmpty;
  bool get hasKoordinat => latitude != null && longitude != null;

  /// Kullanıcı henüz bir şey seçmedi ve konum da alınamadı.
  bool get isUnset => source == LocationSource.none;

  /// Başlıkta gösterilen hâli: "Beyoğlu, İstanbul" veya "İstanbul".
  String get etiket => hasIlce ? '$ilce, $il' : il;

  @override
  bool operator ==(Object other) =>
      other is SelectedLocation &&
      other.il == il &&
      other.ilce == ilce &&
      other.source == source;

  @override
  int get hashCode => Object.hash(il, ilce, source);
}

class LocationNotifier extends StateNotifier<SelectedLocation> {
  LocationNotifier() : super(_varsayilan) {
    _restore();
  }

  /// MVP İstanbul odaklı; hiçbir bilgi yokken buradan başlıyoruz.
  static const _varsayilan = SelectedLocation(il: 'İstanbul');

  static const _storage = FlutterSecureStorage();
  static const _ilKey = 'dishrate_konum_il';
  static const _ilceKey = 'dishrate_konum_ilce';
  static const _kaynakKey = 'dishrate_konum_kaynak';

  Future<void> _restore() async {
    try {
      final il = await _storage.read(key: _ilKey);
      if (il == null || il.isEmpty) {
        // Kayıt yoksa: izin daha önce verilmişse sistem penceresi
        // açılmadan konumu sessizce alabiliriz.
        await _trySilentGps();
        return;
      }
      final ilce = await _storage.read(key: _ilceKey);
      final kaynak = await _storage.read(key: _kaynakKey);
      state = SelectedLocation(
        il: il,
        ilce: ilce,
        source: kaynak == 'manual' ? LocationSource.manual : LocationSource.gps,
      );
      // Kullanıcı elle seçtiyse GPS onu ezmesin.
      if (kaynak != 'manual') await _trySilentGps();
    } catch (_) {
      // Konum kritik veri değil; varsayılanla devam.
    }
  }

  /// İzin zaten verilmişse konumu tazeler. İzin yoksa **pencere açmaz** —
  /// izin isteme anını [requestGps] yönetir.
  Future<void> _trySilentGps() async {
    if (!await LocationService.hasPermission()) return;
    final result = await LocationService.resolve();
    if (result.isOk) _applyPlace(result.place!);
  }

  /// Kullanıcı bilinçli olarak konum istedi — sistem penceresi burada açılır.
  /// Sonucu arayan taraf kullanıcıya anlatabilsin diye geri döndürülür.
  Future<LocationResult> requestGps() async {
    final result = await LocationService.resolve();
    if (result.isOk) _applyPlace(result.place!);
    return result;
  }

  void _applyPlace(ResolvedPlace place) {
    // Geocoder'ın verdiği adı kendi listemizdeki yazımla eşleştiriyoruz;
    // "Istanbul" / "İstanbul" gibi farklar filtrelemeyi bozmasın.
    final il = _normalizeIl(place.il) ?? state.il;
    final ilce = _normalizeIlce(il, place.ilce);
    state = SelectedLocation(
      il: il,
      ilce: ilce,
      source: LocationSource.gps,
      latitude: place.latitude,
      longitude: place.longitude,
    );
    _persist(il, ilce, LocationSource.gps);
  }

  String? _normalizeIl(String? ham) {
    if (ham == null) return null;
    final anahtar = TurkiyeAdres.aramaAnahtari(ham);
    for (final il in _iller) {
      if (TurkiyeAdres.aramaAnahtari(il.ad) == anahtar) return il.ad;
    }
    return ham;
  }

  String? _normalizeIlce(String il, String? ham) {
    if (ham == null) return null;
    final ilObj = _iller.where((i) => i.ad == il);
    if (ilObj.isEmpty) return ham;
    final anahtar = TurkiyeAdres.aramaAnahtari(ham);
    for (final ilce in ilObj.first.ilceler) {
      if (TurkiyeAdres.aramaAnahtari(ilce.ad) == anahtar) return ilce.ad;
    }
    return ham;
  }

  List<Il> _iller = const [];

  /// İl listesini önceden yükler — eşleştirme senkron çalışabilsin diye.
  Future<void> warmUp() async {
    if (_iller.isEmpty) _iller = await TurkiyeAdres.iller();
  }

  /// Kullanıcı listeden seçti. Bu seçim GPS tarafından ezilmez.
  Future<void> setManual(String il, {String? ilce}) async {
    state = SelectedLocation(il: il, ilce: ilce, source: LocationSource.manual);
    await _persist(il, ilce, LocationSource.manual);
  }

  Future<void> _persist(String il, String? ilce, LocationSource source) async {
    try {
      await _storage.write(key: _ilKey, value: il);
      await _storage.write(
          key: _kaynakKey, value: source == LocationSource.manual ? 'manual' : 'gps');
      if (ilce == null || ilce.isEmpty) {
        await _storage.delete(key: _ilceKey);
      } else {
        await _storage.write(key: _ilceKey, value: ilce);
      }
    } catch (_) {
      // Yazılamazsa oturum boyunca geçerli kalır.
    }
  }
}

final selectedLocationProvider =
    StateNotifierProvider<LocationNotifier, SelectedLocation>(
  (ref) => LocationNotifier()..warmUp(),
);

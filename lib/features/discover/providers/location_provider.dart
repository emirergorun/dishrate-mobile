import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/data/turkey_addresses.dart';
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
    required this.province,
    this.district,
    this.source = LocationSource.none,
    this.latitude,
    this.longitude,
  });

  final String province;

  /// İlçe seçilmemişse il genelinde bakılıyor demektir.
  final String? district;

  final LocationSource source;

  /// Yalnızca GPS ile geldiğinde dolu — mesafe sıralaması ve harita
  /// ortalaması için kullanılır.
  final double? latitude;
  final double? longitude;

  bool get hasDistrict => district != null && district!.trim().isNotEmpty;
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Kullanıcı henüz bir şey seçmedi ve konum da alınamadı.
  bool get isUnset => source == LocationSource.none;

  /// Başlıkta gösterilen hâli: "Beyoğlu, İstanbul" veya "İstanbul".
  String get tag => hasDistrict ? '$district, $province' : province;

  @override
  bool operator ==(Object other) =>
      other is SelectedLocation &&
      other.province == province &&
      other.district == district &&
      other.source == source;

  @override
  int get hashCode => Object.hash(province, district, source);
}

class LocationNotifier extends StateNotifier<SelectedLocation> {
  LocationNotifier() : super(_fallback) {
    _restore();
  }

  /// MVP İstanbul odaklı; hiçbir bilgi yokken buradan başlıyoruz.
  static const _fallback = SelectedLocation(province: 'İstanbul');

  static const _storage = FlutterSecureStorage();
  static const _provinceKey = 'dishrate_konum_il';
  static const _districtKey = 'dishrate_konum_ilce';
  static const _sourceKey = 'dishrate_konum_kaynak';

  Future<void> _restore() async {
    try {
      final province = await _storage.read(key: _provinceKey);
      if (province == null || province.isEmpty) {
        // Kayıt yoksa: izin daha önce verilmişse sistem penceresi
        // açılmadan konumu sessizce alabiliriz.
        await _trySilentGps();
        return;
      }
      final district = await _storage.read(key: _districtKey);
      final savedSource = await _storage.read(key: _sourceKey);
      state = SelectedLocation(
        province: province,
        district: district,
        source: savedSource == 'manual' ? LocationSource.manual : LocationSource.gps,
      );
      // Kullanıcı elle seçtiyse GPS onu ezmesin.
      if (savedSource != 'manual') await _trySilentGps();
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
    final province = _normalizeProvince(place.province) ?? state.province;
    final district = _normalizeDistrict(province, place.district);
    state = SelectedLocation(
      province: province,
      district: district,
      source: LocationSource.gps,
      latitude: place.latitude,
      longitude: place.longitude,
    );
    _persist(province, district, LocationSource.gps);
  }

  String? _normalizeProvince(String? raw) {
    if (raw == null) return null;
    final lookupKey = TurkeyAddresses.searchKey(raw);
    for (final province in _provinces) {
      if (TurkeyAddresses.searchKey(province.name) == lookupKey) return province.name;
    }
    return raw;
  }

  String? _normalizeDistrict(String province, String? raw) {
    if (raw == null) return null;
    final provinceObj = _provinces.where((i) => i.name == province);
    if (provinceObj.isEmpty) return raw;
    final lookupKey = TurkeyAddresses.searchKey(raw);
    for (final district in provinceObj.first.districts) {
      if (TurkeyAddresses.searchKey(district.name) == lookupKey) return district.name;
    }
    return raw;
  }

  List<Province> _provinces = const [];

  /// İl listesini önceden yükler — eşleştirme senkron çalışabilsin diye.
  Future<void> warmUp() async {
    if (_provinces.isEmpty) _provinces = await TurkeyAddresses.provinces();
  }

  /// Kullanıcı listeden seçti. Bu seçim GPS tarafından ezilmez.
  Future<void> setManual(String province, {String? district}) async {
    state = SelectedLocation(province: province, district: district, source: LocationSource.manual);
    await _persist(province, district, LocationSource.manual);
  }

  Future<void> _persist(String province, String? district, LocationSource source) async {
    try {
      await _storage.write(key: _provinceKey, value: province);
      await _storage.write(
          key: _sourceKey, value: source == LocationSource.manual ? 'manual' : 'gps');
      if (district == null || district.isEmpty) {
        await _storage.delete(key: _districtKey);
      } else {
        await _storage.write(key: _districtKey, value: district);
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

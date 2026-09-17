import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Konum izninin sonucu.
enum LocationOutcome {
  /// İzin verildi ve konum bulundu.
  ok,

  /// Kullanıcı bu seferlik reddetti — ileride tekrar sorulabilir.
  denied,

  /// Kalıcı olarak reddedildi (iOS'ta ilk ret de böyledir). Artık sistem
  /// penceresi gösterilemez; kullanıcı Ayarlar'dan açmalı.
  deniedForever,

  /// Cihazın konum servisi tamamen kapalı.
  serviceDisabled,

  /// Konum alındı ama adrese çevrilemedi ya da beklenmedik bir hata oldu.
  failed,
}

/// Konumdan çözümlenen yer bilgisi.
class ResolvedPlace {
  const ResolvedPlace({
    required this.latitude,
    required this.longitude,
    this.il,
    this.ilce,
  });

  final double latitude;
  final double longitude;
  final String? il;
  final String? ilce;
}

class LocationResult {
  const LocationResult(this.outcome, [this.place]);

  final LocationOutcome outcome;
  final ResolvedPlace? place;

  bool get isOk => outcome == LocationOutcome.ok && place != null;
}

/// Cihaz konumu ve izin yönetimi.
///
/// İzin **açılışta değil**, faydası belli olduğu anda istenir: kullanıcı
/// haritaya girdiğinde veya konum seçiciye dokunduğunda. Sebebi iOS'ta
/// sistem izin penceresinin ömür boyu yalnızca bir kez gösterilebilmesi —
/// kullanıcı uygulamanın ne işe yaradığını görmeden reddederse o şans
/// kalıcı olarak kaybedilir.
abstract final class LocationService {
  /// İzni kontrol eder, gerekirse ister, sonra konumu çözümler.
  static Future<LocationResult> resolve() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(LocationOutcome.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(LocationOutcome.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(LocationOutcome.denied);
    }

    try {
      // İlçe düzeyi için düşük doğruluk yeterli; hem daha hızlı hem daha az pil.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final place = await _reverseGeocode(position.latitude, position.longitude);
      return LocationResult(LocationOutcome.ok, place);
    } catch (_) {
      return const LocationResult(LocationOutcome.failed);
    }
  }

  /// Sistem izin penceresi gösterilebilir mi? (Henüz sorulmamışsa true.)
  static Future<bool> canAsk() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.denied;
  }

  /// İzin hâlihazırda verilmiş mi? (Pencere açmadan kontrol.)
  static Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Kullanıcıyı uygulamanın sistem ayarlarına götürür (kalıcı ret sonrası).
  static Future<void> openSettings() => Geolocator.openAppSettings();

  static Future<ResolvedPlace> _reverseGeocode(double lat, double lng) async {
    try {
      // geocoding 5.x örnek tabanlı API kullanıyor (üst düzey fonksiyon yok).
      // Türkçe yer adları dönsün diye yerel ayar veriliyor.
      final marks = await Geocoding(locale: const Locale('tr', 'TR'))
          .placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) {
        return ResolvedPlace(latitude: lat, longitude: lng);
      }
      final m = marks.first;
      // Türkiye'de iOS/Android geocoder'ları farklı alanları dolduruyor:
      // il genelde administrativeArea, ilçe ise subAdministrativeArea ya da
      // locality oluyor. İkisini de deneyip ilk dolu olanı alıyoruz.
      final il = _ilkDolu([m.administrativeArea]);
      final ilce = _ilkDolu([m.subAdministrativeArea, m.locality, m.subLocality]);
      return ResolvedPlace(
        latitude: lat,
        longitude: lng,
        il: il,
        ilce: ilce,
      );
    } catch (_) {
      // Adres çözümlenemese bile koordinat işe yarar (mesafe sıralaması).
      return ResolvedPlace(latitude: lat, longitude: lng);
    }
  }

  static String? _ilkDolu(List<String?> adaylar) {
    for (final a in adaylar) {
      if (a != null && a.trim().isNotEmpty) return a.trim();
    }
    return null;
  }
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../utils/turkish_text.dart';

/// Türkiye'nin il / ilçe / mahalle listesi.
///
/// Veri uygulamayla birlikte gelir (`assets/data/turkey_addresses.json`, ~417 KB),
/// yani adres formu internet olmadan da çalışır. Kaynak: TÜİK ve İçişleri
/// Bakanlığı'nın kamuya açık idari birim listeleri; büyük harften Türkçe
/// kurallarıyla başlık biçimine dönüştürülmüştür.
///
/// İlk kullanımda çözümlenip bellekte tutulur — adres formu her açıldığında
/// 32.000 kaydı yeniden ayrıştırmanın anlamı yok.
abstract final class TurkeyAddresses {
  static const String _assetPath = 'assets/data/turkey_addresses.json';

  static List<Province>? _cache;
  static Future<List<Province>>? _loading;

  /// Tüm iller, alfabetik. Birden fazla çağrı tek yüklemeyi paylaşır.
  static Future<List<Province>> provinces() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load();
  }

  static Future<List<Province>> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    // Sıralama burada, tek yerde yapılır: veri dosyasının kendi sırası
    // garanti değil ve `List.sort()` Türkçe alfabeyi bilmiyor (Çankaya'yı
    // Z'den sonraya atıyordu). Listeyi kullanan ekranlar ayrıca sıralamaz.
    final list = (decoded['provinces'] as List)
        .map((e) => Province.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => TurkishText.compare(a.name, b.name));
    _cache = list;
    _loading = null;
    return list;
  }

  /// Türkçe'ye duyarlı küçük harf. Bkz. [TurkishText.lower].
  static String turkishLower(String s) => TurkishText.lower(s);

  /// Aksan/işaret farkını yok sayan arama anahtarı — "sisli" ile "Şişli"
  /// eşleşsin diye. Bkz. [TurkishText.searchKey].
  static String searchKey(String s) => TurkishText.searchKey(s);
}

class Province {
  const Province({required this.name, required this.districts});

  final String name;
  final List<District> districts;

  factory Province.fromJson(Map<String, dynamic> json) => Province(
        name: json['name'] as String,
        districts: (json['districts'] as List)
            .map((e) => District.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => TurkishText.compare(a.name, b.name)),
      );
}

class District {
  const District({required this.name, required this.neighborhoods});

  final String name;
  final List<String> neighborhoods;

  factory District.fromJson(Map<String, dynamic> json) => District(
        name: json['name'] as String,
        neighborhoods: (json['neighborhoods'] as List).cast<String>().toList()
          ..sort(TurkishText.compare),
      );
}

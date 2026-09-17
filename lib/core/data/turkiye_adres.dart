import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../utils/turkce.dart';

/// Türkiye'nin il / ilçe / mahalle listesi.
///
/// Veri uygulamayla birlikte gelir (`assets/data/turkiye_adres.json`, ~417 KB),
/// yani adres formu internet olmadan da çalışır. Kaynak: TÜİK ve İçişleri
/// Bakanlığı'nın kamuya açık idari birim listeleri; büyük harften Türkçe
/// kurallarıyla başlık biçimine dönüştürülmüştür.
///
/// İlk kullanımda çözümlenip bellekte tutulur — adres formu her açıldığında
/// 32.000 kaydı yeniden ayrıştırmanın anlamı yok.
abstract final class TurkiyeAdres {
  static const String _assetPath = 'assets/data/turkiye_adres.json';

  static List<Il>? _cache;
  static Future<List<Il>>? _loading;

  /// Tüm iller, alfabetik. Birden fazla çağrı tek yüklemeyi paylaşır.
  static Future<List<Il>> iller() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load();
  }

  static Future<List<Il>> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    // Sıralama burada, tek yerde yapılır: veri dosyasının kendi sırası
    // garanti değil ve `List.sort()` Türkçe alfabeyi bilmiyor (Çankaya'yı
    // Z'den sonraya atıyordu). Listeyi kullanan ekranlar ayrıca sıralamaz.
    final list = (decoded['iller'] as List)
        .map((e) => Il.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => Turkce.karsilastir(a.ad, b.ad));
    _cache = list;
    _loading = null;
    return list;
  }

  /// Türkçe'ye duyarlı küçük harf. Bkz. [Turkce.kucuk].
  static String trLower(String s) => Turkce.kucuk(s);

  /// Aksan/işaret farkını yok sayan arama anahtarı — "sisli" ile "Şişli"
  /// eşleşsin diye. Bkz. [Turkce.aramaAnahtari].
  static String aramaAnahtari(String s) => Turkce.aramaAnahtari(s);
}

class Il {
  const Il({required this.ad, required this.ilceler});

  final String ad;
  final List<Ilce> ilceler;

  factory Il.fromJson(Map<String, dynamic> json) => Il(
        ad: json['ad'] as String,
        ilceler: (json['ilceler'] as List)
            .map((e) => Ilce.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => Turkce.karsilastir(a.ad, b.ad)),
      );
}

class Ilce {
  const Ilce({required this.ad, required this.mahalleler});

  final String ad;
  final List<String> mahalleler;

  factory Ilce.fromJson(Map<String, dynamic> json) => Ilce(
        ad: json['ad'] as String,
        mahalleler: (json['mahalleler'] as List).cast<String>().toList()
          ..sort(Turkce.karsilastir),
      );
}

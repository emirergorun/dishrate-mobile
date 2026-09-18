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

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcının kendi verisi değişti: puan eklendi, düzenlendi ya da silindi.
///
/// Değer her arttığında profil ve günlük sessizce yenilenir. Önceden yalnızca
/// profil dinliyordu; günlük uygulama açılışında bir kez yükleniyor, sonradan
/// verilen puanlar aşağı çekip yenileyene kadar görünmüyordu (profilde 7
/// değerlendirme, günlükte 4 yemek).
final userDataRefreshProvider = StateProvider<int>((ref) => 0);

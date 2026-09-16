import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/theme/app_colors.dart';

/// Haritaların altlık katmanı — harita gösteren her yer bunu kullanır.
///
/// CARTO altlıkları artık anahtar istiyor; anahtarsız istekte her karede
/// "API KEY REQUIRED" yazan gri bir görsel dönüyordu. Geliştirme süresince
/// anahtar gerektirmeyen OpenStreetMap altlığı kullanılıyor. OSM'nin kullanım
/// politikası yoğun trafiğe izin vermiyor: yayından önce anahtarlı bir
/// sağlayıcıya (MapTiler, Stadia vb.) geçilmeli — değişecek tek yer burası.
///
/// OSM'nin koyu teması yok; koyu temada kareler renkleri ters çevrilerek
/// koyulaştırılıyor.
class AppTileLayer extends StatelessWidget {
  const AppTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.dishrate.app',
      maxNativeZoom: 19,
      tileBuilder: context.isDark ? darkModeTileBuilder : null,
    );
  }
}

/// OSM lisansının istediği atıf satırı.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        color: Colors.black.withValues(alpha: 0.45),
        child: const Text(
          '© OpenStreetMap',
          style: TextStyle(fontSize: 9, color: Colors.white),
        ),
      ),
    );
  }
}

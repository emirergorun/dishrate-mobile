import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

/// Tek bir fotoğrafı tam ekran gösterir; iki parmakla yakınlaştırılabilir.
/// Dokununca ya da kapat düğmesiyle kapanır.
abstract final class PhotoViewer {
  static Future<void> open(BuildContext context, String url) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _PhotoViewerPage(url: url),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

class _PhotoViewerPage extends StatelessWidget {
  const _PhotoViewerPage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(TablerIcons.x, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

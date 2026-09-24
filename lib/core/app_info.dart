import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Uygulamanın gerçek sürümü: "1.0.0 (5)" — `pubspec.yaml`'daki
/// `version` ve yapı numarası.
///
/// Önceden Ayarlar'da ve lisans sayfasında elle "1.0.0" yazıyordu; yapı
/// numarası artınca kimse güncellemiyordu.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

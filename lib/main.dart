import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/theme_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'shared/widgets/dishrate_logo.dart';
import 'shared/widgets/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  _registerFontLicenses();
  await _precacheLogo();
  runApp(const ProviderScope(child: DishrateApp()));
}

/// Gömülü fontların OFL lisansları. Paket lisanslarını Flutter kendisi
/// ekliyor; fontları biz eklemezsek lisans sayfasında görünmüyorlar.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in [
      ('Urbanist', 'URBANIST-OFL.txt'),
      ('Poppins', 'POPPINS-OFL.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks(['$name (font)'], text);
    }
  });
}

/// Açılış logosunu uygulama çizilmeden önce çözer.
///
/// Logo büyük bir PNG; çözülmesi birkaç kare sürüyordu. O arada sistem açılış
/// ekranı kaybolup Flutter'ın boş ilk karesi görünüyor, logo bir an sönüp
/// yeniden yanıyordu. Bu süre boyunca sistem açılış ekranı ekranda kalıyor.
Future<void> _precacheLogo() async {
  Future<void> resolveLogo(bool dark) {
    final done = Completer<void>();
    // Ekranda kullanılan sağlayıcının aynısı: önbellek anahtarı tutsun.
    final stream =
        DishrateWordmark.provider(dark).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, __) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
      onError: (_, __) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return done.future;
  }

  // Tema henüz bilinmiyor; iki sürüm de çözülüyor. Bir sorun olursa açılışı
  // bekletmemek için süre sınırı var.
  await Future.wait([resolveLogo(true), resolveLogo(false)])
      .timeout(const Duration(milliseconds: 1500), onTimeout: () => const []);
}

class DishrateApp extends ConsumerWidget {
  const DishrateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding
                    .instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        // Android sistem çubuğu alt menüyle aynı tonda; ayrı sabit renk
        // yazılınca palet değiştiğinde çubuk ile menü arasında şerit kalıyordu.
        systemNavigationBarColor:
            isDark ? AppColors.navBackground : AppColors.lightNavBackground,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Dishrate',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Uygulama yalnızca Türkçe. Cihaz dili ne olursa olsun Flutter'ın hazır
      // metinleri de Türkçe çıksın diye dil sabit.
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _AuthGate(),
    );
  }
}

/// Auth durumuna göre hangi ekranın gösterileceğine karar verir.
/// - loading       → SplashScreen
/// - authenticated → MainScaffold
/// - unauthenticated → LoginScreen
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState.status) {
      AuthStatus.loading => const SplashScreen(),
      AuthStatus.authenticated => const MainScaffold(),
      AuthStatus.unauthenticated => const LoginScreen(),
      // Açılışta sunucuya ulaşılamadı: oturum korunur, tekrar denenir.
      AuthStatus.unreachable => SplashScreen(
          onRetry: () => ref.read(authProvider.notifier).retry(),
        ),
    };
  }
}

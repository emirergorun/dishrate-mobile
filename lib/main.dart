import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_provider.dart';
import 'core/network/local_network_warmup.dart';
import 'core/storage/fresh_install.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/theme_provider.dart';
import 'features/settings/providers/theme_storage.dart';
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
  // Silinip yeniden kurulduysa cihazda kalan oturumu ve tercihleri temizle.
  // Tema okunmadan önce olmalı: sonra çağrılırsa silinecek tercih okunur.
  await FreshInstall.clearIfNeeded();
  // Tema ilk kareden önce bilinmeli; yoksa uygulama bir an yanlış temada açılır.
  final (_, themeMode) =
      await (_precacheLogo(), ThemeStorage.instance.read()).wait;
  runApp(ProviderScope(
    overrides: [
      themeProvider.overrideWith((ref) => ThemeNotifier(themeMode)),
    ],
    child: const DishrateApp(),
  ));
  // Geliştirmede yerel ağ izni açılışta sorulsun; bkz. warmUpLocalNetwork.
  unawaited(warmUpLocalNetwork());
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
  Future<void> resolve(ImageProvider provider) {
    final done = Completer<void>();
    // Ekranda kullanılan sağlayıcının aynısı: önbellek anahtarı tutsun.
    final stream = provider.resolve(ImageConfiguration.empty);
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

  // Açılış turuncu kareyle başlıyor, sonra temaya geçiyor: üç sürüm de
  // hazır olmalı. Bir sorun olursa açılışı bekletmemek için süre sınırı var.
  await Future.wait([
    resolve(DishrateWordmark.brandProvider),
    resolve(DishrateWordmark.provider(true)),
    resolve(DishrateWordmark.provider(false)),
  ]).timeout(const Duration(milliseconds: 1500), onTimeout: () => const []);
}

class DishrateApp extends ConsumerWidget {
  const DishrateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
      builder: (context, child) {
        // Sistem yazı boyutu en fazla %130 uygulanır (karar 23 Eylül).
        // iOS erişilebilirlik boyutları %310'a kadar çıkıyor; o ölçekte
        // düzen ayakta kalmıyor. %130'a kadar her ekran bozulmadan çalışır.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
      home: const _AuthGate(),
    );
  }
}

/// Auth durumuna göre hangi ekranın gösterileceğine karar verir.
/// - loading       → SplashScreen
/// - authenticated → MainScaffold
/// - unauthenticated → LoginScreen
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  /// Açılış ekranı turuncu kareden temaya geçerken bekleniyor. Sunucu daha
  /// hızlı cevap verirse ekran geçişin ortasında değişip zıplıyordu.
  bool _intro = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(SplashScreen.introDuration, () {
      if (mounted) setState(() => _intro = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (_intro) return const SplashScreen();

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

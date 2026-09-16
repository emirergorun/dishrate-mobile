import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  await _logoyuOnceCoz();
  runApp(const ProviderScope(child: DishrateApp()));
}

/// Açılış logosunu uygulama çizilmeden önce çözer.
///
/// Logo büyük bir PNG; çözülmesi birkaç kare sürüyordu. O arada sistem açılış
/// ekranı kaybolup Flutter'ın boş ilk karesi görünüyor, logo bir an sönüp
/// yeniden yanıyordu. Bu süre boyunca sistem açılış ekranı ekranda kalıyor.
Future<void> _logoyuOnceCoz() async {
  Future<void> coz(bool dark) {
    final tamam = Completer<void>();
    // Ekranda kullanılan sağlayıcının aynısı: önbellek anahtarı tutsun.
    final stream =
        DishrateWordmark.provider(dark).resolve(ImageConfiguration.empty);
    late final ImageStreamListener dinleyici;
    dinleyici = ImageStreamListener(
      (_, __) {
        if (!tamam.isCompleted) tamam.complete();
        stream.removeListener(dinleyici);
      },
      onError: (_, __) {
        if (!tamam.isCompleted) tamam.complete();
        stream.removeListener(dinleyici);
      },
    );
    stream.addListener(dinleyici);
    return tamam.future;
  }

  // Tema henüz bilinmiyor; iki sürüm de çözülüyor. Bir sorun olursa açılışı
  // bekletmemek için süre sınırı var.
  await Future.wait([coz(true), coz(false)])
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
    };
  }
}

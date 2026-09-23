import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_storage.dart';

/// Seçili tema. Başlangıç değeri `main.dart`'ta cihazdan okunup veriliyor;
/// böylece ilk kare doğru temada çizilir, koyudan açığa sıçrama olmaz.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(super.initialMode);

  void set(ThemeMode mode) {
    state = mode;
    // Yazma beklenmez: tema anında değişir, kayıt arkadan gider.
    unawaited(ThemeStorage.instance.write(mode));
  }
}

/// Başlangıç değeri verilmezse cihaz ayarı geçerli.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ThemeMode.system),
);

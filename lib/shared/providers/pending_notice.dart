import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kök ekran değişirken gösterilecek tek seferlik mesaj (ör. hesap silindi).
///
/// Mesajı eski ekranda gösterince ekran geçişte kalktığı için bildirim
/// yarıda kesiliyordu; yeni ekran (tanıtım) açılıp geçiş bitince gösterir
/// ve temizler.
final pendingNoticeProvider = StateProvider<String?>((ref) => null);

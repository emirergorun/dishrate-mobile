import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Misafir bu oturumda tanıtımı "Giriş yapmadan devam et" ile geçti mi?
///
/// Kalıcı değil (karar 29 Eylül): giriş yapılmamışken uygulama her açıldığında
/// tanıtım (A1–A4) yeniden gelir, kullanıcı giriş yapmaya teşvik edilir.
/// Çıkış yapınca da `false`'a döner, tanıtım yeniden açılır (`_AuthGate`).
final guestContinuedProvider = StateProvider<bool>((ref) => false);

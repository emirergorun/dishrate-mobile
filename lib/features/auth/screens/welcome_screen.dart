import 'package:flutter/material.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/receipt/receipt_screen.dart';

/// Kayıt tamamlandıktan sonra gösterilen karşılama: kayıt adisyonu (1.9).
///
/// Kullanıcı doğrudan ana ekrana düşmek yerine "ilk fişini" görür: kayıt
/// tarihi, saati, adı ve üye kodu gerçek veriden; sayılar yeni hesapta 0.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return ReceiptScreen(
      data: ReceiptData(
        kind: ReceiptKind.registration,
        fullName: user.fullName,
        username: user.username,
        ratingCount: 0,
        wishlistCount: 0,
        // Eski sunucu kayıt anını göndermiyorsa şimdiki an: kayıt zaten şimdi.
        createdAt: user.createdAt ?? DateTime.now(),
        memberCode: user.memberCode,
      ),
      message: 'Hesabın hazır. İlk tabağını bulmaya ne dersin?',
      buttonLabel: 'Keşfetmeye başla',
    );
  }
}

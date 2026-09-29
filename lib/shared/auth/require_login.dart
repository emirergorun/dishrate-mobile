import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/screens/login_screen.dart';

/// Misafir gezinme (1.8): okuma serbest, yazma giriş ister.
///
/// Yazma işi (İstek Listesi, puan verme, bildirme…) bununla başlar:
/// ```dart
/// if (!await requireLogin(context, ref, reason: '…')) return;
/// // buradan sonrası girişli; iş kaldığı yerden sürer
/// ```
/// Girişliyse hemen `true` döner. Değilse [reason] başlıklı bir panel açılır
/// ("Puan vermek için giriş yap"); oradan giriş ya da kayıt ekranı üstte
/// açılır, başarı olunca hepsi kapanır ve `true` döner, kullanıcı aynı ekranda
/// kalır. Vazgeçerse `false`.
Future<bool> requireLogin(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) async {
  if (ref.read(authProvider).isAuthenticated) return true;
  // Önce neden giriş gerektiğini söyleyen panel; giriş/kayıt ekranı oradan.
  final ok = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: context.sheetColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _LoginPromptSheet(reason: reason),
  );
  return ok == true && ref.read(authProvider).isAuthenticated;
}

/// Kilitli bir işe basınca açılan bağlam paneli ("Puan vermek için giriş
/// yap"). Seçilen ekran panelin üstünde açılır; başarıyla panel `true` ile
/// kapanır ve çağıran iş sürer. Panel kapatılırsa `false`.
class _LoginPromptSheet extends StatelessWidget {
  const _LoginPromptSheet({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    Future<void> go(Future<bool> Function(BuildContext) open) async {
      final ok = await open(context);
      if (ok && context.mounted) Navigator.of(context).pop(true);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(TablerIcons.lock,
                    color: AppColors.primary, size: 24),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(reason,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium
                    .copyWith(color: context.textPrimaryColor)),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Hesabınla puanların, Günlük’ün ve İstek Listesi’n seninle kalır.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.textSecondaryColor),
            ),
            const SizedBox(height: AppSpace.xl),
            ElevatedButton(
              onPressed: () => go(openLogin),
              child: const Text('Giriş yap'),
            ),
            const SizedBox(height: AppSpace.sm),
            TextButton(
              onPressed: () => go(openRegister),
              child: const Text('Kayıt ol'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Giriş ekranını üstte açar; başarılı girişte `true` döner.
Future<bool> openLogin(BuildContext context) async {
  final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return ok == true;
}

/// Kayıt ekranını üstte açar; başarılı kayıtta ("Aramıza hoş geldin"
/// ekranından sonra) `true` döner.
Future<bool> openRegister(BuildContext context) async {
  final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => const RegisterScreen()),
  );
  return ok == true;
}

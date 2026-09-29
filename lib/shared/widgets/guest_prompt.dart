import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/require_login.dart';

/// Misafire giriş daveti (Günlük ve Profil sekmeleri, 1.8). Sekmeler
/// misafirde de duruyor; içerik yerine bu çıkıyor.
class GuestPrompt extends ConsumerWidget {
  const GuestPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.xxl, AppSpace.screen, AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(title,
              style: AppTextStyles.titleMedium
                  .copyWith(color: context.textPrimaryColor)),
          const SizedBox(height: AppSpace.sm),
          Text(message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: AppSpace.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => openLogin(context),
              child: const Text('Giriş yap'),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => openRegister(context),
              child: const Text('Kayıt ol'),
            ),
          ),
        ],
      ),
    );
  }
}

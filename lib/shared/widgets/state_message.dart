import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Boş ve hata durumları için ortak kompozisyon.
///
/// Önceden 15 yerde aynı kalıp vardı: ortada 48px gri ikon, gri cümle,
/// çerçeveli "Tekrar Dene". İkon bir şey anlatmıyordu. Burada başlık ne
/// olduğunu, açıklama ne yapılabileceğini söylüyor; eylem metin butonu.
/// Sola hizalı, çünkü ekranın geri kalanı da sola hizalı okunuyor.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              AppTextStyles.titleMedium.copyWith(color: context.textPrimaryColor),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              message!,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.textSecondaryColor),
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

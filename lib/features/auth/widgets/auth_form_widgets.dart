import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';

/// Giriş, kayıt ve şifre sıfırlama ekranlarının ortak form parçaları.

/// Form içinde kalan hata kutusu.
///
/// Önceden hata alttan çıkan bir bildirimdi ve giriş ekranı baştan kuruluyordu;
/// kullanıcı yazdıklarını kaybediyordu.
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18, color: context.errorTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.errorTextColor),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.suffixIcon,
    this.validator,
    this.identifier = false,
    this.autofillHints,
    this.inputFormatters,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  /// Kullanıcı adı / e-posta alanı: otomatik düzeltme ve öneri kapalı, ASCII
  /// klavye. Önceden iOS "modsim"i "modern"e çeviriyor, Türkçe klavye
  /// "haritatest" yerine "harıtatest" yazdırıyordu; ikisi de girişi bozuyordu.
  final bool identifier;

  /// iOS'un otomatik doldurması (ör. mailden gelen kod: `oneTimeCode`).
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: identifier ? TextInputType.emailAddress : keyboardType,
          autocorrect: !identifier,
          enableSuggestions: !identifier,
          textCapitalization: TextCapitalization.none,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          validator: validator,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textPrimaryColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondaryColor.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: context.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Şifre kuralları — yazdıkça yeşile döner. Kayıt ve şifre sıfırlama
/// ekranları ortak kullanır; boş şifrede hiçbir şey çizmez.
class PasswordRuleChips extends StatelessWidget {
  const PasswordRuleChips({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          children: PasswordValidator.rules.map((rule) {
            final ok = rule.test(password);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 14,
                  color: ok ? AppColors.success : context.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  rule.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: ok ? AppColors.success : context.textSecondaryColor,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

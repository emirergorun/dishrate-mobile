import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/theme_provider.dart';

// ignore_for_file: avoid_positional_boolean_parameters

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ayarlar', style: AppTextStyles.headlineMedium),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: context.dividerColor),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),

          // ── Görünüm bölümü ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'GÖRÜNÜM',
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 8),

          _ThemeOption(
            title: 'Koyu',
            icon: Icons.dark_mode_rounded,
            iconColor: const Color(0xFF5E5CE6),
            selected: themeMode == ThemeMode.dark,
            onTap: () => ref.read(themeProvider.notifier).set(ThemeMode.dark),
          ),
          _ThemeOption(
            title: 'Açık',
            icon: Icons.light_mode_rounded,
            iconColor: const Color(0xFFFFBF00),
            selected: themeMode == ThemeMode.light,
            onTap: () => ref.read(themeProvider.notifier).set(ThemeMode.light),
          ),
          _ThemeOption(
            title: 'Cihaz Ayarları',
            icon: Icons.brightness_auto_rounded,
            iconColor: AppColors.primary,
            selected: themeMode == ThemeMode.system,
            onTap: () =>
                ref.read(themeProvider.notifier).set(ThemeMode.system),
          ),

          const SizedBox(height: 32),

          // ── Uygulama bilgisi ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'HAKKINDA',
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 8),

          _InfoItem(
            icon: Icons.info_outline_rounded,
            label: 'Sürüm',
            value: '1.0.0',
          ),
          _InfoItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Gizlilik Politikası',
            value: '',
            onTap: () {},
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Tema seçim satırı ─────────────────────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : context.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: AppTextStyles.titleSmall),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22)
            else
              Icon(Icons.circle_outlined,
                  color: context.dividerColor, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Bilgi satırı ──────────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.textSecondaryColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
            if (value.isNotEmpty)
              Text(value, style: AppTextStyles.bodySmall)
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: context.textSecondaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}

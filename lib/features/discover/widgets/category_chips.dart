import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pressable.dart';

class CategoryChips extends StatefulWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    this.onSelected,
  });

  final List<String> categories;
  final ValueChanged<String?>? onSelected;

  /// Çipin görünen yüksekliği.
  static const double _chipHeight = 36;

  /// Dokunma alanının çipin üstünden ve altından taşan kısmı. Şerit bu kadar
  /// uzuyor; çevresindeki boşluklar bunu düşerek veriliyor ki çip görünüşte
  /// yerinden oynamasın.
  static const double tapInset = (AppSize.minTap - _chipHeight) / 2;

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Şerit dokunma alanı kadar yüksek, çip ortada: parmak çipin biraz
      // üstüne ya da altına denk gelse de seçim kaçmıyor.
      height: AppSize.minTap,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = _selected == category ||
              (_selected == null && index == 0);

          return _Chip(
            label: category,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selected = isSelected ? null : category;
              });
              widget.onSelected?.call(_selected);
            },
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Seçili çip turuncu değil, metin renginde dolu. Turuncu ana eyleme
    // (Değerlendir, +) ayrılmış; filtre çipi de turuncu olunca ekranın en
    // güçlü vurgusu bir filtre oluyordu.
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Center(
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.curve,
          height: CategoryChips._chipHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          decoration: BoxDecoration(
            color: isSelected ? context.textPrimaryColor : context.fillColor,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 14,
              color: isSelected ? context.bgColor : context.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

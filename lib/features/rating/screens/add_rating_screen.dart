import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../providers/rating_flow_provider.dart';
import 'step1_restaurant_search.dart';
import 'step2_menu_item_select.dart';
import 'step3_rate_item.dart';

class AddRatingScreen extends ConsumerWidget {
  const AddRatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ratingFlowProvider);

    return Column(
      children: [
        // ── Üst Bar ──────────────────────────────────────────────────────
        _TopBar(
          currentStep: state.currentStep,
          canGoBack: state.currentStep > 0,
          onBack: () => ref.read(ratingFlowProvider.notifier).goBack(),
          onClose: () {
            ref.read(ratingFlowProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),

        // ── Adım İçeriği ─────────────────────────────────────────────────
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: AnimatedSwitcher(
              duration: AppMotion.base,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.curve,
                  )),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(state.currentStep),
                child: _buildStep(context, ref, state.currentStep),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, WidgetRef ref, int step) {
    switch (step) {
      case 0:
        return const Step1RestaurantSearch();
      case 1:
        return const Step2MenuItemSelect();
      case 2:
        // Onay artık panelin içinde gösteriliyor (bkz. Step3RateItem);
        // panel kapandıktan sonra ayrıca yeşil bildirim çıkmıyor.
        return Step3RateItem(
          onSuccess: () {
            ref.read(ratingFlowProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Üst Bar ───────────────────────────────────────────────────────────────────

/// Geri · adım çizgisi · kapat.
///
/// Ortadaki başlık ("Restoran Seç") kaldırıldı: hemen altındaki soru
/// ("Nerede yedin?") aynı şeyi söylüyordu ve ekranda iki başlık yarışıyordu.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentStep,
    required this.canGoBack,
    required this.onBack,
    required this.onClose,
  });

  final int currentStep;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Row(
        children: [
          // Görünmez olsa da yer kaplıyor: adım çizgisi her adımda ortada kalsın.
          Opacity(
            opacity: canGoBack ? 1 : 0,
            child: IconButton(
              onPressed: canGoBack ? onBack : null,
              tooltip: 'Geri',
              icon: const Icon(TablerIcons.chevron_left, size: 22),
            ),
          ),
          Expanded(child: Center(child: _StepProgress(step: currentStep))),
          IconButton(
            onPressed: onClose,
            tooltip: 'Kapat',
            icon: Icon(
              TablerIcons.x,
              size: 22,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Adım göstergesi ───────────────────────────────────────────────────────────

/// Üç ince çizgi. Uzayan nokta göstergesi hazır onboarding kalıbıydı; çizgi
/// "üçte neredeyim" sorusunu daha sessiz yanıtlıyor.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Adım ${step + 1} / 3',
      excludeSemantics: true,
      child: SizedBox(
        width: 96,
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.curve,
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.primary : context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

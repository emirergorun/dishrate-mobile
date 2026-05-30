import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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

        // ── Adım Göstergesi ──────────────────────────────────────────────
        _StepIndicator(currentStep: state.currentStep),

        const SizedBox(height: 8),

        // ── Adım İçeriği ─────────────────────────────────────────────────
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
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
        return Step3RateItem(
          onSuccess: () {
            ref.read(ratingFlowProvider.notifier).reset();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Puan kaydedildi!',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Üst Bar ───────────────────────────────────────────────────────────────────

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

  static const _titles = ['Restoran Seç', 'Menüden Seç', 'Puanla'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: canGoBack ? onBack : null,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: canGoBack ? AppColors.textPrimary : Colors.transparent,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              _titles[currentStep.clamp(0, 2)],
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Adım Göstergesi ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == currentStep;
        final isDone = index < currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone || isActive ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

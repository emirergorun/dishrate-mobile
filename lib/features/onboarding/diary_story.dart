import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../shared/widgets/rating_stars.dart';
import 'story_widgets.dart';

/// A3 — "Yediğin her şey günlüğünde."
///
/// Uygulamanın Günlük ekranının küçültülmüşü: A2'de puanlanan Smash Burger
/// büyük kart olarak belirir, küçülüp listenin en üstüne uçar, diğer kartlar
/// aşağı kayar; yeni kart "Günlüğe git" vurgusu gibi turuncudan söner.
class DiaryStory extends StatelessWidget {
  const DiaryStory({
    super.key,
    required this.active,
    required this.controller,
    required this.index,
  });

  final bool active;
  final PageController controller;
  final int index;

  static const _loop = 8.6;

  @override
  Widget build(BuildContext context) {
    return StoryTime(
      active: active,
      stillTime: 6.0,
      builder: (context, seconds) {
        final t = seconds % _loop;
        return StoryPageLayout(
          controller: controller,
          index: index,
          sceneSize: const Size(_Scene.w, _Scene.h),
          scene: _Scene(t: t),
          headline: StoryHeadline(
            semanticLabel: 'Yediğin her şey günlüğünde.',
            lines: [
              const Text('Yediğin her şey', style: OnboardingText.headline),
              Text('günlüğünde.', style: OnboardingText.headlineAccent),
            ],
          ),
        );
      },
    );
  }
}

class _Entry {
  const _Entry(this.image, this.name, this.restaurant, this.score, this.date,
      this.comment);
  final String image;
  final String name;
  final String restaurant;
  final double score;
  final String date;
  final String comment;
}

class _Scene extends StatelessWidget {
  const _Scene({required this.t});
  final double t;

  static const w = 340.0;
  static const h = 480.0;
  static const listTop = 52.0;
  static const cardH = 100.0;
  static const gap = 8.0;

  // Restoran adları uydurma ve genel.
  static const _newEntry = _Entry('burger', 'Smash Burger', 'Burger Atölyesi',
      5.0, '26 Eylül 2026', 'Turşusu efsane.');
  static const _entries = [
    _Entry('baklava', 'Baklava', 'Tatlıcı Usta', 5.0, '22 Eylül 2026',
        'Fıstığı bol, şerbeti tam.'),
    _Entry('pizza', 'Margherita', 'Taş Fırın', 4.0, '19 Eylül 2026',
        'Hamuru incecik.'),
    _Entry('durum', 'Adana Dürüm', 'Ocakbaşı', 4.5, '12 Eylül 2026',
        'Acısı tam kıvamında.'),
  ];

  /// Büyük kartın gelişini geciktiren süre (sn).
  static const _delay = 1.0;

  static double slotY(double k) => listTop + k * (cardH + gap);

  @override
  Widget build(BuildContext context) {
    final fadeOut = 1 - phase(t, 7.9, 8.3, Curves.easeIn);

    // Önce Günlük listesi görünür; büyük kart 1 sn sonra gelir (Emir,
    // 29 Eylül: çok hızlı beliriyordu; 0,6 sn de yetmedi).
    const d = _delay;
    // Büyük kart: belirir, küçülüp listenin başına uçar.
    final bigIn = phase(t, 0.55 + d, 0.9 + d);
    final fly = phase(t, 1.7 + d, 2.35 + d, Curves.easeInOutCubic);
    final bigOut = phase(t, 2.05 + d, 2.35 + d);
    // Liste büyük kart görünürken kararır.
    final dim = phase(t, 0.55 + d, 0.9 + d) * (1 - phase(t, 1.8 + d, 2.3 + d));
    // Eski kartlar bir sıra aşağı kayar.
    final push = phase(t, 1.75 + d, 2.3 + d, Curves.easeInOutCubic);
    // Yeni kart yerine oturur, turuncudan normale söner.
    final newIn = phase(t, 2.05 + d, 2.4 + d);
    final glow = 1 - phase(t, 2.4 + d, 3.8 + d, Curves.easeOut);
    final counted = t >= 2.25 + d;

    const bigW = 280.0;
    const bigH = _BigCard.height;
    final bigCenter = Offset.lerp(
      const Offset(w / 2, 40 + bigH / 2),
      Offset(w / 2, slotY(0) + cardH / 2),
      fly,
    )!;
    final bigScale = lerpDouble(mix(0.92, 1, bigIn), 0.36, fly)!;

    return Opacity(
      opacity: fadeOut,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Başlık satırı: uygulamadaki gibi "Günlüğüm" + sayı
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 40,
            child: Opacity(
              opacity: phase(t, 0, 0.4),
              child: Row(
                children: [
                  const Text(
                    'Günlüğüm',
                    style: TextStyle(
                      fontFamily: AppFonts.active,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  SwapWord(
                    text: counted ? '4 değerlendirme' : '3 değerlendirme',
                    style: const TextStyle(
                      fontFamily: AppFonts.active,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Eski kartlar
          for (var i = 0; i < _entries.length; i++)
            Positioned(
              left: 0,
              right: 0,
              top: slotY(i + push),
              height: cardH,
              child: Opacity(
                opacity: phase(t, 0.08 * (i + 1), 0.08 * (i + 1) + 0.4) *
                    (1 - 0.65 * dim),
                child: _MiniCard(entry: _entries[i]),
              ),
            ),
          // Yeni kart
          if (newIn > 0)
            Positioned(
              left: 0,
              right: 0,
              top: slotY(0),
              height: cardH,
              child: Opacity(
                opacity: newIn,
                child: Transform.scale(
                  scale: mix(0.94, 1, newIn),
                  child: _MiniCard(entry: _newEntry, glow: glow),
                ),
              ),
            ),
          // Büyük kart (A2'nin son hâli)
          if (bigIn > 0 && bigOut < 1)
            Positioned(
              left: bigCenter.dx - bigW / 2,
              top: bigCenter.dy - bigH / 2,
              width: bigW,
              child: Opacity(
                opacity: bigIn * (1 - bigOut),
                child:
                    Transform.scale(scale: bigScale, child: const _BigCard()),
              ),
            ),
        ],
      ),
    );
  }
}

/// Günlük kartının küçültülmüşü (`diary_screen.dart` `_RatingCard` dili):
/// fotoğraf, ad, restoran, yıldız + tarih, sağda puan, altta yorum.
class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.entry, this.glow = 0});
  final _Entry entry;

  /// 1 → turuncu vurgu, 0 → normal kart.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.lerp(
            AppColors.surface, AppColors.primary.withValues(alpha: 0.14), glow),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Color.lerp(AppColors.divider, AppColors.primary, glow)!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(OnboardingAssets.plate(entry.image),
                    width: 44, height: 44, fit: BoxFit.cover, cacheWidth: 160),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: _name),
                    Text(entry.restaurant, style: _meta),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StarRow(rating: entry.score, size: 11),
                        const SizedBox(width: 6),
                        Text(entry.date, style: _date),
                      ],
                    ),
                  ],
                ),
              ),
              Text(entry.score.toStringAsFixed(1), style: _score),
            ],
          ),
          const Spacer(),
          Text(
            '“${entry.comment}”',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _comment,
          ),
        ],
      ),
    );
  }

  static const _name = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );
  static const _meta = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 12,
    height: 1.3,
    color: AppColors.textSecondary,
  );
  static const _date = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 11,
    color: AppColors.textDisabled,
  );
  static const _score = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const _comment = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 12,
    fontStyle: FontStyle.italic,
    color: AppColors.textSecondary,
  );
}

/// A2'nin son kartı: Smash Burger, 5 yıldız, "Mükemmel".
class _BigCard extends StatelessWidget {
  const _BigCard();

  /// Yaklaşık yükseklik; yalnız uçuşun başlangıç ve bitiş merkezi için.
  /// Kart kendi yüksekliğini içeriğinden alır.
  static const height = 12 + 190 + 12 + 22 + 8 + 30 + 14.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(OnboardingAssets.burgerWide,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 900),
          ),
          const SizedBox(height: 12),
          const Text(
            'Smash Burger',
            style: TextStyle(
              fontFamily: AppFonts.active,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 22 / 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const StarRow(rating: 5, size: 22),
              const SizedBox(width: 8),
              Text(ratingLabel(5),
                  style: const TextStyle(
                    fontFamily: AppFonts.active,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  )),
              const Spacer(),
              const Text(
                '5.0',
                style: TextStyle(
                  fontFamily: AppFonts.active,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 30 / 26,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

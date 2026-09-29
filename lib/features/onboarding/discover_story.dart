import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import 'story_widgets.dart';

/// A1 — Keşfet: "Şehrin en iyi [baklavası] nerede?"
///
/// Dört yemek kartı deste hâlinde döner: soldaki öne gelip düzleşir, öndeki
/// sağa-arkaya çekilir. Turuncu kelime kartla birlikte değişir, "nerede?"
/// yerinde kalır (yalnız kelime uzayıp kısaldıkça yana kayar).
class DiscoverStory extends StatelessWidget {
  const DiscoverStory({
    super.key,
    required this.active,
    required this.controller,
    required this.index,
  });

  final bool active;
  final PageController controller;
  final int index;

  static const _dishes = [
    ('baklava', 'Baklava', 'baklavası'),
    ('pizza', 'Pizza', 'pizzası'),
    ('durum', 'Dürüm', 'dürümü'),
    ('burger', 'Burger', 'burgeri'),
  ];

  /// Açılışta kartların yelpaze gibi açılma süresi.
  static const _entry = 0.7;

  /// Her kartın önde kaldığı süre (geçiş dahil) ve geçiş. Videoda geçiş
  /// 0,65 sn'ydi; Emir önce biraz, sonra %15 daha hızlı istedi (27 Eylül).
  static const _hold = 2.21;
  static const _swap = 0.425;

  /// Destenin o anki konumu: tam sayı = bir kart önde, arası = geçiş.
  static double _deck(double t) {
    final c = t - _entry;
    if (c <= 0) return 0;
    final k = (c / _hold).floor();
    final within = c - k * _hold;
    return k + phase(within, _hold - _swap, _hold, Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return StoryTime(
      active: active,
      stillTime: 0,
      builder: (context, t) {
        final deck = _deck(t);
        // Kelime geçişin ortasında değişir; kartla aynı anda okunur.
        final front = (deck + 0.5).floor() % _dishes.length;
        return StoryPageLayout(
          controller: controller,
          index: index,
          sceneSize: const Size(400, 440),
          scene: _Deck(deck: deck, spread: phase(t, 0, _entry)),
          headline: StoryHeadline(
            semanticLabel: 'Şehrin en iyi ${_dishes[front].$3} nerede?',
            lines: [
              const Text('Şehrin en iyi', style: OnboardingText.headline),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwapWord(
                    text: _dishes[front].$3,
                    style: OnboardingText.headlineAccent,
                  ),
                  const Text(' nerede?', style: OnboardingText.headline),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Kartın destedeki yeri. 0 önde, 1 solda (sıradaki), −1 sağda (önceki),
/// ±2 arkada gizli.
class _Slot {
  const _Slot(
      this.dx, this.dy, this.angle, this.scale, this.shade, this.opacity);
  final double dx; // kart genişliği cinsinden
  final double dy; // kart yüksekliği cinsinden
  final double angle; // derece
  final double scale;
  final double shade; // üstüne binen karanlık
  final double opacity;

  static const front = _Slot(0, 0, 0, 1, 0, 1);
  static const left = _Slot(-0.42, 0.07, -9, 0.88, 0.45, 1);
  static const right = _Slot(0.42, 0.07, 9, 0.88, 0.45, 1);
  static const hidden = _Slot(0, 0.1, 0, 0.74, 0.8, 0);

  static _Slot at(double r) {
    // r ∈ [−2, 2): tam sayılar arasında doğrusal geçiş.
    const stops = [hidden, right, front, left, hidden];
    final x = (r + 2).clamp(0.0, 4.0);
    final i = x.floor().clamp(0, 3);
    final f = x - i;
    final a = stops[i], b = stops[i + 1];
    return _Slot(
      lerpDouble(a.dx, b.dx, f)!,
      lerpDouble(a.dy, b.dy, f)!,
      lerpDouble(a.angle, b.angle, f)!,
      lerpDouble(a.scale, b.scale, f)!,
      lerpDouble(a.shade, b.shade, f)!,
      lerpDouble(a.opacity, b.opacity, f)!,
    );
  }
}

class _Deck extends StatelessWidget {
  const _Deck({required this.deck, required this.spread});

  final double deck;

  /// Açılışta 0→1: yan kartlar önden yelpaze gibi açılır.
  final double spread;

  static const cardW = 232.0;
  static const cardH = 290.0;

  @override
  Widget build(BuildContext context) {
    final n = DiscoverStory._dishes.length;
    final cards = <(double, Widget)>[];
    for (var j = 0; j < n; j++) {
      // Kartın desteye göre yeri, [−2, 2) aralığında.
      final r = ((j - deck + 2) % n + n) % n - 2;
      var slot = _Slot.at(r);
      if (spread < 1) {
        // Açılış: her kart önden kendi yerine açılır.
        const f = _Slot.front;
        slot = _Slot(
          mix(f.dx, slot.dx, spread),
          mix(f.dy, slot.dy, spread),
          mix(f.angle, slot.angle, spread),
          mix(f.scale, slot.scale, spread),
          mix(f.shade, slot.shade, spread),
          r.abs() >= 1.5 ? 0 : 1,
        );
      }
      // Öne gelen kart erkenden üste çıkar (videodaki gibi); arkadakiler altta.
      final depth = r > 0 ? r * 0.4 : r.abs();
      cards.add((depth, _placed(j, slot)));
    }
    cards.sort((a, b) => b.$1.compareTo(a.$1));
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [for (final c in cards) c.$2],
    );
  }

  Widget _placed(int j, _Slot s) {
    if (s.opacity <= 0.01) return const SizedBox.shrink();
    final dish = DiscoverStory._dishes[j];
    return Transform.translate(
      offset: Offset(s.dx * cardW, s.dy * cardH),
      child: Transform.rotate(
        angle: s.angle * math.pi / 180,
        child: Transform.scale(
          scale: s.scale,
          child: Opacity(
            opacity: s.opacity,
            child: _DishCard(
              image: OnboardingAssets.card(dish.$1),
              name: dish.$2,
              shade: s.shade,
            ),
          ),
        ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.image,
    required this.name,
    required this.shade,
  });

  final String image;
  final String name;
  final double shade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Deck.cardW,
      height: _Deck.cardH,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        color: Colors.black.withValues(alpha: shade),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 600,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: AppFonts.active,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

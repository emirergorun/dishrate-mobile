import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/rating_stars.dart';
import 'story_widgets.dart';

/// A2 — "Her şeyin en iyisini [keşfet. / kaydet. / ye. / puanla.]"
///
/// Tek bir yemeğin uygulamadaki yolculuğu, döngüyle:
/// 1. keşfet — üç yemeklik liste, Smash Burger'a dokunulur, kart açılır;
/// 2. kaydet — "İstek Listesi’ne ekle" → "İstek Listesi’nde" + şerit;
/// 3. ye — İstek Listesi kartındaki "Sonunda denedim!", burgerden ısırık;
/// 4. puanla — yıldızlar 1.0'dan 5.0'a yarım adımlarla, etiketiyle.
class TasteStory extends StatelessWidget {
  const TasteStory({
    super.key,
    required this.active,
    required this.controller,
    required this.index,
  });

  final bool active;
  final PageController controller;
  final int index;

  /// Döngü uzunluğu (gerçek saniye; [_listHold] dahil).
  static const _loop = 12.75;

  /// Üç burgerlik liste seçimden önce bu kadar daha ekranda kalır: zaman
  /// [_holdAt]'ta durur (Emir, 29 Eylül: %15 daha uzun). Sahnedeki bütün
  /// zamanlar duraklamasız çizelgeye göre yazılı.
  static const _holdAt = 1.4;
  static const _listHold = 0.3;

  static double _clock(double seconds) {
    final t = seconds % _loop;
    return t <= _holdAt ? t : math.max(_holdAt, t - _listHold);
  }

  static String _word(double t) {
    if (t < 2.9) return 'keşfet.';
    if (t < 6.0) return 'kaydet.';
    if (t < 8.4) return 'ye.';
    return 'puanla.';
  }

  @override
  Widget build(BuildContext context) {
    return StoryTime(
      active: active,
      // Hareketi azalt: puanın 5.0'a ulaştığı son kare.
      stillTime: 11.3,
      builder: (context, seconds) {
        final t = _clock(seconds);
        return StoryPageLayout(
          controller: controller,
          index: index,
          sceneSize: const Size(_Scene.w, _Scene.h),
          scene: _Scene(t: t),
          headline: StoryHeadline(
            semanticLabel: 'Her şeyin en iyisini keşfet, kaydet, ye ve puanla.',
            lines: [
              const Text('Her şeyin', style: OnboardingText.headline),
              const Text('en iyisini', style: OnboardingText.headline),
              SwapWord(
                text: _word(t),
                style: OnboardingText.headlineAccent,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Row {
  const _Row(this.image, this.name, this.restaurant, this.score);
  final String image;
  final String name;
  final String restaurant;
  final String score;
}

class _Scene extends StatelessWidget {
  const _Scene({required this.t});
  final double t;

  // Tasarım ölçüleri (sahne FittedBox ile küçülebilir).
  static const w = 340.0;
  static const h = 420.0;
  static const pad = 12.0;
  static const photoW = w - 2 * pad;
  static const photoH = photoW / 1.35;
  static const nameTop = pad + photoH + 14;
  static const actionTop = nameTop + 22 + 12;
  static const actionH = 48.0;
  static const detailH = actionTop + actionH + 14;
  static const rowH = 64.0;
  static const rowGap = 4.0;
  static const listH = pad * 2 + rowH * 3 + rowGap * 2;
  static const bannerTop = detailH + 12;

  static const _rows = [
    // "Her şeyin en iyisini keşfet": üç farklı burger, en iyisi seçilir
    // (Emir, 29 Eylül). Restoran adları uydurma ve genel.
    _Row('burger', 'Smash Burger', 'Burger Atölyesi', '4.8'),
    _Row('cheeseburger', 'Cheeseburger', 'Köşe Burger', '4.3'),
    _Row('onion_burger', 'Soğanlı Burger', 'Mahalle Burgercisi', '3.9'),
  ];

  @override
  Widget build(BuildContext context) {
    // Döngü sonunda sahne söner, başta yeniden belirir.
    final fadeIn = phase(t, 0, 0.35);
    final fadeOut = 1 - phase(t, 11.75, 12.15, Curves.easeIn);
    // Liste → ayrıntı kartı (0 liste, 1 ayrıntı).
    final m = phase(t, 2.1, 2.75, Curves.easeInOutCubic);

    final cardH = lerpDouble(listH, detailH, m)!;
    // Liste sahnede ortalı durur; kart büyürken yukarı yerleşir.
    final cardTop = lerpDouble((h - listH) / 2, 0, m)!;

    return Opacity(
      opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: mix(0.97, 1, fadeIn),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: cardTop,
              height: cardH,
              child: _card(context, m),
            ),
            // "İstek Listesi’ne eklendi." şeridi
            _banner(),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, double m) {
    final rowIn = [0.15, 0.3, 0.45];
    final othersOut = 1 - phase(t, 1.9, 2.2);
    const firstRowY = pad;

    // Smash Burger'ın fotoğrafı: satırdaki küçük kareden kartın üstüne büyür.
    const from = Rect.fromLTWH(pad + 8, firstRowY + 8, 48, 48);
    const to = Rect.fromLTWH(pad, pad, photoW, photoH);
    final photo = Rect.lerp(from, to, m)!;
    final photoRadius = lerpDouble(10, 14, m)!;

    // Ad: satırdaki yerinden kartın altına.
    final nameLeft = lerpDouble(pad + 8 + 48 + 12, pad + 4, m)!;
    final nameTop = lerpDouble(firstRowY + 13, _Scene.nameTop, m)!;
    final nameSize = lerpDouble(15, 18, m)!;

    final rowHighlight =
        phase(t, 1.55, 1.75) * (1 - phase(t, 2.0, 2.4)) * (1 - m);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Seçilen satırın vurgusu
          if (rowHighlight > 0)
            Positioned(
              left: pad,
              right: pad,
              top: firstRowY,
              height: rowH,
              child: Opacity(
                opacity: rowHighlight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          // Diğer iki satır ve ilk satırın kategori/puanı
          for (var i = 0; i < _rows.length; i++)
            Positioned(
              left: pad,
              right: pad,
              top: firstRowY + i * (rowH + rowGap),
              height: rowH,
              child: Opacity(
                opacity: phase(t, rowIn[i], rowIn[i] + 0.4) *
                    (i == 0 ? 1 - phase(m, 0, 0.4, Curves.linear) : othersOut),
                child: Transform.translate(
                  offset:
                      Offset(0, (1 - phase(t, rowIn[i], rowIn[i] + 0.4)) * 12),
                  child: _ListRow(row: _rows[i], showName: i != 0),
                ),
              ),
            ),
          // Smash Burger'ın fotoğrafı (satırdan karta büyüyen)
          Positioned.fromRect(
            rect: photo,
            child: Opacity(
              opacity: phase(t, rowIn[0], rowIn[0] + 0.4),
              child: _Photo(t: t, m: m, radius: photoRadius),
            ),
          ),
          // Smash Burger adı
          Positioned(
            left: nameLeft,
            top: nameTop,
            child: Opacity(
              opacity: phase(t, rowIn[0], rowIn[0] + 0.4),
              child: Text(
                'Smash Burger',
                style: TextStyle(
                  fontFamily: AppFonts.active,
                  fontSize: nameSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          // Satıra dokunuş
          Positioned(
            left: w / 2 - 22,
            top: firstRowY + rowH / 2 - 22,
            child: TapRipple(p: phase(t, 1.5, 2.1, Curves.linear)),
          ),
          // Alt kısım: İstek Listesi → Sonunda denedim! → puan
          Positioned(
            left: pad,
            right: pad,
            top: actionTop,
            height: actionH,
            child: _Action(t: t),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    final inP = phase(t, 4.45, 4.85);
    final outP = phase(t, 5.9, 6.2, Curves.easeIn);
    final v = inP * (1 - outP);
    if (v <= 0) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      right: 0,
      top: bannerTop + (1 - inP) * 14,
      child: Opacity(
        opacity: v,
        child: IgnorePointer(
          child: InfoBanner(
            icon: Icons.check_circle_outline_rounded,
            message: 'İstek Listesi’ne eklendi.',
            actionLabel: 'Tümünü gör',
            onAction: () {},
          ),
        ),
      ),
    );
  }
}

/// Listedeki satır: küçük fotoğraf (ilk satırda ayrı çiziliyor), ad,
/// kategori, puan.
class _ListRow extends StatelessWidget {
  const _ListRow({required this.row, required this.showName});
  final _Row row;

  /// İlk satırın fotoğrafı ve adı karta büyüyeceği için ayrı çiziliyor.
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: showName
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(OnboardingAssets.plate(row.image),
                        fit: BoxFit.cover, cacheWidth: 160),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İlk satırda ad ayrı çiziliyor; yer tutucu aynı yüksekliği korur.
                Opacity(
                  opacity: showName ? 1 : 0,
                  child: Text(row.name, style: _rowName),
                ),
                const SizedBox(height: 2),
                Text(row.restaurant, style: _rowMeta),
              ],
            ),
          ),
          Icon(TablerIcons.star_filled, size: 14, color: context.starColor),
          const SizedBox(width: 4),
          Text(row.score, style: _rowScore),
        ],
      ),
    );
  }

  static const _rowName = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const _rowMeta = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  static const _rowScore = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

/// Smash Burger fotoğrafı: satırda kare tabak, kartta geniş görsel; "ye"
/// adımında sağ üst köşeden aşağı üç ısırık alınır.
class _Photo extends StatelessWidget {
  const _Photo({required this.t, required this.m, required this.radius});
  final double t;
  final double m;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // Üç ısırık: ilki dokunuşla, diğerleri arkasından.
    final bites = [
      for (var i = 0; i < _BitePainter.marks.length; i++)
        phase(t, 7.15 + i * 0.3, 7.5 + i * 0.3, Curves.easeOutBack),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(OnboardingAssets.plate('burger'),
              fit: BoxFit.cover, cacheWidth: 480),
          Opacity(
            opacity: m,
            child: Image.asset(OnboardingAssets.burgerWide,
                fit: BoxFit.cover, cacheWidth: 900),
          ),
          if (bites.first > 0) CustomPaint(painter: _BitePainter(bites)),
        ],
      ),
    );
  }
}

/// Isırık izleri: burgerin sağ üst köşesinden üç büyük, pürüzsüz ısırık —
/// Apple logosundaki gibi yuvarlak. Daireler birbirine yarıçaptan yakın,
/// kesişip tek bir dalgalı ısırık kenarı oluşturuyor (Emir, 29 Eylül: iki
/// küçük ısırık az yenmiş gibi duruyordu; %60 büyüdü, üçe çıktı). Daire
/// merkezi kenarın biraz dışında, böylece ekmekten içbükey parçalar kopar.
///
/// Fotoğrafın zemin rengiyle boyanır: kesip kartın rengini göstermek
/// zeminden koyu lekeler bırakıyordu. Zemin sol üstten sağ alta açıldığı için
/// ısırıklar tek bir yol olarak aynı çapraz geçişle boyanır; ayrı renkli
/// daireler kesiştikleri yerde iz bırakırdı. Kenar noktaları ve renkler
/// `burger_wide.jpg`'de (900×666) ölçüldü; görsel değişirse yeniden ölçülmeli.
class _BitePainter extends CustomPainter {
  _BitePainter(this.bites);

  /// Her ısırığın büyüklüğü, 0→1.
  final List<double> bites;

  /// (kenar x, kenar y — fotoğraf oranı; dışa bakan yön; merkezin kenardan
  /// dışarı kayması, yarıçap cinsinden). Sağ üst çaprazdan başlayıp sağ
  /// yandan köfteye iner (Emir, 29 Eylül: üstten değil sağdan ısırsın).
  static const marks = [
    (0.728, 0.119, Offset(0.47, -0.88), 0.35),
    (0.836, 0.225, Offset(0.79, -0.62), 0.35),
    (0.858, 0.393, Offset(1.0, -0.05), 0.35),
  ];

  /// Isırığın yarıçapı, fotoğraf genişliği cinsinden (0.08'den %60 büyük).
  static const _radius = 0.128;

  /// Zeminin çapraz geçişi (fotoğraf oranı ve renkleri).
  static const _from = Offset(0.556, 0);
  static const _to = Offset(0.806, 0.338);
  static const _colors = [Color(0xFF181E24), Color(0xFF1F2830)];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < marks.length; i++) {
      final k = bites[i];
      if (k <= 0) continue;
      final (x, y, out, shift) = marks[i];
      final r = size.width * _radius * k;
      final c = Offset(size.width * x, size.height * y) + out * (r * shift);
      path.addOval(Rect.fromCircle(center: c, radius: r));
    }
    Offset at(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _colors,
        )
            .createShader(Rect.fromPoints(at(_from), at(_to)))
        // Hafif yumuşak kenar: zeminle arasında çizgi kalmasın.
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
    );
  }

  @override
  bool shouldRepaint(_BitePainter old) => !listEquals(old.bites, bites);
}

/// Kartın alt kısmı; adımlara göre değişir.
class _Action extends StatelessWidget {
  const _Action({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    // Düğmelerin görünürlüğü
    final saveIn = phase(t, 2.85, 3.2);
    final toTried = phase(t, 6.0, 6.3);
    final buttonsOut = phase(t, 8.2, 8.45, Curves.easeIn);
    final ratingIn = phase(t, 8.4, 8.7);

    // "İstek Listesi’ne ekle" → "İstek Listesi’nde" (4.1–4.3)
    final filled = phase(t, 4.1, 4.3);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (saveIn > 0 && toTried < 1)
          Positioned.fill(
            child: Opacity(
              opacity: saveIn * (1 - toTried),
              child: _Button(
                label: filled < 0.5
                    ? 'İstek Listesi’ne ekle'
                    : 'İstek Listesi’nde',
                icon: filled < 0.5
                    ? TablerIcons.bookmark
                    : TablerIcons.bookmark_filled,
                background:
                    Color.lerp(Colors.transparent, AppColors.primary, filled)!,
                border:
                    Color.lerp(AppColors.divider, AppColors.primary, filled)!,
                foreground:
                    Color.lerp(AppColors.textPrimary, Colors.white, filled)!,
              ),
            ),
          ),
        // Uygulamadaki İstek Listesi kartının düğmesiyle aynı görünüş
        if (toTried > 0 && buttonsOut < 1)
          Positioned.fill(
            child: Opacity(
              opacity: toTried * (1 - buttonsOut),
              child: _Button(
                label: 'Sonunda denedim!',
                icon: TablerIcons.star,
                background: Colors.transparent,
                border: AppColors.primary.withValues(alpha: 0.5),
                foreground: AppColors.primary,
              ),
            ),
          ),
        if (ratingIn > 0)
          Positioned.fill(
            child: Opacity(
              opacity: ratingIn,
              child: _Rating(t: t),
            ),
          ),
        // Düğmelere dokunuşlar
        Positioned(
          left: _Scene.photoW / 2 - 22,
          top: _Scene.actionH / 2 - 22,
          child: Stack(
            children: [
              TapRipple(p: phase(t, 3.9, 4.5, Curves.linear)),
              TapRipple(p: phase(t, 6.85, 7.45, Curves.linear)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.active,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Puan satırı: 1.0'dan 5.0'a yarım adımlarla sayar; her adımda dolan yıldız
/// hafifçe büyür, altındaki etiket değişir. Uygulamada 1'in altı verilemiyor.
class _Rating extends StatelessWidget {
  const _Rating({required this.t});
  final double t;

  static const _start = 8.7;

  /// Yarım yıldız adımı. Emir iki kez hızlandırdı (29 Eylül): önce %15
  /// (0.32 → 0.272), sonra %20 (→ 0.227).
  static const _step = 0.227;

  @override
  Widget build(BuildContext context) {
    final i = ((t - _start) / _step).floor().clamp(0, 8);
    final score = 1 + i * 0.5;
    // Bu adımda dolan yıldız ve ne kadar önce doldu.
    final changedAt = _start + i * _step;
    final popStar = score.ceil() - 1;
    final pop = math
        .sin(math.pi * phase(t, changedAt, changedAt + 0.2, Curves.easeOut));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var s = 0; s < 5; s++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Transform.scale(
                        scale: s == popStar ? 1 + 0.25 * pop : 1,
                        child: StarGlyph(
                          fill: (score - s).clamp(0.0, 1.0),
                          size: 26,
                          emptyColor: context.starOutlineColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              // Etiket yalnız 5.0'da, yumuşakça belirir; ara adımlarda satır
              // boş ama yeri korunur, yıldızlar zıplamasın (Emir, 29 Eylül).
              Opacity(
                opacity: score >= 5 ? phase(t, changedAt, changedAt + 0.3) : 0,
                child: Text(
                  // Döngünün sonu: sevinçle (Emir, 29 Eylül).
                  '${ratingLabel(5)}!',
                  style: const TextStyle(
                    fontFamily: AppFonts.active,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            fontFamily: AppFonts.active,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

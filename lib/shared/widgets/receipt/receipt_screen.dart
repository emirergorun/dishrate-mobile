import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../dishrate_logo.dart';

/// Adisyon (1.9): kullanıcının "fişi". Tasarım Claude Cowork'ün videosundan
/// (29 Eylül) uyarlandı: termal yazıcı yuvasından basılarak çıkan bir adisyon.
///
/// İki türü var:
/// - **Kayıt adisyonu:** kayıttan hemen sonra, üstüne turuncu "HOŞ GELDİN"
///   damgası vurulur.
/// - **Kullanıcı adisyonu:** Profil → "Adisyon çıkar"; güncel sayılar, favori
///   3 yemek (profildeki "Favori yemekler"in ilk üçü) ve altta basım anı.
///   Tarih ve saat "Kayıt Tarihi / Kayıt Saati" diye yazar. Damga yok (karar
///   29 Eylül): "ÜYE" yeni bir şey söylemiyor, sayıların üstünü örtüyordu.
///
/// QR yok (karar 29 Eylül): alan adı (2.1) ve açık profil (6.2) gelene kadar
/// yerinde kullanıcı adı kodu durur. İç kimlik (userId) gösterilmez; altta
/// sunucunun verdiği üye kodu var.
enum ReceiptKind { registration, user }

/// Adisyondaki favori yemek satırı: "Lokanta - Yemek", altında konum.
class ReceiptFavorite {
  const ReceiptFavorite({
    required this.restaurant,
    required this.dish,
    this.location,
  });

  final String restaurant;
  final String dish;

  /// "İlçe, İl"; bilinmiyorsa satır çıkmaz.
  final String? location;
}

class ReceiptData {
  const ReceiptData({
    required this.kind,
    required this.fullName,
    required this.username,
    required this.ratingCount,
    required this.wishlistCount,
    this.createdAt,
    this.memberCode,
    this.favorites = const [],
    this.printedAt,
  });

  final ReceiptKind kind;
  final String fullName;
  final String username;
  final int ratingCount;
  final int wishlistCount;

  /// Kayıt anı (yerel saat). Eski sunucuda null → "—".
  final DateTime? createdAt;
  final String? memberCode;

  /// En fazla 3; yalnız kullanıcı adisyonunda.
  final List<ReceiptFavorite> favorites;

  /// Adisyonun çıkarıldığı an (yerel saat); yalnız kullanıcı adisyonunda.
  /// Sayılar o ana ait, paylaşılan adisyonda ne zamandan kaldığı belli olsun.
  final DateTime? printedAt;
}

/// Tam ekran adisyon: yazıcı animasyonu, altta mesaj ve düğme. Temadan
/// bağımsız koyu zemin (tanıtımla aynı dil).
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.data,
    required this.buttonLabel,
    this.message,
    this.buttonArrow = true,
  });

  final ReceiptData data;
  final String buttonLabel;
  final bool buttonArrow;

  /// Adisyonun altındaki kısa metin (kayıtta "Hesabın hazır…").
  final String? message;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    if (_hasStamp && !_stamped && t >= _stampAt) {
      _stamped = true;
      HapticFeedback.mediumImpact();
    }
    setState(() => _t = t);
    if (t > _end) _ticker.stop();
  });
  double _t = 0;
  bool _stamped = false;

  /// Zaman çizelgesi (sn): kağıt basılır, damga vurulur, metin ve düğme gelir.
  /// Damgasız adisyonda metin kağıt biter bitmez gelir.
  static const _printFrom = 0.35;
  static const _printTo = 2.25;
  static const _stampAt = 2.55;
  static const _stampTextAt = 3.0;
  static const _plainTextAt = 2.35;
  static const _end = 3.8;

  /// Damga yalnız kayıt adisyonunda (karar 29 Eylül).
  bool get _hasStamp => widget.data.kind == ReceiptKind.registration;
  double get _textAt => _hasStamp ? _stampTextAt : _plainTextAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _t = _end;
      _stamped = true;
    } else if (!_ticker.isActive && _t == 0) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static double _phase(double t, double a, double b,
      [Curve curve = Curves.easeOutCubic]) {
    final v = ((t - a) / (b - a)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    // Termal yazıcı kağıdı küçük adımlarla iter: düz hareketin üstüne hafif
    // bir titreşim.
    final raw = _phase(t, _printFrom, _printTo, Curves.easeInOut);
    final jitter = raw > 0 && raw < 1 ? math.sin(raw * 60) * 0.004 : 0.0;
    final printed = (raw + jitter).clamp(0.0, 1.0);
    final stamp = _hasStamp
        ? _phase(t, _stampAt, _stampAt + 0.35, Curves.easeOutBack)
        : 0.0;
    final textIn = _phase(t, _textAt, _textAt + 0.5);

    return Theme(
      data: AppTheme.dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Column(
                children: [
                  const SizedBox(height: AppSpace.xl),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: MediaQuery.withNoTextScaling(
                          child: Semantics(
                            label: _semanticLabel(widget.data),
                            excludeSemantics: true,
                            child: _Printer(
                              data: widget.data,
                              printed: printed,
                              stamp: stamp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: AppSpace.xl),
                    Opacity(
                      opacity: textIn,
                      child: Text(
                        widget.message!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  Opacity(
                    opacity: textIn,
                    child: Transform.translate(
                      offset: Offset(0, (1 - textIn) * 16),
                      child: IgnorePointer(
                        ignoring: textIn < 0.5,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.buttonLabel),
                                if (widget.buttonArrow) ...[
                                  const SizedBox(width: AppSpace.sm),
                                  const Icon(TablerIcons.arrow_right, size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _semanticLabel(ReceiptData d) {
    final title = d.kind == ReceiptKind.registration
        ? 'Kayıt adisyonu'
        : 'Kullanıcı adisyonu';
    final favorites = d.favorites.isEmpty
        ? ''
        : ' Favori yemekler: '
            '${d.favorites.map((f) => '${f.restaurant}, ${f.dish}').join('; ')}.';
    final at = d.printedAt;
    final printed = at == null
        ? ''
        : ' ${_Paper.formatDate(at)} ${_Paper.formatTime(at)} tarihinde çıkarıldı.';
    return '$title. ${d.fullName}, @${d.username}. '
        '${d.ratingCount} değerlendirme, İstek Listesi’nde ${d.wishlistCount} yemek.'
        '$favorites$printed';
  }
}

/// Yazıcı yuvası ve içinden çıkan adisyon.
class _Printer extends StatelessWidget {
  const _Printer({
    required this.data,
    required this.printed,
    required this.stamp,
  });

  final ReceiptData data;

  /// 0 → kağıt yuvanın içinde, 1 → tamamı dışarıda.
  final double printed;

  /// Damga, 0→1 (easeOutBack; 1'i biraz aşar).
  final double stamp;

  static const paperWidth = 320.0;
  static const slotWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kağıt yuvanın üstünde; yuvanın altında kalan kısmı görünmez.
          ClipRect(
            child: FractionalTranslation(
              translation: Offset(0, 1 - printed),
              child: SizedBox(
                width: paperWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _Paper(data: data),
                    if (stamp > 0)
                      Positioned(
                        left: 42,
                        right: 42,
                        top: _Paper.stampTop,
                        child: _Stamp(
                          progress: stamp,
                          year: data.createdAt?.year ?? DateTime.now().year,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Yazıcı yuvası
          Container(
            width: slotWidth,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1918),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2826)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: slotWidth - 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adisyon kağıdı.
class _Paper extends StatelessWidget {
  const _Paper({required this.data});
  final ReceiptData data;

  static const _paper = Color(0xFFF1EEE6);
  static const _ink = Color(0xFF1B1A18);
  static const _faint = Color(0xFF6B665E);

  /// Damganın kağıttaki yeri (sayıların üstü).
  static const stampTop = 196.0;

  static const _mono = TextStyle(
    fontFamily: AppFonts.receipt,
    fontSize: 13,
    height: 1.55,
    color: _ink,
  );

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String formatDate(DateTime at) =>
      '${_two(at.day)}.${_two(at.month)}.${at.year}';

  static String formatTime(DateTime at) =>
      '${_two(at.hour)}:${_two(at.minute)}';

  @override
  Widget build(BuildContext context) {
    final registration = data.kind == ReceiptKind.registration;
    final at = data.createdAt;
    final date = at == null ? '—' : formatDate(at);
    final time = at == null ? '—' : formatTime(at);
    final printedAt = data.printedAt;

    return ClipPath(
      clipper: const _ZigzagTop(),
      child: Container(
        color: _paper,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kağıt açık renk: tema koyu olsa da logonun açık zemin sürümü.
            Center(
              child: Image(
                image: DishrateWordmark.provider(false),
                width: 132,
                height: 132 / DishrateWordmark.aspectRatio,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              registration ? 'KAYIT ADİSYONU' : 'KULLANICI ADİSYONU',
              textAlign: TextAlign.center,
              style: _mono.copyWith(
                  fontSize: 11, letterSpacing: 3.5, color: _faint),
            ),
            const _Dashed(),
            _row(registration ? 'Tarih' : 'Kayıt Tarihi', date),
            _row(registration ? 'Saat' : 'Kayıt Saati', time),
            _row('Misafir', data.fullName),
            _row('Kullanıcı', '@${data.username}'),
            const _Dashed(),
            _row('Değerlendirme', '${data.ratingCount}'),
            _row('İstek Listesi', '${data.wishlistCount}'),
            if (!registration && data.favorites.isNotEmpty) ...[
              const _Dashed(),
              Text(
                'FAVORİ YEMEKLER',
                style: _mono.copyWith(
                    fontSize: 11, letterSpacing: 2.5, color: _faint),
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < data.favorites.length; i++)
                _favorite(i + 1, data.favorites[i]),
            ],
            const SizedBox(height: 10),
            // Çift kalın çizgi (adisyonun toplam çizgisi)
            Container(height: 1.6, color: _ink),
            const SizedBox(height: 3),
            Container(height: 1.6, color: _ink),
            const SizedBox(height: 18),
            // QR'ın yeri: şimdilik kullanıcı adı kodu (QR 2.1 + 6.2 ile).
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border:
                    Border.all(color: _ink.withValues(alpha: 0.85), width: 1.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '@${data.username}',
                  style: _mono.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.memberCode == null ? 'DR' : 'DR-${data.memberCode}',
              textAlign: TextAlign.center,
              style:
                  _mono.copyWith(fontSize: 11, letterSpacing: 3, color: _faint),
            ),
            // Basım anı: sayılar bu ana ait (karar 29 Eylül).
            if (!registration && printedAt != null)
              Text(
                '${formatDate(printedAt)} · ${formatTime(printedAt)}',
                textAlign: TextAlign.center,
                style: _mono.copyWith(
                    fontSize: 11, letterSpacing: 1.5, color: _faint),
              ),
          ],
        ),
      ),
    );
  }

  /// "1. Lokanta - Yemek", altında soluk konum.
  Widget _favorite(int rank, ReceiptFavorite f) {
    const indent = 26.0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: indent, child: Text('$rank.', style: _mono)),
              Expanded(
                child: Text(
                  '${f.restaurant} - ${f.dish}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _mono.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
          if (f.location != null)
            Padding(
              padding: const EdgeInsets.only(left: indent),
              child: Text(
                f.location!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _mono.copyWith(fontSize: 11, color: _faint),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _mono),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _mono,
          ),
        ),
      ],
    );
  }
}

/// Kesikli ayraç.
class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashPainter(),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _Paper._faint.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(
          Offset(x, 0), Offset(math.min(x + 3, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

/// Kağıdın üst kenarı: yırtılmış gibi zikzak.
class _ZigzagTop extends CustomClipper<Path> {
  const _ZigzagTop();

  static const _tooth = 10.0;
  static const _depth = 6.0;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, _depth);
    var x = 0.0;
    while (x < size.width) {
      path.lineTo(math.min(x + _tooth / 2, size.width), 0);
      path.lineTo(math.min(x + _tooth, size.width), _depth);
      x += _tooth;
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_ZigzagTop old) => false;
}

/// Turuncu mürekkep damgası: "HOŞ GELDİN", altında "DISHRATE · yıl".
/// Büyükten vurularak iner, hafif eğik. Yalnız kayıt adisyonunda.
class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.progress,
    required this.year,
  });

  final double progress;
  final int year;

  static const title = 'HOŞ GELDİN';

  static const _ink = Color(0xFFE8612C);

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return Opacity(
      opacity: p.clamp(0.0, 1.0) * 0.88,
      child: Transform.rotate(
        angle: -8 * math.pi / 180,
        child: Transform.scale(
          scale: 1.8 - 0.8 * p,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            decoration: BoxDecoration(
              border: Border.all(color: _ink, width: 2.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.active,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 0.5,
                      color: _ink,
                    ),
                  ),
                ),
                Text(
                  'DISHRATE · $year',
                  style: const TextStyle(
                    fontFamily: AppFonts.active,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

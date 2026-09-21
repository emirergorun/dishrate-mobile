import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Sola kaydırarak silme. Günlük kartları ve istek listesi öğeleri kullanır.
///
/// - Biraz kaydırınca kart kırmızı alanı açıp durur; kırmızıya dokunmak siler,
///   başka yere dokunmak kapatır.
/// - Ekranın yarısını geçince ya da hızlı kaydırınca doğrudan siler.
/// - Silme iki adımda oynar: kart ekrandan kayar, ardından satır yumuşakça
///   kapanır. [onDelete] ancak ikisi bitince çağrılır.
/// - Karttaki "Sil" / "Listeden çıkar" düğmeleri de [builder]'a verilen
///   `swipeAway` ile aynı animasyonu oynatır.
class SwipeToDelete extends StatefulWidget {
  const SwipeToDelete({
    super.key,
    required this.builder,
    required this.onDelete,
    this.radius = 16,
    this.sideInset = 0,
    this.bottomGap = 0,
    this.revealWidth = 80,
    this.iconSize = 24,
    this.animateIn = false,
  });

  final Widget Function(BuildContext context, VoidCallback swipeAway) builder;
  final VoidCallback onDelete;

  /// Kartın köşe yarıçapı. Kırmızı alan kartın altına bu kadar uzanır ki
  /// yuvarlak köşelerin arkasında boşluk kalmasın.
  final double radius;

  /// Kartın yan kenar boşluğu (kartın `margin`'i).
  final double sideInset;

  /// Kartın alt boşluğu; kırmızı alan kartla aynı yükseklikte kalsın.
  final double bottomGap;

  /// Yarım açıkken görünen kırmızı genişlik.
  final double revealWidth;
  final double iconSize;

  /// Geri alınan öğe listeye dönerken satır yumuşakça açılır.
  final bool animateIn;

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete>
    with TickerProviderStateMixin {
  static const _slideDuration = Duration(milliseconds: 240);
  static const _swipeAwayDuration = Duration(milliseconds: 320);
  static const _sizeDuration = Duration(milliseconds: 280);

  late final AnimationController _slide;
  late final AnimationController _size;
  late final Animation<double> _sizeCurve;

  double _offset = 0;
  double _animStart = 0;
  double _animEnd = 0;
  Curve _curve = Curves.easeOutCubic;
  bool _deleting = false;
  OverlayEntry? _overlayEntry;
  final _deleteAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: _slideDuration)
      ..addListener(() {
        final t = _curve.transform(_slide.value);
        setState(() => _offset = _animStart + (_animEnd - _animStart) * t);
      })
      ..addStatusListener((status) {
        // Kart ekrandan çıktı; şimdi satır kapanır.
        if (status == AnimationStatus.completed && _deleting) {
          _size.reverse();
        }
      });
    _size = AnimationController(
      vsync: this,
      duration: _sizeDuration,
      value: widget.animateIn ? 0 : 1,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && _deleting && mounted) {
          widget.onDelete();
        }
      });
    _sizeCurve = CurvedAnimation(parent: _size, curve: Curves.easeInOut);
    if (widget.animateIn) _size.forward();
  }

  @override
  void dispose() {
    _removeOverlay();
    _slide.dispose();
    _size.dispose();
    super.dispose();
  }

  void _animateTo(double target,
      {bool delete = false,
      Duration duration = _slideDuration,
      Curve curve = Curves.easeOutCubic}) {
    _deleting = delete;
    _animStart = _offset;
    _animEnd = target;
    _curve = curve;
    _slide.duration = duration;
    _slide.forward(from: 0);
  }

  // Kart açıkken ekranın tamamına saydam overlay: dokunuşları o alır.
  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) => _onOverlayTap(details.globalPosition),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _snapBack() {
    _removeOverlay();
    _animateTo(0);
  }

  /// Overlay en üstte olduğu için kırmızı alanın kendi dokunma dinleyicisine
  /// sıra gelmez; kırmızıya düşen dokunuş burada konumla ayıklanır. Kartın
  /// altında kalan köşe payı sayılmaz.
  void _onOverlayTap(Offset position) {
    final box =
        _deleteAreaKey.currentContext?.findRenderObject() as RenderBox?;
    var onDeleteArea = false;
    if (box != null && box.hasSize) {
      final visible = box.localToGlobal(Offset(widget.radius, 0)) &
          Size(box.size.width - widget.radius, box.size.height);
      onDeleteArea = visible.contains(position);
    }
    onDeleteArea ? _swipeAway() : _snapBack();
  }

  /// Kartı ekrandan kaydırır, satırı kapatır, sonra siler.
  void _swipeAway() {
    if (_deleting) return;
    _removeOverlay();
    _animateTo(
      -(MediaQuery.sizeOf(context).width + 40),
      delete: true,
      duration: _swipeAwayDuration,
      curve: Curves.easeInCubic,
    );
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_deleting) return;
    _slide.stop();
    setState(() => _offset = (_offset + d.delta.dx).clamp(-300.0, 0.0));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_deleting) return;
    final velocity = d.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (velocity < -1200 || _offset < -(screenWidth * 0.5)) {
      _swipeAway();
    } else if (_offset < -(widget.revealWidth * 0.35) || velocity < -300) {
      _animateTo(-widget.revealWidth);
      _showOverlay();
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeCurve,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _sizeCurve,
        child: LayoutBuilder(builder: (context, constraints) {
          final cardWidth = constraints.maxWidth - 2 * widget.sideInset;
          final revealed = (-_offset).clamp(0.0, cardWidth).toDouble();
          // Kırmızı alan kartın altına köşe yarıçapı kadar uzanır.
          final redWidth =
              (revealed + widget.radius).clamp(0.0, cardWidth).toDouble();
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Kart kaymaya başlamadan gösterilmiyor.
              if (revealed > 1)
                Positioned(
                  top: 0,
                  right: widget.sideInset,
                  bottom: widget.bottomGap,
                  width: redWidth,
                  child: Container(
                    key: _deleteAreaKey,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(widget.radius),
                    ),
                    // Simge görünen kırmızının ortasında durur.
                    padding: EdgeInsets.only(left: widget.radius),
                    alignment: Alignment.center,
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: Icon(Icons.delete_rounded,
                          color: Colors.white, size: widget.iconSize),
                    ),
                  ),
                ),
              // Kart (kaydırılabilir) — açıkken dokunuşları overlay yakalar.
              Transform.translate(
                offset: Offset(_offset, 0),
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: widget.builder(context, _swipeAway),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_theme.dart';
import 'account_step.dart';
import 'diary_story.dart';
import 'discover_story.dart';
import 'story_widgets.dart';
import 'taste_story.dart';

/// Giriş yapılmamışken her açılışta ve her çıkıştan sonra gösterilen tanıtım
/// (1.8; önce yalnız ilk kurulumdaydı, karar 29 Eylül).
///
/// Tasarım Emir'in videolarından (26 Eylül): üç hikâye sayfası (Keşfet →
/// Nasıl çalışır → Günlük) ve son adımda hesap: kayıt ol, giriş yap ya da
/// giriş yapmadan devam et. Karar (25 Eylül): hesap son sayfada önerilir, ayrı bir
/// "emin misin?" penceresi yok; giriş yapmadan devam yolu eşit görünür
/// (Apple 5.1.1).
///
/// Tanıtım temadan bağımsız hep koyu (karar 26 Eylül): videolar koyu, son
/// adım siyah; ekranlar arasında renk sıçraması olmasın.
///
/// "Devam et" sayfa ilk açıldığında kısa bir süre sonra belirir; sayfalar
/// kaydırılarak da geçilir, "Atla" doğrudan hesap adımına götürür.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  /// "Giriş yapmadan devam et" — tanıtım biter, misafir olarak Keşfet açılır.
  /// Giriş/kayıt başarılı olursa auth durumu değişir, kapı kendisi geçer.
  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _storyCount = 3;
  static const _accountIndex = _storyCount;

  /// Sayfa ilk açıldıktan bu kadar sonra "Devam et" belirir.
  static const _buttonDelay = Duration(milliseconds: 900);

  final _pages = PageController();
  int _index = 0;

  /// "Devam et"in göründüğü sayfalar; geri dönülen sayfada hemen görünür.
  final Set<int> _ready = {};
  Timer? _readyTimer;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      OnboardingAssets.precache(context);
      _scheduleButton(_index);
    }
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _scheduleButton(int page) {
    _readyTimer?.cancel();
    if (_ready.contains(page)) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _ready.add(page);
      return;
    }
    _readyTimer = Timer(_buttonDelay, () {
      if (mounted) setState(() => _ready.add(page));
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _scheduleButton(i);
  }

  void _next() => _pages.nextPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic);

  void _skip() => _pages.animateToPage(_accountIndex,
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeInOutCubic);

  /// Hesap adımına yaklaştıkça 1'den 0'a: üst sıra ve "Devam et" söner.
  double _storyChrome() {
    final page = _pages.hasClients && _pages.position.haveDimensions
        ? _pages.page ?? _index.toDouble()
        : _index.toDouble();
    return 1 - (page - (_accountIndex - 1)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _topBar(),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: _onPageChanged,
                        children: [
                          DiscoverStory(
                              active: _index == 0,
                              controller: _pages,
                              index: 0),
                          TasteStory(
                              active: _index == 1,
                              controller: _pages,
                              index: 1),
                          DiaryStory(
                              active: _index == 2,
                              controller: _pages,
                              index: 2),
                          AccountStep(
                            active: _index == _accountIndex,
                            controller: _pages,
                            index: _accountIndex,
                            onExplore: widget.onFinished,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: AppSpace.screen,
                  right: AppSpace.screen,
                  bottom: AppSpace.lg,
                  child: _nextButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Üst sıra: sayfa noktaları + "Atla". Hesap adımında söner.
  Widget _topBar() {
    return AnimatedBuilder(
      animation: _pages,
      builder: (context, child) {
        final v = _storyChrome();
        return Opacity(
          opacity: v,
          child: IgnorePointer(ignoring: v < 0.5, child: child),
        );
      },
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: Row(
            children: [
              _Dots(
                count: _storyCount,
                index: _index.clamp(0, _storyCount - 1),
              ),
              const Spacer(),
              TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
                child: const Text('Atla'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hikâye sayfalarının ortak düğmesi: sayfa kayarken yerinde durur,
  /// yazısı değişir. Hesap adımında söner (orada kendi düğmeleri var).
  Widget _nextButton() {
    final shown = _ready.contains(_index) && _index < _accountIndex;
    return AnimatedBuilder(
      animation: _pages,
      builder: (context, child) {
        final v = _storyChrome();
        return Opacity(
          opacity: v,
          child: IgnorePointer(ignoring: v < 0.5 || !shown, child: child),
        );
      },
      child: AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: const Duration(milliseconds: 350),
        child: AnimatedSlide(
          offset: shown ? Offset.zero : const Offset(0, 0.3),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _index == _storyCount - 1 ? 'Başlayalım' : 'Devam et',
                      key: ValueKey(_index == _storyCount - 1),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  const Icon(TablerIcons.arrow_right, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sayfa ${index + 1} / $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 6),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? AppColors.primary : AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}

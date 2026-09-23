import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';

/// Tek satırlık bilgi şeridi: ikon + metin + isteğe bağlı eylem düğmesi.
///
/// Yemek panelinde ("daha önce denedin", "istek listesine eklendi") ve
/// silmelerden sonra ("… silindi · Geri al") aynı görünümle kullanılır.
/// Alt panellerde SnackBar kullanılamıyor: ScaffoldMessenger panelin
/// ALTINDAKİ Scaffold'a bağlı olduğu için mesaj panelin arkasında kalıyor;
/// şerit panelin kendi içine konur.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;
    // Şerit kendiliğinden beliriyor: ekran okuyucu içeriği duyursun, yoksa
    // "… silindi" ve "Geri al" görmeyen kullanıcıdan tamamen kaçıyor.
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(AppSpace.md, hasAction ? 4 : 12,
            hasAction ? 4 : AppSpace.md, hasAction ? 4 : 12),
        // Açık temada gri dolgu yerine beyaz zemin + kenarlık + hafif gölge;
        // günlükte kartların üstünde yüzerken de ayrışır.
        decoration: BoxDecoration(
          color: context.isDark
              ? context.surfaceElevatedColor
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.dividerColor),
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.textSecondaryColor),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textPrimaryColor),
              ),
            ),
            if (hasAction)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Alt alta dizilen şeritler: en yenisi en altta, eskiler yukarı kayar.
///
/// Şerit gelirken açılıp belirir, giderken solup kapanır; alttaki ve üstteki
/// şeritler bu sırada yumuşakça yer değiştirir. Listeden çıkan şerit
/// animasyonu bitene kadar son hâliyle çizilmeye devam eder.
/// Her şeridin benzersiz bir `key`i olmalı.
class InfoBannerStack extends StatefulWidget {
  const InfoBannerStack({
    super.key,
    required this.banners,
    this.gap = AppSpace.sm,
    this.trailingGap = 0,
  });

  /// Eskiden yeniye sıralı şeritler.
  final List<Widget> banners;

  /// Her şeridin üstündeki boşluk; şeritle birlikte açılıp kapanır.
  final double gap;

  /// Şerit varken yığının altında kalan boşluk (ör. ekranın alt güvenli alanı).
  final double trailingGap;

  @override
  State<InfoBannerStack> createState() => _InfoBannerStackState();
}

class _StackEntry {
  _StackEntry(this.child);
  Widget child;
  bool leaving = false;
  Key get key => child.key!;
}

class _InfoBannerStackState extends State<InfoBannerStack> {
  static const _duration = Duration(milliseconds: 280);

  late final List<_StackEntry> _entries =
      widget.banners.map(_StackEntry.new).toList();

  @override
  void didUpdateWidget(InfoBannerStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = {for (final b in widget.banners) b.key!: b};

    // Kalanlar güncellenir, gidenler son hâlleriyle "çıkıyor" olarak kalır.
    for (final entry in _entries) {
      final next = incoming[entry.key];
      if (next != null) {
        entry.child = next;
        entry.leaving = false;
      } else {
        entry.leaving = true;
      }
    }

    // Yeni gelenler kendinden önceki şeridin hemen arkasına girer.
    Key? previous;
    for (final banner in widget.banners) {
      final key = banner.key!;
      if (!_entries.any((e) => e.key == key)) {
        final at = previous == null
            ? 0
            : _entries.indexWhere((e) => e.key == previous) + 1;
        _entries.insert(at, _StackEntry(banner));
      }
      previous = key;
    }
  }

  void _removeGone(Key key) {
    if (!mounted) return;
    setState(() => _entries.removeWhere((e) => e.key == key && e.leaving));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: _duration,
      curve: Curves.easeInOut,
      padding: EdgeInsets.only(
          bottom: widget.banners.isEmpty ? 0 : widget.trailingGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in _entries)
            _BannerEntry(
              key: entry.key,
              gap: widget.gap,
              leaving: entry.leaving,
              duration: _duration,
              onGone: () => _removeGone(entry.key),
              child: entry.child,
            ),
        ],
      ),
    );
  }
}

/// Tek şeridin giriş (açılma, alttan kayma, belirme) ve çıkış (solma,
/// kapanma) animasyonu.
class _BannerEntry extends StatefulWidget {
  const _BannerEntry({
    super.key,
    required this.gap,
    required this.leaving,
    required this.duration,
    required this.onGone,
    required this.child,
  });

  final double gap;
  final bool leaving;
  final Duration duration;
  final VoidCallback onGone;
  final Widget child;

  @override
  State<_BannerEntry> createState() => _BannerEntryState();
}

class _BannerEntryState extends State<_BannerEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.dismissed && widget.leaving) {
            widget.onGone();
          }
        })
        ..forward();

  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

  @override
  void didUpdateWidget(_BannerEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving != oldWidget.leaving) {
      widget.leaving ? _ctrl.reverse() : _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Boşluk da şeritle birlikte açılıp kapanır; yığında sıçrama olmaz.
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(top: widget.gap),
        child: FadeTransition(
          opacity: _curve,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                .animate(_curve),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'min_tap_area.dart';

/// Düzenleme panellerinde değişiklik varken kapatmadan önce sorar (günlük
/// düzenleme ve profil düzenleme).
///
/// Üç kapanış yolu aynı yere gelir: sağ üstteki "İptal et"
/// ([SheetCancelButton]), panelin dışına basma ([PopScope]) ve aşağı
/// kaydırma. Değişiklik yoksa panel hemen kapanır; varsa [discardMessage]
/// sorulur, "Geri dön" paneli olduğu gibi bırakır.
///
/// Panel `showModalBottomSheet(enableDrag: false)` ile açılmalı: Flutter'ın
/// kendi kaydırarak kapatması `Navigator.pop` çağırıyor, `PopScope`'a
/// sormuyor; değişiklik sessizce kayboluyordu. Kaydırmayı bu widget yönetir.
class EditSheetGuard extends StatefulWidget {
  const EditSheetGuard({
    super.key,
    required this.isDirty,
    required this.discardMessage,
    required this.child,
    this.busy = false,
  });

  final bool isDirty;

  /// Kaydetme ya da yükleme sürerken panel kapatılamaz.
  final bool busy;

  /// Onay penceresinin sorusu, ör. "Güncellemeyi iptal etmek istiyor musun?".
  final String discardMessage;

  final Widget child;

  /// Paneldeki bir düğmeden kapatmayı ister ([SheetCancelButton] bunu
  /// kullanır). [context] korumanın altında olmalı.
  static void requestClose(BuildContext context) =>
      context.findAncestorStateOfType<_EditSheetGuardState>()?._requestClose();

  @override
  State<EditSheetGuard> createState() => _EditSheetGuardState();
}

class _EditSheetGuardState extends State<EditSheetGuard> {
  /// Aşağı kaydırılan mesafe; panel parmağı izler.
  double _dragOffset = 0;
  bool _dragging = false;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragging = true;
      _dragOffset = (_dragOffset + d.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final close = _dragOffset > 100 || d.velocity.pixelsPerSecond.dy > 700;
    setState(() {
      _dragging = false;
      _dragOffset = 0;
    });
    if (close) _requestClose();
  }

  Future<void> _requestClose() async {
    if (widget.busy) return;
    if (!widget.isDirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        content: Text(widget.discardMessage, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Geri dön'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.errorTextColor),
            child: const Text('İptal et'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isDirty && !widget.busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: AnimatedContainer(
          duration:
              _dragging ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _dragOffset, 0),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Düzenleme panelinin başlık satırındaki kırmızı "İptal et" ("Hesabı sil"
/// ile aynı renk). [EditSheetGuard]'ın altında kullanılmalı.
class SheetCancelButton extends StatelessWidget {
  const SheetCancelButton({super.key, required this.semanticLabel});

  /// Ekran okuyucu için ne iptal edildiği, ör. "Düzenlemeyi iptal et".
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => EditSheetGuard.requestClose(context),
        child: MinTapArea(
          child: Text(
            'İptal et',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.errorTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

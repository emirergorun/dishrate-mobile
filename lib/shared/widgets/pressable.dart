import 'package:flutter/material.dart';

import '../../core/theme/app_metrics.dart';

/// Dokunulabilir yüzeylerin basılma geri bildirimi.
///
/// Kartlar ve satırlar düz `GestureDetector` ile yazılmıştı; dokunuşun
/// algılandığı ancak yeni ekran açılınca anlaşılıyordu. Hafif küçülme iOS'un
/// kendi listelerindeki hisse yakın, Material dalgası gibi yabancı durmuyor.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final enabled = widget.onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        child: AnimatedScale(
          scale: _down && animate ? widget.scale : 1,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: AnimatedOpacity(
            opacity: _down ? 0.85 : 1,
            duration: AppMotion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

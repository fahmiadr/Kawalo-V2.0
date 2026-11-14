import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

/// The 180 px round primary action of a Beranda task card (redesign 2026).
///
/// Three modes, chosen by the callbacks given:
/// * tap: [onPressed];
/// * hold: [onHoldStart] on touch down, [onHoldEnd] on release or cancel
///   (PTT, held like a walkie-talkie);
/// * timed hold: [holdDuration] plus [onHoldComplete]; a progress ring fills
///   while held and [onHoldComplete] fires once it is full, releasing earlier
///   only calls [onHoldEnd] (SOS "tahan 3 detik").
///
/// With no callback the button is inert and drawn [dimmed].
///
/// In the hold modes the button claims the pointer at touch down, so a
/// surrounding `PageView` cannot start a swipe on it (the Flutter equivalent
/// of CSS `touch-action: none`). [onHoldEnd] is the callback captured at touch
/// down, and it also runs if the button is disposed mid-hold, so a hold is
/// always released even when the widget is rebuilt or removed.
class AppRoundActionButton extends StatefulWidget {
  const AppRoundActionButton({
    required this.icon,
    required this.label,
    required this.tone,
    super.key,
    this.onPressed,
    this.onHoldStart,
    this.onHoldEnd,
    this.holdDuration,
    this.onHoldComplete,
    this.active = false,
    this.dimmed = false,
    this.size = 180,
    this.semanticLabel,
    this.semanticHint,
  });

  final IconData icon;
  final String label;
  final KawaloTone tone;
  final VoidCallback? onPressed;
  final VoidCallback? onHoldStart;
  final VoidCallback? onHoldEnd;
  final Duration? holdDuration;
  final VoidCallback? onHoldComplete;

  /// Pressed look with a halo, e.g. while transmitting.
  final bool active;

  /// Grey look (waiting, unavailable); still interactive if callbacks are set.
  final bool dimmed;
  final double size;
  final String? semanticLabel;
  final String? semanticHint;

  bool get _holdMode =>
      onHoldStart != null || onHoldEnd != null || onHoldComplete != null;

  bool get _enabled => onPressed != null || _holdMode;

  @override
  State<AppRoundActionButton> createState() => _AppRoundActionButtonState();
}

class _AppRoundActionButtonState extends State<AppRoundActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this)
    ..addStatusListener(_onProgressStatus);
  int? _pointer;
  VoidCallback? _endOfHold;
  VoidCallback? _completeOfHold;

  bool get _held => _pointer != null;

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_held) return;
    final complete = _completeOfHold;
    _completeOfHold = null;
    complete?.call();
  }

  void _down(PointerDownEvent event) {
    if (_held || !widget._holdMode) return;
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _pointer = event.pointer);
    _endOfHold = widget.onHoldEnd;
    _completeOfHold = widget.onHoldComplete;
    widget.onHoldStart?.call();
    final duration = widget.holdDuration;
    if (duration != null) {
      _progress
        ..duration = duration
        ..forward(from: 0);
    }
  }

  void _up(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _release();
  }

  void _release() {
    _pointer = null;
    _completeOfHold = null;
    _progress.reset();
    final end = _endOfHold;
    _endOfHold = null;
    end?.call();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_held) {
      final end = _endOfHold;
      _endOfHold = null;
      end?.call();
    }
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final dimmed = widget.dimmed || !widget._enabled;
    final bg = dimmed ? tones.surface2 : widget.tone.color;
    final fg = dimmed ? tones.ink3 : widget.tone.on;
    final pressed = widget.active || _held;
    final reduceMotion = AppMotion.isReducedMotion(context);

    Widget circle = AnimatedScale(
      scale: pressed && !reduceMotion ? 0.97 : 1,
      duration: AppMotion.short4,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppMotion.short4,
        width: widget.size,
        height: widget.size,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          boxShadow: pressed && !dimmed
              ? [
                  BoxShadow(color: widget.tone.soft, spreadRadius: 12),
                  BoxShadow(
                    color: widget.tone.soft.withValues(alpha: 0.5),
                    spreadRadius: 26,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 46, color: fg),
            const SizedBox(height: 6),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.holdDuration != null) {
      circle = SizedBox.square(
        dimension: widget.size + 20,
        child: CustomPaint(
          painter: _RingPainter(
            progress: _progress,
            color: widget.tone.color,
            track: dimmed ? tones.surface2 : widget.tone.soft,
          ),
          child: Center(child: circle),
        ),
      );
    }

    Widget semantics(Widget child) => Semantics(
      button: true,
      enabled: widget._enabled,
      label: widget.semanticLabel ?? widget.label,
      hint: widget.semanticHint,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: child,
    );

    if (widget.onPressed != null) {
      return semantics(
        Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            child: circle,
          ),
        ),
      );
    }
    if (!widget._holdMode) return semantics(circle);

    return semantics(
      RawGestureDetector(
        gestures: {
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (_) {},
              ),
        },
        child: Listener(
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: circle,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = track);
    if (progress.value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.value,
        true,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.track != track;
}

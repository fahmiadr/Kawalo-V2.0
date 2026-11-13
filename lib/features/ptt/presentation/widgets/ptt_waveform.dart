import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/features/ptt/presentation/utils/ptt_duration_format.dart';

/// Seekable bar waveform of a recording, used like a [Slider]: [onChanged]
/// follows the finger, [onChangeEnd] commits the seek. Tap or drag anywhere.
///
/// [bars] are the server's loudness values (`0..255`). Without them every bar
/// is drawn at the same low height: an honest "no shape known", never an
/// invented one.
class PttWaveform extends StatefulWidget {
  const PttWaveform({
    required this.bars,
    required this.value,
    required this.total,
    required this.playedColor,
    required this.unplayedColor,
    super.key,
    this.onChanged,
    this.onChangeEnd,
  });

  static const double barWidth = 3;
  static const double barGap = 2;
  static const double maxBarHeight = 28;
  static const double minBarHeight = 3;

  /// Height of every bar when the recording has no waveform.
  static const int fallbackLevel = 40;

  final Uint8List? bars;

  /// Played fraction, `0..1`.
  final double value;
  final Duration total;
  final Color playedColor;
  final Color unplayedColor;

  /// Null disables seeking (the recording is not loaded).
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<PttWaveform> createState() => _PttWaveformState();
}

class _PttWaveformState extends State<PttWaveform> {
  /// Where the finger is while dragging; the player position would otherwise
  /// pull the bar back under it.
  double? _drag;

  bool get _enabled => widget.onChanged != null;

  double get _shown => _drag ?? widget.value;

  /// One TalkBack step: a tenth of the clip, but at least a second.
  double get _semanticStep {
    final ms = widget.total.inMilliseconds;
    if (ms <= 0) return 1;
    return math.max(0.1, 1000 / ms).clamp(0.0, 1.0);
  }

  String _label(double fraction) {
    final total = widget.total;
    final at = Duration(
      milliseconds: (total.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
    );
    return '${formatPttDuration(at)} dari ${formatPttDuration(total)}';
  }

  void _dragTo(double fraction) {
    setState(() => _drag = fraction);
    widget.onChanged?.call(fraction);
  }

  void _commit(double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    setState(() => _drag = null);
    widget.onChanged?.call(f);
    widget.onChangeEnd?.call(f);
  }

  @override
  Widget build(BuildContext context) {
    final step = _semanticStep;
    final value = _shown;
    return Semantics(
      slider: true,
      enabled: _enabled,
      label: 'Posisi rekaman',
      value: _label(value),
      increasedValue: _enabled ? _label(value + step) : null,
      decreasedValue: _enabled ? _label(value - step) : null,
      onIncrease: _enabled ? () => _commit(value + step) : null,
      onDecrease: _enabled ? () => _commit(value - step) : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          double at(Offset local) =>
              width <= 0 ? 0 : (local.dx / width).clamp(0.0, 1.0);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapUp: _enabled ? (d) => _commit(at(d.localPosition)) : null,
            onHorizontalDragStart: _enabled
                ? (d) => _dragTo(at(d.localPosition))
                : null,
            onHorizontalDragUpdate: _enabled
                ? (d) => _dragTo(at(d.localPosition))
                : null,
            onHorizontalDragEnd: _enabled ? (_) => _commit(_shown) : null,
            onHorizontalDragCancel: _enabled
                ? () => setState(() => _drag = null)
                : null,
            child: SizedBox(
              width: width,
              height: AppStateLayer.minTouchTarget,
              child: CustomPaint(
                painter: PttWaveformPainter(
                  bars: widget.bars,
                  value: value,
                  playedColor: widget.playedColor,
                  unplayedColor: widget.unplayedColor,
                  showThumb: _enabled,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PttWaveformPainter extends CustomPainter {
  const PttWaveformPainter({
    required this.bars,
    required this.value,
    required this.playedColor,
    required this.unplayedColor,
    required this.showThumb,
  });

  final Uint8List? bars;
  final double value;
  final Color playedColor;
  final Color unplayedColor;
  final bool showThumb;

  static int barCountFor(double width) => math.max(
    1,
    ((width + PttWaveform.barGap) / (PttWaveform.barWidth + PttWaveform.barGap))
        .floor(),
  );

  /// Resamples [source] to [count] bars, each the loudest value of its slice,
  /// so short peaks survive narrow bubbles.
  static List<int> levels(Uint8List? source, int count) {
    if (source == null || source.isEmpty) {
      return List.filled(count, PttWaveform.fallbackLevel);
    }
    final n = source.length;
    return List.generate(count, (i) {
      final start = i * n ~/ count;
      final end = math.max(start + 1, (i + 1) * n ~/ count);
      var peak = 0;
      for (var j = start; j < end; j++) {
        if (source[j] > peak) peak = source[j];
      }
      return peak;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final count = barCountFor(size.width);
    final heights = levels(bars, count);
    final used =
        count * PttWaveform.barWidth + (count - 1) * PttWaveform.barGap;
    final left = (size.width - used) / 2;
    final centerY = size.height / 2;

    final path = Path();
    for (var i = 0; i < count; i++) {
      final h =
          PttWaveform.minBarHeight +
          (PttWaveform.maxBarHeight - PttWaveform.minBarHeight) *
              heights[i] /
              255;
      final x = left + i * (PttWaveform.barWidth + PttWaveform.barGap);
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centerY - h / 2, PttWaveform.barWidth, h),
          const Radius.circular(PttWaveform.barWidth / 2),
        ),
      );
    }

    // The played colour is clipped at the exact position rather than per bar,
    // so progress moves smoothly instead of in bar-sized steps.
    final split = size.width * value.clamp(0.0, 1.0);
    canvas
      ..drawPath(path, Paint()..color = unplayedColor)
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, split, size.height))
      ..drawPath(path, Paint()..color = playedColor)
      ..restore();

    if (showThumb) {
      canvas.drawCircle(
        Offset(split.clamp(4.0, size.width - 4.0), centerY),
        6,
        Paint()..color = playedColor,
      );
    }
  }

  @override
  bool shouldRepaint(PttWaveformPainter old) =>
      old.value != value ||
      !identical(old.bars, bars) ||
      old.playedColor != playedColor ||
      old.unplayedColor != unplayedColor ||
      old.showThumb != showThumb;
}

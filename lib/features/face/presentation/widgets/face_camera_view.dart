import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';

/// Colours of the dark camera screens (`--cam-*` in `rd.css`); the same in
/// light and dark mode.
const Color _camBg = Color(0xFF0B0F0C);
const Color _camInk = Color(0xFFF3F6F2);
const Color _ovalOk = Color(0xFF8FD694);
const Color _ovalBad = Color(0xFFFFB4AB);

enum FaceCameraPillKind { neutral, ok, bad }

/// Front-camera screen (`RdAbsenWajah*`, `RdWajahDaftar*`): close + title,
/// a rounded viewfinder with the face oval, a status pill on top, the hint
/// under the oval and a small footer. There is no shutter: the cubit takes
/// the photo once the face has been steady.
class FaceCameraView extends StatelessWidget {
  const FaceCameraView({
    required this.title,
    required this.hint,
    required this.hintOk,
    required this.cancelLabel,
    super.key,
    this.hintBad = false,
    this.pill,
    this.pillIcon,
    this.pillKind = FaceCameraPillKind.neutral,
    this.caption,
    this.onCancel,
    this.extraActionLabel,
    this.onExtraAction,
    this.camera,
    this.progress,
    this.busy = false,
  });

  final FaceCamera? camera;
  final String title;
  final String hint;

  /// Green oval: the face passes the gate.
  final bool hintOk;

  /// Red oval: the last attempt failed.
  final bool hintBad;

  final String? pill;
  final IconData? pillIcon;
  final FaceCameraPillKind pillKind;

  /// Small text in the footer, e.g. "Foto tidak disimpan bila gagal".
  final String? caption;

  /// Semantic label of the close button.
  final String cancelLabel;

  /// Null while a request is in flight: leaving would not undo it.
  final VoidCallback? onCancel;

  /// Optional extra choice in the footer ("Lapor ke Admin").
  final String? extraActionLabel;
  final VoidCallback? onExtraAction;

  /// `(done, total)`, e.g. photos taken; drawn as a progress bar.
  final (int, int)? progress;

  /// Spinner before the hint (sending to the server).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final oval = hintBad
        ? _ovalBad
        : hintOk
        ? _ovalOk
        : _camInk;
    final pill = this.pill;
    final caption = this.caption;
    final extra = extraActionLabel != null && onExtraAction != null;

    return Scaffold(
      backgroundColor: _camBg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  if (onCancel == null)
                    const SizedBox(width: 48)
                  else
                    IconButton(
                      tooltip: cancelLabel,
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded, color: _camInk),
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _camInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFF1B231D)),
                      if (camera != null) camera!.buildPreview(context),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _OvalMask(oval, thick: hintOk || hintBad),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (pill != null)
                              _Pill(
                                label: pill,
                                icon: pillIcon,
                                kind: pillKind,
                              ),
                            const Spacer(),
                            Semantics(
                              liveRegion: true,
                              child: _Hint(text: hint, busy: busy),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progress case (final done, final total))
                    Semantics(
                      label: 'Foto $done dari $total',
                      child: SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : done / total,
                            minHeight: 6,
                            color: _ovalOk,
                            backgroundColor: _camInk.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    )
                  else if (caption != null)
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _camInk.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  if (extra) ...[
                    const SizedBox(height: 12),
                    Theme(
                      data: ThemeData.dark(),
                      child: AppTaskButton(
                        label: extraActionLabel!,
                        onPressed: onExtraAction,
                        variant: AppTaskButtonVariant.secondary,
                        size: AppTaskButtonSize.medium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.kind, this.icon});

  final String label;
  final IconData? icon;
  final FaceCameraPillKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      FaceCameraPillKind.ok => (
        const Color(0xFF1D3B20),
        const Color(0xFFB9F0BD),
      ),
      FaceCameraPillKind.bad => (
        const Color(0xFF5A1A15),
        const Color(0xFFFFDAD6),
      ),
      FaceCameraPillKind.neutral => (
        Colors.black.withValues(alpha: 0.55),
        _camInk,
      ),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.busy});

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _camInk,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _camInk,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Darkens everything outside a centred portrait oval.
class _OvalMask extends CustomPainter {
  const _OvalMask(this.borderColor, {required this.thick});

  final Color borderColor;
  final bool thick;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.62;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: width * 1.31,
    );
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas
      ..drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.5))
      ..drawOval(
        oval,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = thick ? 5 : 3,
      );
  }

  @override
  bool shouldRepaint(_OvalMask oldDelegate) =>
      oldDelegate.borderColor != borderColor || oldDelegate.thick != thick;
}

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/task_layout.dart';

/// Colour of the result badge: the Absensi tone, red, or grey.
enum FaceResultTone { success, error, neutral }

/// [style] `filled` is the one primary (64 px, Absensi tone) action; any other
/// style is drawn as a grey secondary button.
class FaceResultAction {
  const FaceResultAction(
    this.label,
    this.onPressed, {
    this.style = AppButtonColor.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonColor style;
}

/// Outcome of the face and attendance flows. Without [screenTitle] it is a
/// result page (`.done`: round badge, no top bar); with it, an explanation
/// inside a task screen (`.es`: top bar with back, rounded-square icon).
class FaceResultLayout extends StatelessWidget {
  const FaceResultLayout({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    super.key,
    this.content = const [],
    this.highlights = const [],
    this.onClose,
    this.screenTitle,
  });

  final FaceResultTone tone;
  final String icon;
  final String title;
  final String message;

  /// Below the message (details).
  final List<Widget> content;

  /// Between the title and the message (big time, status pill).
  final List<Widget> highlights;
  final List<FaceResultAction> actions;
  final VoidCallback? onClose;
  final String? screenTitle;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final screenTitle = this.screenTitle;
    final footer = [
      for (final action in actions)
        if (action.style == AppButtonColor.filled)
          taskPrimary(action.label, action.onPressed, tone: tones.abs)
        else
          taskSecondary(action.label, action.onPressed),
    ];
    final body = TaskMessage(
      icon: AppSvgIcon(icon),
      title: title,
      message: message,
      round: screenTitle == null,
      kind: switch (tone) {
        FaceResultTone.success => TaskMessageKind.tone,
        FaceResultTone.error => TaskMessageKind.bad,
        FaceResultTone.neutral => TaskMessageKind.neutral,
      },
      below: content,
      children: highlights,
    );

    if (screenTitle != null) {
      return TaskScaffold(
        title: screenTitle,
        onClose: onClose,
        scrollable: false,
        body: body,
        footer: footer,
      );
    }
    return Scaffold(
      backgroundColor: tones.background,
      body: SafeArea(
        child: Column(
          children: [
            if (onClose != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconButton(
                    tooltip: 'Tutup',
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded, color: tones.ink),
                  ),
                ),
              ),
            Expanded(child: body),
            AppTaskFooter(children: footer),
          ],
        ),
      ),
    );
  }
}

/// `.box` panel holding [FaceInfoRow]s or text.
class FaceInfoCard extends StatelessWidget {
  const FaceInfoCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => TaskBox(children: children);
}

/// Label above a bold value, with a leading icon.
class FaceInfoRow extends StatelessWidget {
  const FaceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Row(
      children: [
        AppSvgIcon(icon, size: 22, color: tones.abs.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: tones.ink2, fontSize: 13)),
              Text(
                value,
                style: TextStyle(
                  color: tones.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

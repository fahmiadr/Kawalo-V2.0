import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_footer.dart';
import 'package:kawalo_mobile/core/widgets/app_top_bar.dart';

/// Redesign 2026 building blocks shared by the face, attendance and
/// attendance-admin screens (`.es`, `.done`, `.box`, `.it` in
/// `Task/redesign/board/rd.css`); the top bar and footer are `AppTopBar` and
/// `AppTaskFooter` in core. Kept here until a second feature needs them;
/// then they belong in `core/widgets`.

/// Red, soft fill: the `.btn.dan` look for "Hapus ..." actions.
KawaloTone dangerTone(KawaloTones tones) => KawaloTone(
  color: tones.sos.soft,
  on: tones.sos.color,
  soft: tones.sos.soft,
);

/// Task screen: top bar with back/close, scrolling [body] and the action dock
/// ([footer], primary first). Covers the bottom bar.
class TaskScaffold extends StatelessWidget {
  const TaskScaffold({
    required this.title,
    required this.body,
    super.key,
    this.subtitle,
    this.footer = const [],
    this.footerAsRow = false,
    this.onClose,
    this.closeIcon = false,
    this.scrollable = true,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> footer;

  /// Two equal buttons side by side (Tolak | Setujui).
  final bool footerAsRow;

  /// Defaults to popping the route.
  final VoidCallback? onClose;
  final bool closeIcon;

  /// False when [body] fills the space itself (empty states, lists).
  final bool scrollable;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppTopBar(
        title: title,
        subtitle: subtitle,
        leading: closeIcon ? AppTopBarLeading.close : AppTopBarLeading.back,
        onLeadingPressed: onClose,
        actions: actions,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: body,
                    )
                  : body,
            ),
            if (footer.isNotEmpty)
              AppTaskFooter(asRow: footerAsRow, children: footer),
          ],
        ),
      ),
    );
  }
}

/// Look of the badge in [TaskMessage].
enum TaskMessageKind { tone, bad, neutral }

/// `.es` (rounded-square icon, inside a task screen) or `.done` (round badge,
/// a result page) when [round]: icon, title, text, extra [children].
class TaskMessage extends StatelessWidget {
  const TaskMessage({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.tone,
    this.kind = TaskMessageKind.tone,
    this.round = false,
    this.children = const [],
    this.below = const [],
  });

  final Widget icon;
  final String title;
  final String message;

  /// Badge colour for [TaskMessageKind.tone]; Absensi by default.
  final KawaloTone? tone;
  final TaskMessageKind kind;
  final bool round;

  /// Shown between the title and [message] (big time, status pill).
  final List<Widget> children;

  /// Shown under [message] (tips, details).
  final List<Widget> below;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final t = tone ?? tones.abs;
    final (bg, fg) = switch (kind) {
      TaskMessageKind.tone => (t.soft, t.color),
      TaskMessageKind.bad => (tones.sos.soft, tones.sos.color),
      TaskMessageKind.neutral => (tones.surface2, tones.ink2),
    };
    final size = round ? 104.0 : 84.0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(round ? size / 2 : 26),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(color: fg, size: round ? 52 : 40),
                child: icon,
              ),
            ),
            SizedBox(height: round ? 16 : 14),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tones.ink,
                  fontSize: round ? 24 : 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            for (final child in children) ...[
              const SizedBox(height: 12),
              child,
            ],
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: tones.ink2, fontSize: 15, height: 1.4),
              ),
            ),
            for (final child in below) ...[const SizedBox(height: 14), child],
          ],
        ),
      ),
    );
  }
}

/// Clock time of a result page (`.done .big`), e.g. "06.52".
class TaskBigTime extends StatelessWidget {
  const TaskBigTime(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Text(
      text,
      style: TextStyle(
        color: tones.ink,
        fontSize: 56,
        fontWeight: FontWeight.w500,
        letterSpacing: -1,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// `.box`: bordered surface panel.
class TaskBox extends StatelessWidget {
  const TaskBox({required this.children, super.key, this.soft = false});

  final List<Widget> children;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: soft ? tones.surface2 : tones.surface,
        borderRadius: BorderRadius.circular(18),
        border: soft ? null : Border.all(color: tones.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            child,
          ],
        ],
      ),
    );
  }
}

/// `.kv`: label left, bold value right.
class TaskKeyValue extends StatelessWidget {
  const TaskKeyValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: tones.ink2, fontSize: 14)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: tones.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// `.it`: list row with a leading widget, title, subtitle and trailing.
class TaskListItem extends StatelessWidget {
  const TaskListItem({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final subtitle = this.subtitle;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: tones.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tones.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tones.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: tones.ink2, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.ti`: 40 px icon tile in a soft tone.
class TaskIconTile extends StatelessWidget {
  const TaskIconTile(this.icon, {required this.tone, super.key});

  final IconData icon;
  final KawaloTone tone;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: tone.soft,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, size: 20, color: tone.color),
  );
}

/// `.chip` row: single choice, the selected chip tinted with [tone].
class TaskChoiceChips<T> extends StatelessWidget {
  const TaskChoiceChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.tone,
    super.key,
    this.enabled = true,
  });

  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final KawaloTone tone;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (value, label) in options)
          Semantics(
            selected: value == selected,
            button: true,
            child: Material(
              color: value == selected ? tone.soft : Colors.transparent,
              shape: StadiumBorder(
                side: value == selected
                    ? BorderSide.none
                    : BorderSide(color: tones.line, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? () => onSelected(value) : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: value == selected ? tone.color : tones.ink2,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Convenience for the common primary/secondary pair of a footer.
AppTaskButton taskPrimary(
  String label,
  VoidCallback? onPressed, {
  required KawaloTone tone,
  IconData? icon,
  bool isLoading = false,
}) => AppTaskButton(
  label: label,
  icon: icon,
  tone: tone,
  onPressed: onPressed,
  isLoading: isLoading,
);

AppTaskButton taskSecondary(String label, VoidCallback? onPressed) =>
    AppTaskButton(
      label: label,
      onPressed: onPressed,
      variant: AppTaskButtonVariant.secondary,
      size: AppTaskButtonSize.medium,
    );

/// `.dlg` confirmation: [title], [message], then Batal and [confirmLabel]
/// side by side. Resolves to true only on confirm.
Future<bool> showTaskConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required KawaloTone tone,
  String cancelLabel = 'Batal',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final tones = KawaloTones.of(context);
      return Dialog(
        backgroundColor: tones.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    color: tones.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: tones.ink2, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: taskSecondary(
                      cancelLabel,
                      () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppTaskButton(
                      label: confirmLabel,
                      tone: tone,
                      size: AppTaskButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

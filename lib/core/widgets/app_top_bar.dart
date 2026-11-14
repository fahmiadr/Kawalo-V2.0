import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';

enum AppTopBarLeading { back, close, none }

/// Redesign 2026 top bar (`.tb` in `Task/redesign/board/rd.css`): back or
/// close button, a 20/800 title with an optional 12/600 subtitle, and icon
/// actions on the right, drawn on the page background.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.leading = AppTopBarLeading.back,
    this.onLeadingPressed,
    this.leadingEnabled = true,
    this.actions = const [],
  }) : assert(
         title != null || titleWidget != null,
         'AppTopBar needs a title or a titleWidget',
       );

  final String? title;
  final String? subtitle;

  /// Replaces [title] and [subtitle], e.g. a search field or a title that
  /// rebuilds from a bloc (use [AppTopBarTitle] inside it).
  final Widget? titleWidget;

  final AppTopBarLeading leading;

  /// Defaults to [Navigator.maybePop], so a `PopScope` still applies.
  final VoidCallback? onLeadingPressed;

  /// False disables the back/close button, e.g. while a save is running.
  final bool leadingEnabled;

  final List<Widget> actions;

  static const double height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final onPressed = leadingEnabled
        ? onLeadingPressed ?? () => Navigator.of(context).maybePop()
        : null;
    final leadingButton = switch (leading) {
      AppTopBarLeading.back => AppIconButton(
        semanticLabel: 'Kembali',
        tooltip: 'Kembali',
        onPressed: onPressed,
        icon: Icon(Icons.arrow_back_rounded, color: tones.ink),
      ),
      AppTopBarLeading.close => AppIconButton(
        semanticLabel: 'Tutup',
        tooltip: 'Tutup',
        onPressed: onPressed,
        icon: Icon(Icons.close_rounded, color: tones.ink),
      ),
      AppTopBarLeading.none => null,
    };
    // Plain widgets instead of AppBar: AppBar needs MaterialLocalizations,
    // which the bare M3EMaterialApp in widget tests does not provide.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Material(
        color: tones.background,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.only(
                left: leadingButton == null ? 16 : 4,
                right: 8,
              ),
              child: Row(
                children: [
                  if (leadingButton != null) ...[
                    leadingButton,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child:
                        titleWidget ??
                        Semantics(
                          header: true,
                          child: AppTopBarTitle(
                            title: title!,
                            subtitle: subtitle,
                          ),
                        ),
                  ),
                  if (actions.isNotEmpty) const SizedBox(width: 8),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title block of [AppTopBar]; public for titles built inside a builder.
class AppTopBarTitle extends StatelessWidget {
  const AppTopBarTitle({required this.title, super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tones.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tones.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

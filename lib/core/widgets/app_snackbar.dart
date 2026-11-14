import 'package:flutter/widgets.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_icon_button.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

// ---------------------------------------------------------------------------
// Material 3 Expressive Snackbars with Built-in Deduplication & Close Button
// ---------------------------------------------------------------------------

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3ESnackbar, M3ESnackbarHost, M3ESnackbarTheme;

/// Enhanced Material 3 Expressive Snackbar wrapper with built-in
/// message deduplication, debouncing, and single active overlay management.
class AppSnackbar extends StatelessWidget {
  /// Creates an [AppSnackbar] widget directly.
  const AppSnackbar({
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showCloseIcon,
    this.onClose,
    super.key,
  });

  /// The message text to display.
  final String message;

  /// An optional action label (e.g. "Undo").
  final String? actionLabel;

  /// An optional callback when the action label is tapped.
  final VoidCallback? onAction;

  /// Whether to display a close icon button.
  ///
  /// When null, defaults to true if [actionLabel] is null, and false otherwise.
  final bool? showCloseIcon;

  /// An optional callback when the close icon is tapped.
  final VoidCallback? onClose;

  /// Holds the currently active [OverlayEntry].
  static OverlayEntry? _currentEntry;

  /// The last message text shown to prevent duplicate spam.
  static String? _lastMessage;

  /// The timestamp of the last displayed message.
  static DateTime? _lastShownTime;

  /// Minimum duration between identical messages before showing again.
  /// The one text for any action whose feature is not built yet (user
  /// decision: such actions look normal and say this when used).
  static const String inProgressMessage = 'Fitur dalam pengerjaan';

  static void showInProgress(BuildContext context) =>
      show(context, message: inProgressMessage);

  static const Duration duplicateDebounceDuration = Duration(
    milliseconds: 1500,
  );

  /// Dismisses the currently displayed snackbar overlay, if any.
  static void hideCurrent() {
    if (_currentEntry != null && _currentEntry!.mounted) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
    _lastMessage = null;
    _lastShownTime = null;
  }

  /// Presents a deduplicated Material 3 Expressive snackbar over the overlay.
  ///
  /// If the same [message] is called within [duplicateDebounceDuration],
  /// the call is ignored to prevent UI spam. If another snackbar is
  /// already visible, it is dismissed immediately to prevent visual stacking.
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool? showCloseIcon,
    VoidCallback? onClose,
    Duration? duration,
    bool force = false,
  }) {
    final now = DateTime.now();

    // Prevent duplicate message spam within the debounce window
    if (!force &&
        _lastMessage == message &&
        _lastShownTime != null &&
        now.difference(_lastShownTime!) < duplicateDebounceDuration) {
      return;
    }

    // Dismiss existing active snackbar before showing a new one
    hideCurrent();

    _lastMessage = message;
    _lastShownTime = now;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final theme = AppTheme.of(context);
    final resolvedDuration = duration ?? theme.snackBarTheme.defaultDuration;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return M3EComponentTheme(
          builder: (context) => M3ESnackbarHost(
            duration: resolvedDuration,
            entry: entry,
            child: AppSnackbar(
              message: message,
              actionLabel: actionLabel,
              onAction: onAction,
              showCloseIcon: showCloseIcon,
              onClose: () {
                onClose?.call();
                hideCurrent();
              },
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return M3EComponentTheme(
      builder: (context) {
        final theme = M3ETheme.of(context);
        final scheme = theme.colorScheme;
        final snackTheme = theme.snackBarTheme;

        final shouldShowClose = showCloseIcon ?? (actionLabel == null);

        return Container(
          constraints: BoxConstraints(
            minHeight: snackTheme.singleLineMinHeight,
            maxWidth: snackTheme.maxWidth,
          ),
          padding: EdgeInsets.only(
            left: snackTheme.startPadding,
            top: snackTheme.verticalPadding,
            bottom: snackTheme.verticalPadding,
            right: shouldShowClose
                ? snackTheme.endPaddingWithTrailing
                : snackTheme.endPadding,
          ),
          decoration: BoxDecoration(
            color: snackTheme.containerColor(scheme),
            borderRadius: snackTheme.borderRadius,
            boxShadow: M3EElevation.shadows(
              snackTheme.elevation,
              shadowColor: scheme.shadow,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: Text(
                  message,
                  style: snackTheme.messageStyle(theme.typeScale, scheme),
                ),
              ),
              if (actionLabel != null)
                Padding(
                  padding: EdgeInsets.only(left: snackTheme.actionGap),
                  child: M3ETappable(
                    onTap: onAction,
                    semanticLabel: actionLabel,
                    builder: (context, state) {
                      return Padding(
                        padding: snackTheme.actionPadding,
                        child: Text(
                          actionLabel!,
                          style: snackTheme.actionStyle(
                            theme.typeScale,
                            scheme,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (shouldShowClose)
                Padding(
                  padding: EdgeInsets.only(left: snackTheme.actionGap),
                  child: Semantics(
                    label: 'Tutup notifikasi',
                    button: true,
                    child: AppIconButton(
                      icon: AppSvgIcon(
                        KawaloVectors.cancel01,
                        size: 18,
                        color: scheme.onInverseSurface,
                      ),
                      visualSize: const Size(36, 36),
                      tooltip: 'Tutup notifikasi',
                      onPressed: onClose ?? hideCurrent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

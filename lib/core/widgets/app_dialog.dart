import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

export 'package:material_3_expressive/material_3_expressive.dart'
    show M3EDialog, M3EDialogTheme;

export 'app_confirmation_dialog.dart';

/// Alias for [M3EDialogTheme] to maintain standard project naming.
typedef AppDialogTheme = M3EDialogTheme;

/// Implementasi Material 3 Expressive Dialog untuk Kawalo Mobile.
///
/// Menyediakan dialog standar dan fullscreen dialog yang terintegrasi
/// dengan sistem navigasi Flutter, memastikan intervensi `PopScope`
/// dan dialog konfirmasi perubahan dihormati saat penutupan dialog.
class AppDialog extends M3EDialog {
  /// Membuat instance [AppDialog].
  const AppDialog({
    required super.title,
    super.icon,
    super.content,
    super.contentPadding,
    super.actions = const <Widget>[],
    super.topDivider = false,
    super.bottomDivider = false,
    super.key,
  });

  /// Menampilkan dialog standar Material 3 Expressive.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget dialog,
    bool barrierDismissible = true,
    bool? resizeToAvoidBottomInset,
  }) {
    return M3EDialog.show<T>(
      context,
      dialog: dialog,
      barrierDismissible: barrierDismissible,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  /// Menampilkan fullscreen dialog Material 3 Expressive.
  ///
  /// Menggunakan [onClose] jika disediakan untuk penanganan khusus
  /// saat tombol tutup (X) ditekan, atau default ke [Navigator.maybePop]
  /// agar menghormati penjagaan [PopScope] ketika formulir memiliki perubahan
  /// yang belum disimpan.
  static Future<T?> showFullScreen<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    Widget? action,
    VoidCallback? onClose,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        fullscreenDialog: true,
        transitionDuration: M3EMotion.long2,
        reverseTransitionDuration: M3EMotion.medium1,
        pageBuilder: (context, animation, secondaryAnimation) {
          return M3EComponentTheme(
            builder: (context) => _AppFullScreenDialog(
              title: title,
              body: body,
              action: action,
              onClose: onClose,
            ),
          );
        },
        transitionsBuilder: (context, animation, secondary, child) {
          if (AppMotion.isReducedMotion(context)) {
            return FadeTransition(opacity: animation, child: child);
          }
          final isClosing = animation.status == AnimationStatus.reverse;
          final curve = isClosing
              ? M3EMotion.emphasizedAccelerate
              : M3EMotion.emphasizedDecelerate;

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: curve,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class _AppFullScreenDialog extends StatelessWidget {
  const _AppFullScreenDialog({
    required this.title,
    required this.body,
    this.action,
    this.onClose,
  });

  final String title;
  final Widget body;
  final Widget? action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return M3EComponentTheme(builder: _buildFullScreen);
  }

  Widget _buildFullScreen(BuildContext context) {
    final theme = M3ETheme.of(context);
    final dialogTheme = theme.dialogTheme;
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: dialogTheme.fullScreenBackground(scheme),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(context, theme, dialogTheme),
            M3EDivider(color: scheme.outlineVariant),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    M3EThemeData theme,
    M3EDialogTheme dialogTheme,
  ) {
    final scheme = theme.colorScheme;
    return SizedBox(
      height: dialogTheme.fullScreenHeaderHeight,
      child: Row(
        children: <Widget>[
          SizedBox(width: dialogTheme.headerEdgeGap),
          M3ETappable(
            onTap: onClose ?? () => Navigator.of(context).maybePop(),
            semanticLabel: 'Tutup',
            builder: (BuildContext context, M3EInteractionState state) {
              return Padding(
                padding: dialogTheme.closeButtonPadding,
                child: IconTheme.merge(
                  data: IconThemeData(size: dialogTheme.iconSize),
                  child: const Icon(M3EIcons.close),
                ),
              );
            },
          ),
          SizedBox(width: dialogTheme.headerEdgeGap),
          Expanded(
            child: Text(
              title,
              style: theme.typeScale.titleLarge.copyWith(
                color: scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action != null) ...<Widget>[
            action!,
            SizedBox(width: dialogTheme.headerActionGap),
          ],
        ],
      ),
    );
  }
}

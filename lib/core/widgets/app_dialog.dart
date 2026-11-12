import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
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
  /// Aksi utama (Simpan, Kirim, Hapus) lewat [bottomActions], ditumpuk vertikal
  /// di bagian bawah; header tidak punya slot aksi.
  ///
  /// Menggunakan [onClose] jika disediakan untuk penanganan khusus
  /// saat tombol tutup (X) ditekan, atau default ke [Navigator.maybePop]
  /// agar menghormati penjagaan [PopScope] ketika formulir memiliki perubahan
  /// yang belum disimpan.
  static Future<T?> showFullScreen<T>(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget> bottomActions = const <Widget>[],
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
              bottomActions: bottomActions,
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
            ).animate(CurvedAnimation(parent: animation, curve: curve)),
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
    this.bottomActions = const <Widget>[],
    this.onClose,
  });

  final String title;
  final Widget body;
  final List<Widget> bottomActions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return M3EComponentTheme(builder: _buildFullScreen);
  }

  Widget _buildFullScreen(BuildContext context) {
    final theme = M3ETheme.of(context);
    final dialogTheme = theme.dialogTheme;
    final scheme = theme.colorScheme;
    // Material (not ColoredBox): bodies use InkWell/InkResponse, which need a
    // Material ancestor, and this route has no Scaffold.
    return Material(
      color: dialogTheme.fullScreenBackground(scheme),
      child: SafeArea(
        // The keyboard covers the bottom actions instead of lifting them: they
        // stay put at the bottom edge while only the body shrinks.
        child: CustomMultiChildLayout(
          delegate: _FullScreenLayout(MediaQuery.viewInsetsOf(context).bottom),
          children: <Widget>[
            LayoutId(
              id: _Slot.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildHeader(context, theme, dialogTheme),
                  M3EDivider(color: scheme.outlineVariant),
                ],
              ),
            ),
            LayoutId(id: _Slot.body, child: body),
            if (bottomActions.isNotEmpty)
              LayoutId(
                id: _Slot.footer,
                child: AppPageActions(children: bottomActions),
              ),
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
        ],
      ),
    );
  }
}

enum _Slot { top, body, footer }

class _FullScreenLayout extends MultiChildLayoutDelegate {
  _FullScreenLayout(this.keyboardHeight);

  final double keyboardHeight;

  @override
  void performLayout(Size size) {
    final width = BoxConstraints(
      minWidth: size.width,
      maxWidth: size.width,
      maxHeight: size.height,
    );
    final top = layoutChild(_Slot.top, width);
    final footer = hasChild(_Slot.footer)
        ? layoutChild(_Slot.footer, width)
        : Size.zero;
    final reserved = footer.height > keyboardHeight
        ? footer.height
        : keyboardHeight;
    final bodyHeight = size.height - top.height - reserved;
    layoutChild(
      _Slot.body,
      BoxConstraints.tightFor(
        width: size.width,
        height: bodyHeight < 0 ? 0 : bodyHeight,
      ),
    );
    positionChild(_Slot.top, Offset.zero);
    positionChild(_Slot.body, Offset(0, top.height));
    if (hasChild(_Slot.footer)) {
      positionChild(_Slot.footer, Offset(0, size.height - footer.height));
    }
  }

  @override
  bool shouldRelayout(_FullScreenLayout old) =>
      old.keyboardHeight != keyboardHeight;
}

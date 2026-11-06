import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_elevation.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';

/// Menampilkan Material 3 Expressive Confirmation Dialog sesuai layout desain
/// Figma.
///
/// Karakteristik tata letak:
/// - Lebar kontainer dialog tetap 280dp (standar M3 compact dialog).
/// - Permukaan dialog berpenampilan melengkung 28dp ([AppShape.extraLarge])
///   dengan warna latar `surfaceContainerHigh` dan elevasi bayangan Level 3.
/// - Judul teks berpusat (*centered*) `titleMedium`.
/// - Pesan/deskripsi berpusat (*centered*) `bodyMedium`.
/// - Dua tombol berdampingan ([Row] dengan [Expanded]):
///   - Tombol Batal/Cancel menggunakan [AppButton] bertipe
///     [AppButtonColor.filled] secara standar tanpa modifikasi decoration.
///   - Tombol Konfirmasi/Hapus menggunakan [AppButton] bertipe
///     [AppButtonColor.text] dengan teks berwarna [ColorScheme.error] saat
///     destruktif.
///
/// Mengembalikan `Future<bool?>` yang bernilai:
/// - `true` jika tombol konfirmasi ditekan.
/// - `false` jika tombol batal ditekan.
/// - `null` jika dialog ditutup tanpa memilih (misal mengetuk scrim di luar).
Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Batal',
  String confirmText = 'Hapus',
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  bool isDestructive = true,
  AppButtonColor cancelStyle = AppButtonColor.filled,
  AppButtonColor confirmStyle = AppButtonColor.text,
  Color? cancelButtonColor,
  Color? cancelTextColor,
  Color? confirmTextColor,
  double width = 280,
  Widget? icon,
  bool barrierDismissible = false,
}) {
  return AppDialog.show<bool>(
    context,
    barrierDismissible: barrierDismissible,
    dialog: AppConfirmationDialog(
      title: title,
      message: message,
      cancelText: cancelText,
      confirmText: confirmText,
      onCancel: onCancel,
      onConfirm: onConfirm,
      isDestructive: isDestructive,
      cancelStyle: cancelStyle,
      confirmStyle: confirmStyle,
      cancelButtonColor: cancelButtonColor,
      cancelTextColor: cancelTextColor,
      confirmTextColor: confirmTextColor,
      width: width,
      icon: icon,
    ),
  );
}

/// Widget Material 3 Expressive Confirmation Dialog.
///
/// Mengikuti spesifikasi tata letak dialog konfirmasi dari Material 3
/// Expressive dengan integrasi penuh token tema Kawalo (warna, bentuk,
/// tipografi, dan spasi).
class AppConfirmationDialog extends AppDialog {
  /// Membuat instance [AppConfirmationDialog].
  const AppConfirmationDialog({
    required super.title,
    required this.message,
    this.cancelText = 'Batal',
    this.confirmText = 'Hapus',
    this.onCancel,
    this.onConfirm,
    this.isDestructive = true,
    this.cancelStyle = AppButtonColor.filled,
    this.confirmStyle = AppButtonColor.text,
    this.cancelButtonColor,
    this.cancelTextColor,
    this.confirmTextColor,
    this.width = 280,
    super.icon,
    super.key,
  });

  /// Pesan atau deskripsi penjelasan tindakan.
  final String message;

  /// Label teks untuk tombol batal/cancel. Default bernilai `'Batal'`.
  final String cancelText;

  /// Label teks untuk tombol konfirmasi/hapus. Default bernilai `'Hapus'`.
  final String confirmText;

  /// Callback opsional saat tombol batal ditekan.
  final VoidCallback? onCancel;

  /// Callback opsional saat tombol konfirmasi ditekan.
  final VoidCallback? onConfirm;

  /// Menentukan apakah tindakan bersifat destruktif.
  final bool isDestructive;

  /// Gaya tampilan tombol batal (default: [AppButtonColor.filled]).
  final AppButtonColor cancelStyle;

  /// Gaya tampilan tombol konfirmasi (default: [AppButtonColor.text]).
  final AppButtonColor confirmStyle;

  /// Override warna latar belakang tombol batal opsional.
  final Color? cancelButtonColor;

  /// Override warna teks tombol batal opsional.
  final Color? cancelTextColor;

  /// Override warna teks tombol konfirmasi opsional.
  final Color? confirmTextColor;

  /// Lebar kontainer dialog (default: 280dp sesuai spesifikasi M3).
  final double width;

  /// Helper statis untuk menampilkan dialog melalui
  /// [showAppConfirmationDialog].
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = 'Batal',
    String confirmText = 'Hapus',
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    bool isDestructive = true,
    AppButtonColor cancelStyle = AppButtonColor.filled,
    AppButtonColor confirmStyle = AppButtonColor.text,
    Color? cancelButtonColor,
    Color? cancelTextColor,
    Color? confirmTextColor,
    double width = 280,
    Widget? icon,
    bool barrierDismissible = false,
  }) {
    return showAppConfirmationDialog(
      context: context,
      title: title,
      message: message,
      cancelText: cancelText,
      confirmText: confirmText,
      onCancel: onCancel,
      onConfirm: onConfirm,
      isDestructive: isDestructive,
      cancelStyle: cancelStyle,
      confirmStyle: confirmStyle,
      cancelButtonColor: cancelButtonColor,
      cancelTextColor: cancelTextColor,
      confirmTextColor: confirmTextColor,
      width: width,
      icon: icon,
      barrierDismissible: barrierDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final dialogTheme = theme.dialogTheme;
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedTypeScale = theme.typography.emphasized;

    final effectiveConfirmColor = confirmTextColor ??
        (isDestructive ? colorScheme.error : null);

    final confirmDecoration = effectiveConfirmColor != null
        ? AppButtonDecoration(
            foregroundColor: WidgetStatePropertyAll<Color?>(
              effectiveConfirmColor,
            ),
          )
        : null;

    final cancelDecoration =
        (cancelTextColor != null || cancelButtonColor != null)
            ? AppButtonDecoration(
                backgroundColor: cancelButtonColor != null
                    ? WidgetStatePropertyAll<Color?>(cancelButtonColor)
                    : null,
                foregroundColor: cancelTextColor != null
                    ? WidgetStatePropertyAll<Color?>(cancelTextColor)
                    : null,
              )
            : null;

    return Container(
      constraints: BoxConstraints(
        minWidth: dialogTheme.minWidth,
        maxWidth: dialogTheme.maxWidth,
      ),
      decoration: BoxDecoration(
        color: dialogTheme.containerColor(colorScheme),
        borderRadius: dialogTheme.borderRadius,
        boxShadow: AppElevation.shadows(
          AppElevation.level3,
          shadowColor: colorScheme.shadow,
        ),
      ),
      padding: dialogTheme.padding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              AppSpacing.vGapSm,
            ],

            // ── 1. Judul Dialog ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: emphasizedTypeScale.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            AppSpacing.vGapSm,

            // ── 2. Pesan Penjelasan ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: typeScale.bodyLarge.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AppSpacing.vGap200,

            // ── 3. Tombol Aksi Berdampingan ──────────────────────────────
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppStateLayer.minTouchTarget,
                        maxWidth: 360,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          style: cancelStyle,
                          decoration: cancelDecoration,
                          shape: AppButtonShape.square,
                          semanticLabel: cancelText,
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            final route = ModalRoute.of(context);
                            onCancel?.call();
                            if (route != null &&
                                route.isCurrent &&
                                navigator.canPop()) {
                              navigator.pop(false);
                            }
                          },
                          child: Text(
                            cancelText,
                            style: typeScale.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.hGapSm,

                  // Tombol Konfirmasi / Hapus
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppStateLayer.minTouchTarget,
                        maxWidth: 360,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          style: confirmStyle,
                          decoration: confirmDecoration,
                          shape: AppButtonShape.square,
                          semanticLabel: confirmText,
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            final route = ModalRoute.of(context);
                            onConfirm?.call();
                            if (route != null &&
                                route.isCurrent &&
                                navigator.canPop()) {
                              navigator.pop(true);
                            }
                          },
                          child: Text(
                            confirmText,
                            style: typeScale.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

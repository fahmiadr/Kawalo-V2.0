import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/widgets/actionable_error/actionable_error_data.dart';
import 'package:kawalo_mobile/core/widgets/actionable_error/actionable_error_views.dart';

// -----------------------------------------------------------------------------
// GoF Strategy & Facade Pattern
// -----------------------------------------------------------------------------

/// Strategi modalitas penyajian galat pada antarmuka pengguna.
enum AppActionableErrorModality {
  /// Modalitas lembar bawah (Modal Bottom Sheet).
  bottomSheet,

  /// Modalitas dialog mengambang (Modal Dialog).
  dialog,

  /// Modalitas layar penuh mandiri (Fullscreen / Blocking Screen).
  fullScreen,
}

/// Facade terpadu untuk menyajikan galat terstandarisasi di aplikasi Kawalo.
///
/// Menyediakan API terpadu untuk merender galat tersemat di tata letak layar
/// melalui [view], atau menampilkannya secara dinamis melalui [show]
/// berdasarkan strategi modalitas [AppActionableErrorModality].
///
/// ```dart
/// // Menampilkan galat via modalitas Bottom Sheet
/// await AppActionableError.show(
///   context,
///   data: errorData,
///   modality: AppActionableErrorModality.bottomSheet,
/// );
///
/// // Merender galat tersemat di dalam tata letak widget
/// AppActionableError.view(data: errorData);
/// ```
abstract final class AppActionableError {
  const AppActionableError._();

  /// Menghasilkan widget galat tersemat (*In-Place / Embedded View*).
  ///
  /// Cocok untuk disematkan di dalam kontainer layar seperti *viewfinder*
  /// kamera atau *empty state*.
  static Widget view({
    required AppActionableErrorData data,
    Key? key,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.space300),
    ScrollPhysics physics = const AlwaysScrollableScrollPhysics(),
    Color? backgroundColor,
    bool wrapTheme = true,
  }) {
    return AppActionableErrorView(
      key: key,
      data: data,
      padding: padding,
      physics: physics,
      backgroundColor: backgroundColor,
      wrapTheme: wrapTheme,
    );
  }

  /// Menampilkan galat secara dinamis berdasarkan strategi [modality].
  ///
  /// Meneruskan parameter ke metode modalitas terkait seperti
  /// [showBottomSheet], [showDialog], atau [showFullScreen].
  static Future<T?> show<T>(
    BuildContext context, {
    required AppActionableErrorData data,
    AppActionableErrorModality modality =
        AppActionableErrorModality.bottomSheet,
    bool barrierDismissible = true,
    bool isBlocking = false,
    double maxHeightFactor = 0.85,
  }) {
    switch (modality) {
      case AppActionableErrorModality.bottomSheet:
        return showBottomSheet<T>(
          context,
          data: data,
          enableDrag: barrierDismissible,
          maxHeightFactor: maxHeightFactor,
        );
      case AppActionableErrorModality.dialog:
        return showDialog<T>(
          context,
          data: data,
          barrierDismissible: barrierDismissible,
        );
      case AppActionableErrorModality.fullScreen:
        return showFullScreen<T>(context, data: data, isBlocking: isBlocking);
    }
  }

  /// Menampilkan galat dalam modalitas Modal Bottom Sheet.
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required AppActionableErrorData data,
    bool enableDrag = true,
    double maxHeightFactor = 0.85,
  }) {
    return AppActionableErrorBottomSheet.show<T>(
      context,
      data: data,
      enableDrag: enableDrag,
      maxHeightFactor: maxHeightFactor,
    );
  }

  /// Menampilkan galat dalam modalitas Modal Dialog.
  static Future<T?> showDialog<T>(
    BuildContext context, {
    required AppActionableErrorData data,
    bool barrierDismissible = true,
  }) {
    return AppActionableErrorDialog.show<T>(
      context,
      data: data,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Menampilkan galat dalam modalitas Layar Penuh (*Fullscreen*).
  static Future<T?> showFullScreen<T>(
    BuildContext context, {
    required AppActionableErrorData data,
    bool isBlocking = false,
  }) {
    return AppActionableErrorFullScreen.show<T>(
      context,
      data: data,
      isBlocking: isBlocking,
    );
  }
}

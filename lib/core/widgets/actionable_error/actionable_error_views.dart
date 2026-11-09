import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_elevation.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/actionable_error/actionable_error_data.dart';
import 'package:kawalo_mobile/core/widgets/actionable_error/actionable_error_slots.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';

/// Helper internal untuk menyelesaikan pasangan [ThemeData] dan [M3EThemeData]
/// berdasarkan [themeMode].
(ThemeData, M3EThemeData)? _resolveActionableErrorTheme(
  AppActionableErrorThemeMode themeMode,
) {
  switch (themeMode) {
    case AppActionableErrorThemeMode.light:
      return (AppTheme.lightThemeData(), AppTheme.m3eLight());
    case AppActionableErrorThemeMode.dark:
      return (AppTheme.darkThemeData(), AppTheme.m3eDark());
    case AppActionableErrorThemeMode.system:
      return null;
  }
}

/// Helper internal untuk membungkus [child] dengan [Theme] dan [M3ETheme]
/// sesuai [themeMode].
Widget _wrapActionableErrorTheme({
  required AppActionableErrorThemeMode themeMode,
  required Widget child,
}) {
  final themePair = _resolveActionableErrorTheme(themeMode);
  if (themePair == null) {
    return child;
  }

  return Theme(
    data: themePair.$1,
    child: M3ETheme(
      data: themePair.$2,
      child: child,
    ),
  );
}

// -----------------------------------------------------------------------------
// GoF Template Method: Reusable Compact Scrollable Body
// -----------------------------------------------------------------------------

/// Template pembungkus konten kompak yang dapat digulirkan untuk
/// Modal Bottom Sheet dan Modal Dialog (GoF Template Method / DRY).
class _CompactErrorScrollableBody extends StatelessWidget {
  const _CompactErrorScrollableBody({
    required this.data,
    this.padding = const EdgeInsets.all(AppSpacing.space300),
  });

  final AppActionableErrorData data;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: padding,
        child: ActionableErrorSlotContent(
          data: data,
          isCompact: true,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Modalitas 1: In-Place / Embedded View
// -----------------------------------------------------------------------------

/// Tata letak galat terstandarisasi untuk modalitas In-Place / Embedded View.
///
/// Mengisi kontainer induk (seperti area *viewfinder* kamera atau *empty state*
/// halaman) tanpa menutup navigasi atau kontrol di sekitarnya.
class AppActionableErrorView extends StatelessWidget {
  /// Membuat instance [AppActionableErrorView].
  const AppActionableErrorView({
    required this.data,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.space300),
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.backgroundColor,
    this.wrapTheme = true,
  });

  /// Data galat terstandarisasi yang akan dirender ke dalam slot tata letak.
  final AppActionableErrorData data;

  /// Jarak ruang di sekeliling konten galat.
  final EdgeInsetsGeometry padding;

  /// Fisika pengguliran untuk kontainer yang dapat digulirkan.
  final ScrollPhysics physics;

  /// Warna latar belakang opsional.
  ///
  /// Jika bernilai `null`, kontainer bersifat transparan dan mewarisi warna
  /// kontainer induknya.
  final Color? backgroundColor;

  /// Apakah tampilan membungkus konten dengan tema override dari [data].
  ///
  /// Bernilai `false` jika kontainer induk telah melakukan pembungkusan tema
  /// untuk mencegah penumpukan tema ganda.
  final bool wrapTheme;

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: padding,
                child: ActionableErrorSlotContent(data: data),
              ),
            ),
          ),
        );
      },
    );

    if (backgroundColor != null) {
      content = ColoredBox(
        color: backgroundColor!,
        child: content,
      );
    }

    if (!wrapTheme) {
      return content;
    }

    return _wrapActionableErrorTheme(
      themeMode: data.themeMode,
      child: content,
    );
  }
}

// -----------------------------------------------------------------------------
// Modalitas 2: Modal Bottom Sheet
// -----------------------------------------------------------------------------

/// Tata letak galat terstandarisasi untuk modalitas Modal Bottom Sheet.
///
/// Disajikan saat terjadi gangguan operasional sementara (*transient error*)
/// di tengah alur kerja aktif (misal: saat kamera aktif dan foto gagal
/// disimpan) tanpa meninggalkan konteks halaman saat ini.
class AppActionableErrorBottomSheet extends StatelessWidget {
  /// Membuat instance [AppActionableErrorBottomSheet].
  const AppActionableErrorBottomSheet({
    required this.data,
    super.key,
  });

  /// Data galat terstandarisasi.
  final AppActionableErrorData data;

  /// Menampilkan lembar galat terstandarisasi dari batas bawah layar.
  static Future<T?> show<T>(
    BuildContext context, {
    required AppActionableErrorData data,
    bool enableDrag = true,
    double maxHeightFactor = 0.85,
  }) {
    final themePair = _resolveActionableErrorTheme(data.themeMode);

    return showAppBottomSheet<T>(
      context: context,
      enableDrag: enableDrag,
      maxHeightFactor: maxHeightFactor,
      m3eTheme: themePair?.$2,
      themeData: themePair?.$1,
      child: AppActionableErrorBottomSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _wrapActionableErrorTheme(
      themeMode: data.themeMode,
      child: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: _CompactErrorScrollableBody(
          data: data,
          padding: const EdgeInsets.only(
            left: AppSpacing.space300,
            right: AppSpacing.space300,
            top: AppSpacing.space100,
            bottom: AppSpacing.space300,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Modalitas 3: Modal Dialog (Compact / Floating)
// -----------------------------------------------------------------------------

/// Tata letak galat terstandarisasi untuk modalitas Modal Dialog.
///
/// Disajikan saat memerlukan konfirmasi pengguna atau dialog peringatan dengan
/// fokus interaksi terarah.
class AppActionableErrorDialog extends StatelessWidget {
  /// Membuat instance [AppActionableErrorDialog].
  const AppActionableErrorDialog({
    required this.data,
    super.key,
  });

  /// Data galat terstandarisasi.
  final AppActionableErrorData data;

  /// Menampilkan dialog galat terstandarisasi mengambang di tengah layar.
  static Future<T?> show<T>(
    BuildContext context, {
    required AppActionableErrorData data,
    bool barrierDismissible = true,
  }) {
    return AppDialog.show<T>(
      context,
      barrierDismissible: barrierDismissible,
      dialog: AppActionableErrorDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _wrapActionableErrorTheme(
      themeMode: data.themeMode,
      child: Builder(
        builder: (themedContext) {
          final theme = AppTheme.of(themedContext);
          final colorScheme = theme.colorScheme;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 340,
              ),
              child: Material(
                color: colorScheme.surfaceContainerHigh,
                shape: AppShape.extraLarge,
                elevation: AppElevation.level3,
                clipBehavior: Clip.antiAlias,
                child: _CompactErrorScrollableBody(data: data),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Modalitas 4: Fullscreen / Blocking Screen
// -----------------------------------------------------------------------------

/// Tata letak galat terstandarisasi untuk modalitas Layar Penuh (*Fullscreen*).
///
/// Mengambil seluruh area layar sebagai rute mandiri dan memblokir navigasi
/// jika [isBlocking] bernilai `true` (misalnya pada pelanggaran keamanan
/// fatal).
class AppActionableErrorFullScreen extends StatelessWidget {
  /// Membuat instance [AppActionableErrorFullScreen].
  const AppActionableErrorFullScreen({
    required this.data,
    super.key,
    this.isBlocking = false,
  });

  /// Data galat terstandarisasi.
  final AppActionableErrorData data;

  /// Apakah layar memblokir navigasi kembali pengguna via [PopScope].
  final bool isBlocking;

  /// Menampilkan rute layar penuh galat terstandarisasi.
  static Future<T?> show<T>(
    BuildContext context, {
    required AppActionableErrorData data,
    bool isBlocking = false,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (routeContext) => AppActionableErrorFullScreen(
          data: data,
          isBlocking: isBlocking,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _wrapActionableErrorTheme(
      themeMode: data.themeMode,
      child: Builder(
        builder: (themedContext) {
          final theme = AppTheme.of(themedContext);
          final colorScheme = theme.colorScheme;

          final content = Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: AppActionableErrorView(
                data: data,
                wrapTheme: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space300,
                  vertical: AppSpacing.space400,
                ),
              ),
            ),
          );

          if (isBlocking) {
            return PopScope(
              canPop: false,
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}

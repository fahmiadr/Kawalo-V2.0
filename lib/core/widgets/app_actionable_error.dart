import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_elevation.dart';
import 'package:kawalo_mobile/core/theme/app_shape.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

/// Mode tema visual untuk komponen galat [AppActionableError].
enum AppActionableErrorThemeMode {
  /// Mengikuti tema aktif aplikasi secara dinamis (Light atau Dark).
  system,

  /// Memaksa tampilan galat menggunakan tema terang (Light Mode).
  light,

  /// Memaksa tampilan galat menggunakan tema gelap (Dark Mode).
  ///
  /// Sangat ideal untuk kontainer kamera (*viewfinder*), pemindai, atau media.
  dark,
}

/// Data model terpadu untuk merepresentasikan informasi galat terstandarisasi.
///
/// Digunakan oleh seluruh modalitas [AppActionableError] untuk menyajikan
/// masalah secara informatif, langkah penanggulangan konkret, atau informasi
/// diagnostik teknis.
///
/// ```dart
/// final errorData = AppActionableErrorData.actionable(
///   title: 'Izin kamera dinonaktifkan',
///   message: 'Aktifkan izin kamera untuk mengambil foto dokumentasi.',
///   troubleshootingTips: const [
///     'Buka pengaturan aplikasi di perangkat Anda.',
///     'Aktifkan perizinan kamera.',
///   ],
///   primaryActionLabel: 'Buka pengaturan',
///   onPrimaryAction: () => openAppSettings(),
/// );
/// ```
@immutable
class AppActionableErrorData extends Equatable {
  /// Membuat instance [AppActionableErrorData].
  const AppActionableErrorData({
    required this.title,
    required this.message,
    this.icon,
    this.customIcon,
    this.troubleshootingTips = const <String>[],
    this.technicalDetails,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.primaryActionStyle = AppButtonColor.filled,
    this.primaryButtonDecoration,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionStyle = AppButtonColor.outlined,
    this.secondaryButtonDecoration,
    this.isUnexpected = false,
    this.themeMode = AppActionableErrorThemeMode.system,
  });

  /// Menghasilkan galat operasional yang dapat ditindaklanjuti pengguna.
  ///
  /// Menggunakan [primaryActionLabel] dan [onPrimaryAction] untuk mengarahkan
  /// pengguna ke tindakan resolusi yang relevan.
  factory AppActionableErrorData.actionable({
    required String title,
    required String message,
    String? icon,
    Widget? customIcon,
    List<String> troubleshootingTips = const <String>[],
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    AppButtonColor primaryActionStyle = AppButtonColor.filled,
    AppButtonDecoration? primaryButtonDecoration,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    AppButtonColor secondaryActionStyle = AppButtonColor.outlined,
    AppButtonDecoration? secondaryButtonDecoration,
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
  }) {
    return AppActionableErrorData(
      title: title,
      message: message,
      icon: icon,
      customIcon: customIcon,
      troubleshootingTips: troubleshootingTips.isEmpty
          ? const <String>[]
          : List<String>.unmodifiable(troubleshootingTips),
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: onPrimaryAction,
      primaryActionStyle: primaryActionStyle,
      primaryButtonDecoration: primaryButtonDecoration,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
      secondaryActionStyle: secondaryActionStyle,
      secondaryButtonDecoration: secondaryButtonDecoration,
      themeMode: themeMode,
    );
  }

  /// Menghasilkan galat sistem atau runtime tak terduga (*unexpected failure*).
  ///
  /// Menyediakan opsi untuk menyertakan [technicalDetails] diagnostik dan aksi
  /// bawaan [primaryActionLabel] bernilai `'Coba lagi'`.
  factory AppActionableErrorData.unexpected({
    required String title,
    required String message,
    String? technicalDetails,
    String? icon,
    Widget? customIcon,
    String primaryActionLabel = 'Coba lagi',
    VoidCallback? onPrimaryAction,
    AppButtonColor primaryActionStyle = AppButtonColor.filled,
    AppButtonDecoration? primaryButtonDecoration,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    AppButtonColor secondaryActionStyle = AppButtonColor.outlined,
    AppButtonDecoration? secondaryButtonDecoration,
    AppActionableErrorThemeMode themeMode = AppActionableErrorThemeMode.system,
  }) {
    return AppActionableErrorData(
      title: title,
      message: message,
      icon: icon,
      customIcon: customIcon,
      technicalDetails: technicalDetails,
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: onPrimaryAction,
      primaryActionStyle: primaryActionStyle,
      primaryButtonDecoration: primaryButtonDecoration,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
      secondaryActionStyle: secondaryActionStyle,
      secondaryButtonDecoration: secondaryButtonDecoration,
      isUnexpected: true,
      themeMode: themeMode,
    );
  }

  /// Path aset ikon SVG utama.
  final String? icon;

  /// Widget ikon kustom eksplisit jika tidak menggunakan [icon].
  final Widget? customIcon;

  /// Judul ringkas masalah dalam format sentence case.
  final String title;

  /// Penjelasan konteks masalah secara manusiawi bagi pengguna.
  final String message;

  /// Daftar instruksi langkah demi langkah penanggulangan masalah.
  final List<String> troubleshootingTips;

  /// Informasi diagnostik teknis yang disajikan dalam panel lipat (accordion).
  ///
  /// Di lingkungan Development/Staging menyajikan string galat lengkap untuk
  /// debugging, sedangkan di Production menyajikan token diagnostik aman
  /// terstandarisasi via `DiagnosticErrorFormatter` untuk mencegah Information
  /// Disclosure (OWASP M8).
  final String? technicalDetails;

  /// Label teks tombol aksi utama dalam format sentence case.
  final String? primaryActionLabel;

  /// Aksi yang dijalankan ketika tombol aksi utama ditekan.
  final VoidCallback? onPrimaryAction;

  /// Gaya visual tombol aksi utama.
  final AppButtonColor primaryActionStyle;

  /// Dekorasi kustom tambahan untuk tombol aksi utama.
  final AppButtonDecoration? primaryButtonDecoration;

  /// Label teks tombol aksi sekunder dalam format sentence case.
  final String? secondaryActionLabel;

  /// Aksi yang dijalankan ketika tombol aksi sekunder ditekan.
  final VoidCallback? onSecondaryAction;

  /// Gaya visual tombol aksi sekunder.
  final AppButtonColor secondaryActionStyle;

  /// Dekorasi kustom tambahan untuk tombol aksi sekunder.
  final AppButtonDecoration? secondaryButtonDecoration;

  /// Apakah kesalahan ini termasuk kategori tak terduga (*unexpected*).
  final bool isUnexpected;

  /// Mode tema visual yang diterapkan pada tampilan galat ini.
  final AppActionableErrorThemeMode themeMode;

  /// Apakah data memiliki langkah penanggulangan untuk ditampilkan.
  bool get hasTroubleshooting => troubleshootingTips.isNotEmpty;

  /// Apakah data memiliki detail teknis untuk ditampilkan.
  bool get hasTechnicalDetails =>
      technicalDetails != null && technicalDetails!.trim().isNotEmpty;

  /// Menghasilkan salinan baru dengan nilai atribut yang diperbarui.
  AppActionableErrorData copyWith({
    String? title,
    String? message,
    String? icon,
    Widget? customIcon,
    List<String>? troubleshootingTips,
    String? technicalDetails,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    AppButtonColor? primaryActionStyle,
    AppButtonDecoration? primaryButtonDecoration,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    AppButtonColor? secondaryActionStyle,
    AppButtonDecoration? secondaryButtonDecoration,
    bool? isUnexpected,
    AppActionableErrorThemeMode? themeMode,
  }) {
    return AppActionableErrorData(
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      customIcon: customIcon ?? this.customIcon,
      troubleshootingTips: troubleshootingTips != null
          ? (troubleshootingTips.isEmpty
              ? const <String>[]
              : List<String>.unmodifiable(troubleshootingTips))
          : this.troubleshootingTips,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      primaryActionLabel: primaryActionLabel ?? this.primaryActionLabel,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      primaryActionStyle: primaryActionStyle ?? this.primaryActionStyle,
      primaryButtonDecoration:
          primaryButtonDecoration ?? this.primaryButtonDecoration,
      secondaryActionLabel: secondaryActionLabel ?? this.secondaryActionLabel,
      onSecondaryAction: onSecondaryAction ?? this.onSecondaryAction,
      secondaryActionStyle: secondaryActionStyle ?? this.secondaryActionStyle,
      secondaryButtonDecoration:
          secondaryButtonDecoration ?? this.secondaryButtonDecoration,
      isUnexpected: isUnexpected ?? this.isUnexpected,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [
        title,
        message,
        icon,
        customIcon,
        troubleshootingTips,
        technicalDetails,
        primaryActionLabel,
        onPrimaryAction != null,
        primaryActionStyle,
        primaryButtonDecoration,
        secondaryActionLabel,
        onSecondaryAction != null,
        secondaryActionStyle,
        secondaryButtonDecoration,
        isUnexpected,
        themeMode,
      ];
}

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
        return showFullScreen<T>(
          context,
          data: data,
          isBlocking: isBlocking,
        );
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
        child: _ActionableErrorSlotContent(
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
                child: _ActionableErrorSlotContent(data: data),
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

// -----------------------------------------------------------------------------
// Private Atomic Slot Molecules (Arsitektur 6-Slot Terpadu)
// -----------------------------------------------------------------------------

class _ActionableErrorSlotContent extends StatelessWidget {
  const _ActionableErrorSlotContent({
    required this.data,
    this.isCompact = false,
  });

  final AppActionableErrorData data;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isCompact) const Spacer(),

        // ── Slot 1: Molecule Badge Ikon Semantik ─────────────────────────────
        _ErrorIconSlot(
          isUnexpected: data.isUnexpected,
          icon: data.icon,
          customIcon: data.customIcon,
        ),
        AppSpacing.vGap300,

        // ── Slot 2 & 3: Molecule Judul dan Deskripsi Masalah ────────────────
        _ErrorHeaderSlot(
          title: data.title,
          message: data.message,
          isCompact: isCompact,
        ),

        // ── Slot 4: Troubleshooting Slot ─────────────────────────────────────
        if (data.hasTroubleshooting) ...[
          AppSpacing.vGap300,
          _ErrorTroubleshootingSlot(
            tips: data.troubleshootingTips,
          ),
        ],

        // ── Slot 5: Technical Detail Slot (Unexpected Error) ─────────────────
        if (data.hasTechnicalDetails) ...[
          AppSpacing.vGap200,
          _ErrorTechnicalDetailsSlot(
            details: data.technicalDetails!,
          ),
        ],

        if (!isCompact) const Spacer(),
        AppSpacing.vGap300,

        // ── Slot 6: Actions Slot (Menggunakan AppButton bawaan minTouchTarget)
        _ErrorActionsSlot(
          primaryStyle: data.primaryActionStyle,
          secondaryStyle: data.secondaryActionStyle,
          primaryLabel: data.primaryActionLabel,
          onPrimary: data.onPrimaryAction,
          primaryDecoration: data.primaryButtonDecoration,
          secondaryLabel: data.secondaryActionLabel,
          onSecondary: data.onSecondaryAction,
          secondaryDecoration: data.secondaryButtonDecoration,
        ),
      ],
    );
  }
}

/// Slot 1: Molecule Badge Ikon Semantik
class _ErrorIconSlot extends StatelessWidget {
  const _ErrorIconSlot({
    required this.isUnexpected,
    this.icon,
    this.customIcon,
  });

  final String? icon;
  final Widget? customIcon;
  final bool isUnexpected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);

    final Color badgeBg;
    final Color iconColor;

    if (isUnexpected) {
      badgeBg = colorScheme.errorContainer;
      iconColor = colorScheme.onErrorContainer;
    } else {
      badgeBg = colorScheme.secondaryContainer;
      iconColor = colorScheme.onSecondaryContainer;
    }

    final effectiveIcon = customIcon ??
        AppSvgIcon(
          icon ?? KawaloVectors.alertSquareFilled,
          size: 40,
          color: iconColor,
        );

    return ExcludeSemantics(
      child: Container(
        width: 80,
        height: 80,
        decoration: ShapeDecoration(
          color: badgeBg,
          shape: AppShape.extraLarge,
        ),
        child: Center(
          child: effectiveIcon,
        ),
      ),
    );
  }
}

/// Slot 2 & 3: Molecule Judul dan Deskripsi Masalah Terstruktur
class _ErrorHeaderSlot extends StatelessWidget {
  const _ErrorHeaderSlot({
    required this.title,
    required this.message,
    required this.isCompact,
  });

  final String title;
  final String message;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: (isCompact
                    ? emphasizedScale.titleLarge
                    : emphasizedScale.headlineSmall)
                .copyWith(color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ),
        AppSpacing.vGap150,
        Text(
          message,
          style: typeScale.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Slot 4: Molecule Troubleshooting Box Terstruktur (Informational Callout).
///
/// Menggunakan [Container] dengan latar `surfaceContainerHigh` dan batas
/// `outlineVariant` (alih-alih `AppCard`) agar berfungsi murni sebagai
/// kontainer instruksional statis tanpa semantik kartu interaktif, serta
/// mempertahankan kontras tonal yang stabil di seluruh modalitas (terutama
/// saat disematkan di dalam dialog atau viewfinder kamera).
class _ErrorTroubleshootingSlot extends StatelessWidget {
  const _ErrorTroubleshootingSlot({
    required this.tips,
  });

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final emphasizedScale = theme.typography.emphasized;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space200),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.borderMedium,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: AppSvgIcon(
                  KawaloVectors.repairFilled,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              AppSpacing.hGap100,
              Expanded(
                child: Text(
                  'Cara mengatasi:',
                  style: emphasizedScale.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGap150,
          for (var i = 0; i < tips.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ',
                    style: emphasizedScale.bodySmall.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tips[i],
                      style: typeScale.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Slot 5: Molecule Detail Teknis Diagnostik (Accordion Interaktif)
class _ErrorTechnicalDetailsSlot extends StatefulWidget {
  const _ErrorTechnicalDetailsSlot({
    required this.details,
  });

  final String details;

  @override
  State<_ErrorTechnicalDetailsSlot> createState() =>
      _ErrorTechnicalDetailsSlotState();
}

class _ErrorTechnicalDetailsSlotState
    extends State<_ErrorTechnicalDetailsSlot> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _isExpanded,
          child: AppTappable(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppStateLayer.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space100,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _isExpanded
                            ? 'Sembunyikan detail teknis'
                            : 'Lihat detail teknis',
                        style: typeScale.labelMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.hGap50,
                    ExcludeSemantics(
                      child: AppSvgIcon(
                        _isExpanded
                            ? KawaloVectors.arrowUp01
                            : KawaloVectors.arrowDown01,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isExpanded) ...[
          AppSpacing.vGap100,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.space150),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.borderSmall,
            ),
            child: SelectableText(
              widget.details,
              style: typeScale.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Slot 6: Molecule Tombol Aksi Primer & Sekunder
class _ErrorActionsSlot extends StatelessWidget {
  const _ErrorActionsSlot({
    required this.primaryStyle,
    required this.secondaryStyle,
    this.primaryLabel,
    this.onPrimary,
    this.primaryDecoration,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryDecoration,
  });

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final AppButtonColor primaryStyle;
  final AppButtonDecoration? primaryDecoration;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final AppButtonColor secondaryStyle;
  final AppButtonDecoration? secondaryDecoration;

  @override
  Widget build(BuildContext context) {
    final hasPrimary = primaryLabel != null && onPrimary != null;
    final hasSecondary = secondaryLabel != null && onSecondary != null;

    if (!hasPrimary && !hasSecondary) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPrimary)
          AppButton(
            size: AppButtonSize.md,
            style: primaryStyle,
            decoration: primaryDecoration,
            onPressed: onPrimary,
            child: Text(primaryLabel!),
          ),
        if (hasPrimary && hasSecondary) AppSpacing.vGap150,
        if (hasSecondary)
          AppButton(
            size: AppButtonSize.md,
            style: secondaryStyle,
            decoration: secondaryDecoration,
            onPressed: onSecondary,
            child: Text(secondaryLabel!),
          ),
      ],
    );
  }
}

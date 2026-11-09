/// @docImport 'package:kawalo_mobile/core/widgets/actionable_error/actionable_error_facade.dart';
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

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

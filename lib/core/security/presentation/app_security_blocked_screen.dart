import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kawalo_mobile/core/security/models/security_violation_type.dart';
import 'package:kawalo_mobile/core/security/presentation/extensions/security_violation_ui_extension.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

/// Layar pemblokiran ketat (Strict Lockdown Screen) yang bersifat
/// un-dismissible.
///
/// Ditampilkan saat perangkat atau aplikasi mendeteksi pelanggaran keamanan
/// fatal seperti Root/Jailbreak, Mock GPS, atau instalasi APK tidak resmi.
/// Diimplementasikan menggunakan modalitas Fullscreen Blocking Screen
/// dari [AppActionableErrorFullScreen].
class AppSecurityBlockedScreen extends StatelessWidget {
  /// Membuat instance [AppSecurityBlockedScreen].
  const AppSecurityBlockedScreen({
    required this.violationType,
    this.onExit,
    super.key,
  });

  /// Tipe pelanggaran keamanan yang mendasari pemblokiran.
  final SecurityViolationType violationType;

  /// Callback ketika pengguna menekan tombol keluar.
  /// Jika bernilai `null`, default memanggil [SystemNavigator.pop].
  final VoidCallback? onExit;

  void _handleExit() {
    if (onExit != null) {
      onExit!.call();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorSchemeOf(context);

    final errorData = AppActionableErrorData(
      icon: violationType.icon,
      title: violationType.displayTitle,
      message: violationType.displayDescription,
      primaryActionLabel: 'Tutup aplikasi',
      onPrimaryAction: _handleExit,
      primaryButtonDecoration: AppButtonDecoration(
        backgroundColor: WidgetStatePropertyAll(colorScheme.error),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onError),
      ),
    );

    return AppActionableErrorFullScreen(data: errorData, isBlocking: true);
  }
}

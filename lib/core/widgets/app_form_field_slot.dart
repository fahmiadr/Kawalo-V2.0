import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';

/// Layout slot terstandarisasi untuk elemen masukan formulir non-text-field
/// (seperti Dropdown, Chip Selector, Date/Time Picker, atau kontrol kustom).
///
/// Memastikan seluruh elemen masukan formulir memiliki tipografi label,
/// jarak vertikal, dan pesan galat (*error text*) yang seragam dan konsisten.
class AppFormFieldSlot extends StatelessWidget {
  /// Membuat instance [AppFormFieldSlot].
  const AppFormFieldSlot({
    required this.label,
    required this.child,
    this.isRequired = false,
    this.errorText,
    this.trailing,
    this.padding,
    this.labelStyle,
    super.key,
  });

  /// Label teks field masukan (misal: "Tipe tamu", "Jenis identitas").
  final String label;

  /// Menandakan apakah field bersifat wajib (menambahkan simbol bintang `*`).
  final bool isRequired;

  /// Konten widget kontrol masukan (misal: dropdown atau chip group).
  final Widget child;

  /// Pesan galat validasi yang ditampilkan di bawah kontrol masukan (opsional).
  final String? errorText;

  /// Aksesoris opsional di sisi kanan label (misal: tooltip info atau counter).
  final Widget? trailing;

  /// Padding pembungkus field masukan.
  final EdgeInsetsGeometry? padding;

  /// Gaya tipografi teks label kustom (fallback: `typeScale.labelMedium`).
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    final displayLabel =
        isRequired && !label.endsWith('*') ? '$label *' : label;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayLabel,
                  style: labelStyle ??
                      typeScale.labelMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (trailing != null) ...[
                AppSpacing.hGapXs,
                trailing!,
              ],
            ],
          ),
          AppSpacing.vGapXs,
          child,
          if (errorText != null && errorText!.isNotEmpty) ...[
            AppSpacing.vGapXs,
            Text(
              errorText!,
              style: typeScale.bodySmall.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

/// Shows the Terms of Service Modal Bottom Sheet.
void showTermsOfServiceBottomSheet(BuildContext context) {
  final theme = AppTheme.of(context);
  final colorScheme = theme.colorScheme;
  final typeScale = theme.typeScale;
  final emphasizedTypeScale = theme.typography.emphasized;

  showAppBottomSheet<void>(
    context: context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space300,
        AppSpacing.space100,
        AppSpacing.space300,
        AppSpacing.space300,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title Slot
          Text(
            'Ketentuan layanan',
            style: emphasizedTypeScale.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),

          AppSpacing.vGap200,

          // Scrollable Terms Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    title: '1. Ketentuan Umum',
                    content:
                        'Dengan mengunduh, mendaftar, dan menggunakan '
                        'aplikasi Kawalo, Anda menyetujui untuk terikat '
                        'oleh seluruh ketentuan layanan operasional resmi '
                        'ini.',
                  ),
                  AppSpacing.vGap200,
                  _buildSection(
                    context,
                    title: '2. Akun & Kerahasiaan',
                    content:
                        'Pengguna bertanggung jawab penuh atas kerahasiaan '
                        'kata sandi akun dan semua aktivitas yang '
                        'dilakukan melalui akun tersebut.',
                  ),
                  AppSpacing.vGap200,
                  _buildSection(
                    context,
                    title: '3. Penggunaan yang Diperbolehkan',
                    content:
                        'Aplikasi Kawalo ditujukan khusus untuk manajemen '
                        'operasional, absensi GPS, laporan insiden, '
                        'dan jadwal patroli petugas di lingkungan resmi.',
                  ),
                  AppSpacing.vGap200,
                  _buildSection(
                    context,
                    title: '4. Pembatasan Tanggung Jawab',
                    content:
                        'Kawalo tidak bertanggung jawab atas keterlambatan '
                        'sinkronisasi data yang disebabkan oleh gangguan '
                        'jaringan pihak ketiga atau perangkat keras '
                        'pengguna.',
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.vGap300,

          // Bottom Action
          SizedBox(
            width: double.infinity,
            child: AppButton(
              shape: AppButtonShape.square,
              size: AppButtonSize.md,
              semanticLabel: 'Saya mengerti',
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Saya mengerti', style: typeScale.titleMedium),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSection(
  BuildContext context, {
  required String title,
  required String content,
}) {
  final theme = AppTheme.of(context);
  final colorScheme = theme.colorScheme;
  final typeScale = theme.typeScale;
  final emphasizedTypeScale = theme.typography.emphasized;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: emphasizedTypeScale.titleMedium.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      AppSpacing.vGapXs,
      Text(
        content,
        style: typeScale.bodyLarge.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

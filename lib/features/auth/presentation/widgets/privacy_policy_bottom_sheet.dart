import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';

/// Shows the Privacy Policy Modal Bottom Sheet.
void showPrivacyPolicyBottomSheet(BuildContext context) {
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
            'Kebijakan privasi',
            style: emphasizedTypeScale.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),

          AppSpacing.vGap200,

          // Scrollable Policy Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    title: '1. Pengumpulan data',
                    content: 'Kawalo mengumpulkan informasi akun seperti nama, '
                        'email, serta lokasi GPS perangkat untuk '
                        'memverifikasi kehadiran personil saat check-in '
                        'absensi dan patroli di lapangan.',
                  ),
                  AppSpacing.vGap200,
                  _buildSection(
                    context,
                    title: '2. Penggunaan informasi',
                    content:
                        'Data yang dikumpulkan digunakan semata-mata untuk '
                        'kelancaran operasional pengamanan, manajemen '
                        'shift kerja, dan penyusunan rekapitulasi laporan '
                        'bulanan.',
                  ),
                  AppSpacing.vGap200,
                  _buildSection(
                    context,
                    title: '3. Keamanan data',
                    content: 'Kami berkomitmen menjaga kerahasiaan data Anda '
                        'dengan mengimplementasikan enkripsi SSL/TLS dan '
                        'penyimpanan kredensial terenkripsi aman.',
                  ),
                  AppSpacing.vGap200,
                  _buildSection(
                    context,
                    title: '4. Hak pengguna',
                    content: 'Anda dapat memperbarui informasi akun atau '
                        'menghubungi administrator operasional Kawalo jika '
                        'memerlukan bantuan terkait privasi data Anda.',
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
              child: Text(
                'Saya mengerti',
                style: typeScale.titleMedium,
              ),
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

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_action_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_option_tile.dart';

enum ProfileAvatarAction { camera, gallery, remove }

/// Bottom sheet with the ways to change the profile photo. "Hapus foto" only
/// appears when [hasPhoto].
class ProfileAvatarSheet extends StatelessWidget {
  const ProfileAvatarSheet({required this.hasPhoto, super.key});

  final bool hasPhoto;

  static Future<ProfileAvatarAction?> show(
    BuildContext context, {
    required bool hasPhoto,
  }) => showAppBottomSheet<ProfileAvatarAction>(
    context: context,
    child: ProfileAvatarSheet(hasPhoto: hasPhoto),
  );

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space300,
            right: AppSpacing.space300,
            top: AppSpacing.space100,
            bottom: AppSpacing.space300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Foto profil',
                style: theme.typography.emphasized.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              AppSpacing.vGap300,
              AppOptionTile(
                vectorIcon: KawaloVectors.camera01,
                title: 'Ambil foto',
                subtitle: 'Gunakan kamera depan atau belakang',
                onTap: () =>
                    Navigator.of(context).pop(ProfileAvatarAction.camera),
              ),
              AppSpacing.vGap150,
              AppOptionTile(
                vectorIcon: KawaloVectors.images,
                title: 'Pilih dari galeri',
                subtitle: 'Pilih foto yang sudah ada',
                onTap: () =>
                    Navigator.of(context).pop(ProfileAvatarAction.gallery),
              ),
              if (hasPhoto) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space50),
                  child: AppDivider(),
                ),
                AppActionTile(
                  vectorIcon: KawaloVectors.delete01,
                  title: 'Hapus foto',
                  isDestructive: true,
                  closeOnTap: false,
                  onTap: () =>
                      Navigator.of(context).pop(ProfileAvatarAction.remove),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

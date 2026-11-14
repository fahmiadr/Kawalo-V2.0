import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/account_menu_row.dart';

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
    final tones = KawaloTones.of(context);
    void pop(ProfileAvatarAction action) => Navigator.of(context).pop(action);
    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Foto profil',
              style: TextStyle(
                color: tones.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            AccountMenuRow(
              icon: Icons.photo_camera_outlined,
              title: 'Ambil foto',
              subtitle: 'Gunakan kamera depan atau belakang',
              onTap: () => pop(ProfileAvatarAction.camera),
            ),
            const SizedBox(height: 8),
            AccountMenuRow(
              icon: Icons.photo_library_outlined,
              title: 'Pilih dari galeri',
              subtitle: 'Pilih foto yang sudah ada',
              onTap: () => pop(ProfileAvatarAction.gallery),
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 12),
              AppTaskButton(
                label: 'Hapus foto',
                icon: Icons.delete_outline_rounded,
                size: AppTaskButtonSize.medium,
                tone: KawaloTone(
                  color: tones.sos.soft,
                  on: tones.sos.color,
                  soft: tones.sos.soft,
                ),
                onPressed: () => pop(ProfileAvatarAction.remove),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

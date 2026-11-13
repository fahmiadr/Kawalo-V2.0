import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/cubit/theme_mode_cubit.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/core/widgets/app_action_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_overlay.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/attendance_location_screen.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/screens/attendance_setting_screen.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/profile_avatar_cubit.dart';
import 'package:kawalo_mobile/features/auth/presentation/screens/change_password_screen.dart';
import 'package:kawalo_mobile/features/face/face_module.dart';
import 'package:kawalo_mobile/features/face/presentation/screens/face_data_screen.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/app_version_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/widgets/profile_avatar_sheet.dart';

/// "Pengaturan" tab: profile of the signed-in user (with photo change),
/// theme, group switch, password change and logout.
///
/// Reads [AuthBloc] only for [Authenticated]; transient states (loading during
/// logout/switch) keep showing the last profile instead of flashing empty.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, this.mediaPicker});

  /// Test injection; defaults to the device camera and gallery.
  final MediaPickerService? mediaPicker;

  @override
  Widget build(BuildContext context) {
    // The shell tolerates a missing AuthBloc (isolated widget tests); nothing
    // here works without one, so render nothing instead of throwing.
    if (context.read<AuthBloc?>() == null) return const SizedBox.shrink();
    final authRepository = context.read<AuthRepository?>();
    final uploadRepository = context.read<UploadRepository?>();
    final body = BlocProvider(
      create: (_) => AppVersionCubit()..load(),
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (_, current) => current is Authenticated,
        builder: (context, state) {
          final auth = state is Authenticated ? state : null;
          return _MoreBody(
            user: auth?.user,
            role: auth?.session?.role,
            mediaPicker: mediaPicker,
          );
        },
      ),
    );
    // Without both repositories (isolated widget tests) the photo stays
    // read-only.
    if (authRepository == null || uploadRepository == null) return body;
    return BlocProvider(
      create: (_) => ProfileAvatarCubit(
        authRepository: authRepository,
        uploadRepository: uploadRepository,
      ),
      child: BlocConsumer<ProfileAvatarCubit, ProfileAvatarState>(
        listener: _onAvatarState,
        builder: (context, state) => Stack(
          children: [
            body,
            if (state is ProfileAvatarBusy)
              const AppLoadingOverlay(semanticLabel: 'Menyimpan foto profil'),
          ],
        ),
      ),
    );
  }

  static void _onAvatarState(BuildContext context, ProfileAvatarState state) {
    switch (state) {
      case ProfileAvatarSuccess(:final avatarUrl, :final message):
        context.read<AuthBloc>().add(AvatarUpdated(avatarUrl));
        AppSnackbar.show(context, message: message);
      case ProfileAvatarFailure(:final message):
        AppSnackbar.show(context, message: message);
      case ProfileAvatarIdle():
      case ProfileAvatarBusy():
        break;
    }
  }
}

class _MoreBody extends StatelessWidget {
  const _MoreBody({
    required this.user,
    required this.role,
    required this.mediaPicker,
  });

  final UserEntity? user;
  final String? role;
  final MediaPickerService? mediaPicker;

  static String? _roleLabel(String? role) {
    final value = role?.trim() ?? '';
    return switch (value.toUpperCase()) {
      '' => null,
      'ADMIN' => 'Admin',
      'GUARD' => 'Petugas',
      'USER' => 'Pengguna',
      _ => value,
    };
  }

  Future<void> _changeAvatar(BuildContext context, UserEntity user) async {
    final cubit = context.read<ProfileAvatarCubit>();
    final hasPhoto = user.avatarUrl?.trim().isNotEmpty ?? false;
    final action = await ProfileAvatarSheet.show(context, hasPhoto: hasPhoto);
    if (action == null || !context.mounted) return;

    if (action == ProfileAvatarAction.remove) {
      final confirmed = await showAppConfirmationDialog(
        context: context,
        title: 'Hapus foto profil?',
        message: 'Foto profil Anda akan dihapus dan diganti inisial nama.',
      );
      if ((confirmed ?? false) && !cubit.isClosed) {
        unawaited(cubit.removePhoto());
      }
      return;
    }

    final picker = mediaPicker ?? DefaultMediaPickerService();
    try {
      final files = action == ProfileAvatarAction.camera
          ? await picker.captureMultiImagesFromCamera(context, maxPhotos: 1)
          : await picker.pickMultiImagesFromGallery(limit: 1);
      if (files.isNotEmpty && !cubit.isClosed) {
        unawaited(cubit.setPhoto(files.first));
      }
    } on Object catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: action == ProfileAvatarAction.camera
              ? 'Kamera tidak dapat dibuka.'
              : 'Galeri tidak dapat dibuka.',
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Keluar dari akun?',
      message:
          'Sesi Anda akan berakhir. Anda perlu masuk kembali '
          'untuk mengakses aplikasi.',
      confirmText: 'Keluar',
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  /// Gap between menu tiles so they do not touch.
  static List<Widget> _spaced(List<Widget> tiles) => [
    for (var i = 0; i < tiles.length; i++) ...[
      if (i > 0) AppSpacing.vGap100,
      tiles[i],
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;

    final user = this.user;
    final groupName = user?.activeGroup?.groupName?.trim();
    final roleLabel = _roleLabel(role ?? user?.activeGroup?.category);
    final canSwitchGroup = user != null && user.groups.length > 1;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.marginCompact,
          vertical: AppSpacing.space200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null) ...[
              Row(
                children: [
                  _Avatar(
                    name: user.name,
                    imageUrl: user.avatarUrl,
                    onTap: context.read<ProfileAvatarCubit?>() == null
                        ? null
                        : () => unawaited(_changeAvatar(context, user)),
                  ),
                  AppSpacing.hGap200,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: typeScale.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.vGap25,
                        Text(
                          user.email,
                          style: typeScale.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (roleLabel != null) ...[
                          AppSpacing.vGapSm,
                          AppTag(
                            label: roleLabel,
                            size: AppTagSize.small,
                            semanticLabel: 'Peran $roleLabel',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (groupName != null && groupName.isNotEmpty) ...[
                AppSpacing.vGap200,
                Text(
                  'Grup aktif',
                  style: typeScale.labelMedium.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGap25,
                Text(
                  groupName,
                  style: typeScale.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
              AppSpacing.vGap200,
              const AppDivider(),
              AppSpacing.vGapSm,
            ],
            if (context.read<ThemeModeCubit?>() != null) ...[
              AppSpacing.vGapSm,
              Text(
                'Tampilan',
                style: typeScale.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vGapSm,
              const _ThemeModeSelector(),
              AppSpacing.vGap200,
              const AppDivider(),
              AppSpacing.vGapSm,
            ],
            ..._spaced([
              if (canSwitchGroup)
                AppActionTile(
                  title: 'Ganti Grup',
                  subtitle: 'Pindah ke grup lain',
                  vectorIcon: KawaloVectors.refreshCcwDot,
                  closeOnTap: false,
                  trailing: const AppSvgIcon(
                    KawaloVectors.arrowRight01,
                    size: 20,
                  ),
                  onTap: () =>
                      unawaited(AppRouter.of(context).pushGroupSelection(user)),
                ),
              if (context.read<UserSessionCubit?>()?.state?.isAdminRole ??
                  false) ...[
                AppActionTile(
                  title: 'Tentukan Titik Absen',
                  subtitle: 'Satu titik dan radius untuk semua shift',
                  vectorIcon: KawaloVectors.location01,
                  closeOnTap: false,
                  trailing: const AppSvgIcon(
                    KawaloVectors.arrowRight01,
                    size: 20,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).push(AttendanceLocationScreen.route()),
                ),
                AppActionTile(
                  title: 'Pengaturan Absensi',
                  subtitle: 'Batas kemiripan wajah untuk absen',
                  vectorIcon: KawaloVectors.userShield01,
                  closeOnTap: false,
                  trailing: const AppSvgIcon(
                    KawaloVectors.arrowRight01,
                    size: 20,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).push(AttendanceSettingScreen.route()),
                ),
              ],
              if (context.read<FaceModule?>() != null)
                AppActionTile(
                  title: 'Data Wajah',
                  subtitle: 'Status dan daftar ulang wajah',
                  vectorIcon: KawaloVectors.arrowRight01,
                  closeOnTap: false,
                  trailing: const AppSvgIcon(
                    KawaloVectors.arrowRight01,
                    size: 20,
                  ),
                  onTap: () => Navigator.of(context).push(
                    FaceDataScreen.route(
                      repository: context.read<FaceModule>().repository,
                    ),
                  ),
                ),
              if (context.read<AuthRepository?>() != null)
                AppActionTile(
                  title: 'Ganti Password',
                  subtitle: 'Ubah password akun Anda',
                  vectorIcon: KawaloVectors.lockPassword,
                  closeOnTap: false,
                  trailing: const AppSvgIcon(
                    KawaloVectors.arrowRight01,
                    size: 20,
                  ),
                  onTap: () => Navigator.of(context).push(
                    ChangePasswordScreen.route(
                      repository: context.read<AuthRepository>(),
                      authBloc: context.read<AuthBloc>(),
                    ),
                  ),
                ),
              AppActionTile(
                title: 'Keluar',
                vectorIcon: KawaloVectors.logout03,
                isDestructive: true,
                closeOnTap: false,
                onTap: () => unawaited(_confirmLogout(context)),
              ),
            ]),
            BlocBuilder<AppVersionCubit, String?>(
              builder: (context, version) {
                if (version == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space300),
                  child: Text(
                    'Versi $version',
                    textAlign: TextAlign.center,
                    style: typeScale.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeModeCubit, ThemeMode>(
      builder: (context, mode) => SizedBox(
        width: double.infinity,
        child: SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Otomatis')),
            ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
          ],
          selected: {mode},
          onSelectionChanged: (selection) =>
              unawaited(context.read<ThemeModeCubit>().select(selection.first)),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = AppUserAvatar(
      name: name,
      imageUrl: imageUrl,
      size: 64,
      maxInitials: 2,
      circle: true,
    );
    if (onTap == null) return avatar;
    return Semantics(
      button: true,
      label: 'Ubah foto profil',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatar,
      ),
    );
  }
}

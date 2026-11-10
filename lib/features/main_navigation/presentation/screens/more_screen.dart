import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/app_router.dart';
import 'package:kawalo_mobile/core/theme/app_layout.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_action_tile.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_divider.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/app_version_cubit.dart';

/// "Lainnya" tab: profile of the signed-in user, group switch and logout.
///
/// Reads [AuthBloc] only for [Authenticated]; transient states (loading during
/// logout/switch) keep showing the last profile instead of flashing empty.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The shell tolerates a missing AuthBloc (isolated widget tests); nothing
    // here works without one, so render nothing instead of throwing.
    if (context.read<AuthBloc?>() == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => AppVersionCubit()..load(),
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (_, current) => current is Authenticated,
        builder: (context, state) {
          final auth = state is Authenticated ? state : null;
          return _MoreBody(user: auth?.user, role: auth?.session?.role);
        },
      ),
    );
  }
}

class _MoreBody extends StatelessWidget {
  const _MoreBody({required this.user, required this.role});

  final UserEntity? user;
  final String? role;

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

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p.substring(0, 1)).join();
    return letters.toUpperCase();
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
                  _Avatar(name: user.name, imageUrl: user.avatarUrl),
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
                Text(groupName, style: typeScale.bodyLarge),
              ],
              AppSpacing.vGap200,
              const AppDivider(),
              AppSpacing.vGapSm,
            ],
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
                    unawaited(AppRouter.of(context).toGroupSelection(user)),
              ),
            AppActionTile(
              title: 'Keluar',
              vectorIcon: KawaloVectors.logout03,
              isDestructive: true,
              closeOnTap: false,
              onTap: () => unawaited(_confirmLogout(context)),
            ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.imageUrl});

  static const double _size = 64;

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final url = imageUrl?.trim();

    final initials = Center(
      child: Text(
        _MoreBody._initials(name),
        style: theme.typeScale.titleLarge.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Semantics(
      label: 'Foto profil $name',
      excludeSemantics: true,
      child: Container(
        width: _size,
        height: _size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: url == null || url.isEmpty
            ? initials
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }
}

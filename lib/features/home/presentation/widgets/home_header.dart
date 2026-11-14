import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kawalo_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawalo_mobile/features/home/presentation/utils/home_greeting_helper.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

/// Beranda header: avatar, short greeting and the bell. While a colleague
/// holds the PTT floor the row is covered by `<nama> sedang bicara`, on every
/// card, so nobody misses a call while looking at another task.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onAvatarTap});

  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final authState = context.watch<AuthBloc?>()?.state;
    final user = authState is Authenticated ? authState.user : null;
    final name =
        user?.name ?? context.watch<UserSessionCubit?>()?.state?.name ?? '';
    final pttState = context.watch<PttCubit?>()?.state;
    final speaker = pttState is PttListening
        ? (pttState.floorState.speaker?.name ?? 'Rekan')
        : null;

    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 8, 6),
            child: Row(
              children: [
                Semantics(
                  button: onAvatarTap != null,
                  label: 'Akun',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onAvatarTap,
                    child: AppUserAvatar(
                      name: name.isEmpty ? '?' : name,
                      imageUrl: user?.avatarUrl,
                      maxInitials: 2,
                      circle: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    HomeGreetingHelper.formatShort(name: name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tones.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Notifikasi',
                  iconSize: 24,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: tones.ink,
                  ),
                  // The backend has no notification feature yet.
                  onPressed: () => AppSnackbar.showInProgress(context),
                ),
              ],
            ),
          ),
          if (speaker != null)
            Positioned.fill(
              left: 12,
              right: 12,
              top: 4,
              bottom: 8,
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: tones.ptt.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _Wave(color: tones.ptt.on),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$speaker sedang bicara',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tones.ptt.on,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Wave extends StatelessWidget {
  const _Wave({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final h in const [6.0, 15.0, 10.0, 17.0, 7.0])
        Container(
          width: 3,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
    ],
  );
}

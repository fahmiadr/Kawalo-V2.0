import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_status_pill.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

/// "N rekan online": one row per member of the channel. Rows are plain
/// children (no nested scrollable); the screen scrolls as a whole.
class PttMemberList extends StatelessWidget {
  const PttMemberList({super.key});

  /// Taken from the live floor state, not from the fetched `speaking` flag, so
  /// it follows the channel without a refetch. While this user holds the floor
  /// the cubit ignores floor events, so that case is read from its own state.
  static String? speakingUserId(PttState state, String? selfId) {
    if (state is PttTransmitting) return selfId;
    final floor = state.floorState;
    return floor.isOccupied ? floor.speaker?.userId : null;
  }

  /// Speaker first, then by name.
  static List<PttMemberEntity> sorted(
    List<PttMemberEntity> members,
    String? speakingId,
  ) {
    int rank(PttMemberEntity m) => m.userId == speakingId ? 0 : 1;
    return [...members]..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final selfId = context.watch<UserSessionCubit?>()?.state?.userId;
    final speakingId = speakingUserId(
      context.select<PttCubit, PttState>((c) => c.state),
      selfId,
    );

    return BlocBuilder<PttMembersCubit, PttMembersState>(
      builder: (context, state) {
        final members = sorted(state.members, speakingId);
        // Same wording as the Beranda card: colleagues, not counting oneself.
        final others = members.where((m) => m.userId != selfId).length;
        final title = members.isEmpty ? 'Rekan online' : '$others rekan online';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: tones.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (state.failed) ...[
              _LoadFailed(
                onRetry: () => context.read<PttMembersCubit>().retry(),
              ),
              const SizedBox(height: 8),
            ],
            if (members.isEmpty && !state.failed && state.isLoading)
              const _MemberSkeleton()
            else if (members.isEmpty && !state.failed)
              Text(
                'Belum ada rekan online.',
                style: TextStyle(color: tones.ink2, fontSize: 15),
              ),
            for (final member in members)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MemberRow(
                  member: member,
                  isSpeaking: member.userId == speakingId,
                  isSelf: member.userId == selfId,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isSpeaking,
    required this.isSelf,
  });

  final PttMemberEntity member;
  final bool isSpeaking;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final name = member.name.trim().isEmpty ? 'Anggota' : member.name.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tones.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tones.line),
      ),
      child: Row(
        children: [
          AppUserAvatar(name: name, size: 34, maxInitials: 2, circle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tones.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isSpeaking ? 'Sedang bicara' : member.roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tones.ink2, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isSelf) ...[
            const SizedBox(width: 8),
            const AppStatusPill(label: 'Anda'),
          ],
          if (isSpeaking) ...[
            const SizedBox(width: 8),
            const AppStatusPill(
              label: 'Bicara',
              kind: AppStatusKind.ok,
              icon: Icons.graphic_eq_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberSkeleton extends StatelessWidget {
  const _MemberSkeleton();

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Semantics(
      label: 'Memuat daftar rekan',
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: tones.surface2,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Gagal memuat daftar rekan',
            style: TextStyle(color: tones.sos.color, fontSize: 15),
          ),
        ),
        AppTaskButton(
          label: 'Coba lagi',
          icon: Icons.refresh_rounded,
          variant: AppTaskButtonVariant.secondary,
          size: AppTaskButtonSize.small,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_tag.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';

/// "Anggota Online (N)": one row per member of the channel. Rows are plain
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selfId = context.watch<UserSessionCubit?>()?.state?.userId;
    final speakingId = speakingUserId(
      context.select<PttCubit, PttState>((c) => c.state),
      selfId,
    );

    return BlocBuilder<PttMembersCubit, PttMembersState>(
      builder: (context, state) {
        final members = sorted(state.members, speakingId);
        final title = state.members.isEmpty
            ? 'Anggota Online'
            : 'Anggota Online (${state.members.length})';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.failed) ...[
                const SizedBox(height: AppSpacing.sm),
                _LoadFailed(
                  onRetry: () => context.read<PttMembersCubit>().retry(),
                ),
              ],
              if (members.isEmpty && !state.failed) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.isLoading
                      ? 'Memuat daftar anggota...'
                      : 'Belum ada anggota online.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              for (final member in members)
                _MemberRow(
                  member: member,
                  isSpeaking: member.userId == speakingId,
                  isSelf: member.userId == selfId,
                ),
            ],
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = member.name.trim().isEmpty ? 'Anggota' : member.name.trim();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isSpeaking
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            foregroundColor: isSpeaking
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            child: Text(name.characters.first.toUpperCase()),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const AppTag(
                        label: 'Anda',
                        variant: AppTagVariant.neutral,
                        size: AppTagSize.small,
                      ),
                    ],
                  ],
                ),
                Text(
                  member.roleLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (isSpeaking)
            const AppTag(
              label: 'Bicara',
              size: AppTagSize.small,
              leading: Icon(Icons.graphic_eq_rounded),
            )
          else
            const AppTag(
              label: 'Siaga',
              variant: AppTagVariant.neutral,
              size: AppTagSize.small,
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
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Gagal memuat daftar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
        AppButton(
          style: AppButtonColor.tonal,
          size: AppButtonSize.custom(
            height: AppStateLayer.minTouchTarget,
            hPadding: AppSpacing.space200,
          ),
          onPressed: onRetry,
          child: const Text('Coba lagi'),
        ),
      ],
    );
  }
}

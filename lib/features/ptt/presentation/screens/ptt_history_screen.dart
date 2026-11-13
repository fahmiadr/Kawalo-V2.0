import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/utils/app_date_format.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_empty_state.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_refresh_indicator.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/list_screen/list_screen_views.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_recording_repository.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_recordings_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_recordings_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/services/ptt_audio_player.dart';
import 'package:kawalo_mobile/features/ptt/presentation/utils/ptt_duration_format.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_recording_bubble.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_recording_skeleton.dart';

/// "Riwayat PTT": recorded walkie-talkie turns of the active group as
/// voice-note bubbles, newest at the bottom.
class PttHistoryScreen extends StatefulWidget {
  const PttHistoryScreen({super.key});

  /// Both cubits live exactly as long as the route, so leaving the screen
  /// stops playback and clears the downloaded audio.
  static Route<void> route(PttRecordingRepository repository) =>
      AppPageRoute.forwardBackward<void>(
        settings: const RouteSettings(name: AppRouteNames.pttHistory),
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<PttRecordingsCubit>(
              create: (_) => PttRecordingsCubit(repository: repository)..load(),
            ),
            BlocProvider<PttPlaybackCubit>(
              create: (_) => PttPlaybackCubit(
                repository: repository,
                player: JustAudioPttPlayer(),
              ),
            ),
          ],
          child: const PttHistoryScreen(),
        ),
      );

  @override
  State<PttHistoryScreen> createState() => _PttHistoryScreenState();
}

class _PttHistoryScreenState extends State<PttHistoryScreen> {
  late final LoadMoreScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = LoadMoreScrollController(
      onLoadMore: () =>
          unawaited(context.read<PttRecordingsCubit>().loadMore()),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    PttRecordingEntity recording,
    AuthSessionEntity? session,
  ) async {
    final recordings = context.read<PttRecordingsCubit>();
    final playback = context.read<PttPlaybackCubit>();
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Hapus Rekaman?',
      message:
          'Rekaman ${recording.speakerName} '
          '(${formatPttDuration(recording.duration)}) akan dihapus untuk '
          'semua anggota grup dan tidak dapat dipulihkan.',
      confirmText: 'Hapus Rekaman',
    );
    if (confirmed != true) return;
    await playback.stopIfActive(recording.id);
    await recordings.delete(recording.id, session: session);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    final session = context.watch<UserSessionCubit>().state;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Riwayat PTT'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PttRecordingsCubit, PttRecordingsState>(
            listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
            listener: (context, state) {
              final notice = state.notice;
              if (notice != null) AppSnackbar.show(context, message: notice);
            },
          ),
          BlocListener<PttPlaybackCubit, PttPlaybackState>(
            listenWhen: (a, b) => a.errorSeq != b.errorSeq,
            listener: (context, state) {
              final error = state.error;
              if (error != null) AppSnackbar.show(context, message: error);
            },
          ),
        ],
        child: SafeArea(
          top: false,
          child: AppRefreshIndicator.contained(
            semanticsLabel: 'Memuat ulang riwayat PTT',
            onRefresh: context.read<PttRecordingsCubit>().refresh,
            child: BlocBuilder<PttRecordingsCubit, PttRecordingsState>(
              builder: (context, state) => switch (state.status) {
                PttRecordingsStatus.loading => const PttRecordingSkeleton(),
                PttRecordingsStatus.failure => ListErrorState(
                  noun: 'riwayat PTT',
                  message:
                      state.errorMessage ??
                      'Terjadi kendala saat memuat riwayat PTT.',
                  onRetry: () =>
                      unawaited(context.read<PttRecordingsCubit>().load()),
                ),
                PttRecordingsStatus.loaded when state.items.isEmpty =>
                  AppEmptyState(
                    icon: Icon(
                      Icons.mic_none_rounded,
                      color: colorScheme.outline,
                    ),
                    title: 'Belum ada rekaman',
                    description:
                        'Percakapan Walkie-Talkie yang direkam akan muncul '
                        'di sini.',
                  ),
                PttRecordingsStatus.loaded => _buildList(state, session),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(PttRecordingsState state, AuthSessionEntity? session) {
    final rows = _rowsFor(state.items);
    final canDelete = session?.isAdminRole ?? false;

    // Reversed so the newest turn sits at the bottom and "older" is reached by
    // scrolling up; index 0 is the newest.
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space200,
        AppSpacing.space100,
        AppSpacing.space200,
        AppSpacing.space300,
      ),
      itemCount: rows.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return const Padding(
            padding: AppSpacing.paddingVertical200,
            child: Center(child: AppLoadingIndicator()),
          );
        }
        final row = rows[index];
        if (row.date != null) return _DateSeparator(date: row.date!);

        final recording = row.recording!;
        return BlocBuilder<PttPlaybackCubit, PttPlaybackState>(
          buildWhen: (a, b) =>
              a.isActive(recording.id) || b.isActive(recording.id),
          builder: (context, playback) => PttRecordingBubble(
            key: ValueKey(recording.id),
            recording: recording,
            isMe: recording.isSpokenBy(session?.email),
            isFirstInGroup: row.isFirstInGroup,
            isLastInGroup: row.isLastInGroup,
            playback: playback,
            canDelete: canDelete,
            isDeleting: state.deletingIds.contains(recording.id),
            onDelete: () => unawaited(_confirmDelete(recording, session)),
            onTogglePlay: () =>
                unawaited(context.read<PttPlaybackCubit>().toggle(recording)),
            onSeek: (position) => unawaited(
              context.read<PttPlaybackCubit>().seek(recording.id, position),
            ),
          ),
        );
      },
    );
  }

  /// Turns of one speaker this close together share one avatar and name.
  static const _groupGap = Duration(minutes: 5);

  /// [items] are newest first. In the reversed list a day's separator must come
  /// after (above) its oldest turn, so it is inserted when the day changes.
  /// On screen `items[i + 1]` sits directly above `items[i]`.
  static List<_Row> _rowsFor(List<PttRecordingEntity> items) {
    final rows = <_Row>[];
    for (var i = 0; i < items.length; i++) {
      final above = i == items.length - 1 ? null : items[i + 1];
      final below = i == 0 ? null : items[i - 1];
      rows.add(
        _Row.recording(
          items[i],
          isFirstInGroup: !_sameGroup(above, items[i]),
          isLastInGroup: !_sameGroup(items[i], below),
        ),
      );
      final isLastOfDay =
          above == null || !_sameDay(items[i].startedAt, above.startedAt);
      if (isLastOfDay) rows.add(_Row.date(items[i].startedAt));
    }
    return rows;
  }

  static bool _sameGroup(PttRecordingEntity? older, PttRecordingEntity? newer) {
    if (older == null || newer == null) return false;
    return older.speakerId == newer.speakerId &&
        _sameDay(older.startedAt, newer.startedAt) &&
        newer.startedAt.difference(older.startedAt).abs() <= _groupGap;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Row {
  const _Row.recording(
    PttRecordingEntity this.recording, {
    required this.isFirstInGroup,
    required this.isLastInGroup,
  }) : date = null;
  const _Row.date(DateTime this.date)
    : recording = null,
      isFirstInGroup = false,
      isLastInGroup = false;

  final PttRecordingEntity? recording;
  final DateTime? date;
  final bool isFirstInGroup;
  final bool isLastInGroup;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return AppDateFormat.formatWeekdayDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    // The turn below always starts a group and brings its own top gap.
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.space300),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space200,
          vertical: AppSpacing.space75,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
        ),
        child: Text(
          _label(),
          style: theme.typeScale.labelMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

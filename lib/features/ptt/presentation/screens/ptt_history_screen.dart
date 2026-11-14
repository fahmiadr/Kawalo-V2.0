import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';
import 'package:kawalo_mobile/core/routes/app_route_names.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
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
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_channel_header.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_recording_skeleton.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_recording_tile.dart';

/// "Riwayat PTT": recorded walkie-talkie turns of the active group as a chat,
/// oldest at the top and newest at the bottom, grouped by day.
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
      title: 'Hapus rekaman ini?',
      message:
          'Rekaman ${recording.speakerName} pukul '
          '${formatPttClock(recording.startedAt)} '
          '(${formatPttDuration(recording.duration)}) dan transkripnya '
          'dihapus untuk semua anggota. Tidak bisa dibatalkan.',
    );
    if (confirmed != true) return;
    await playback.stopIfActive(recording.id);
    await recordings.delete(recording.id, session: session);
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final session = context.watch<UserSessionCubit>().state;

    return Scaffold(
      backgroundColor: tones.background,
      appBar: AppBar(
        title: PttAppBarTitle(
          title: 'Riwayat PTT',
          subtitle: PttAppBarTitle.channelName(context),
        ),
        backgroundColor: tones.background,
        surfaceTintColor: Colors.transparent,
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
                    icon: Icon(Icons.mic_none_rounded, color: tones.ptt.color),
                    title: 'Belum ada rekaman',
                    description:
                        'Setiap giliran bicara di kanal ini tersimpan di '
                        'sini.',
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

    // `reverse` anchors the list at the newest turn without a jump-to-bottom
    // and turns the scroll-extent end into the top edge, where older pages load.
    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: rows.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return const Padding(
            padding: AppSpacing.paddingVertical200,
            child: Center(child: AppLoadingIndicator()),
          );
        }
        final row = rows[index];
        if (row.date != null) {
          return _DateLabel(date: row.date!);
        }

        final recording = row.recording!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: BlocBuilder<PttPlaybackCubit, PttPlaybackState>(
            buildWhen: (a, b) =>
                a.isActive(recording.id) || b.isActive(recording.id),
            builder: (context, playback) => PttRecordingTile(
              key: ValueKey(recording.id),
              recording: recording,
              isMe: recording.isSpokenBy(session?.email),
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
          ),
        );
      },
    );
  }

  static DateTime _dayOf(PttRecordingEntity item) {
    final t = item.startedAt;
    return DateTime(t.year, t.month, t.day);
  }

  /// [items] are newest first, which is bottom-up in the reversed list, so a
  /// day's label goes after its oldest turn to render above the whole group.
  static List<_Row> _rowsFor(List<PttRecordingEntity> items) {
    final rows = <_Row>[];
    for (var i = 0; i < items.length; i++) {
      rows.add(_Row.recording(items[i]));
      final day = _dayOf(items[i]);
      if (i + 1 == items.length || _dayOf(items[i + 1]) != day) {
        rows.add(_Row.date(day));
      }
    }
    return rows;
  }
}

class _Row {
  const _Row.recording(PttRecordingEntity this.recording) : date = null;
  const _Row.date(DateTime this.date) : recording = null;

  final PttRecordingEntity? recording;
  final DateTime? date;
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return AppDateFormat.formatWeekdayDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();
    final tones = KawaloTones.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Semantics(
        header: true,
        label: label,
        excludeSemantics: true,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tones.ptt.soft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: tones.ptt.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.84,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

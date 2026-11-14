import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/utils/ptt_duration_format.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_waveform.dart';

/// `HH.mm`, the Indonesian clock style used across the redesign.
String formatPttClock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}.'
    '${t.minute.toString().padLeft(2, '0')}';

/// One recorded PTT turn in "Riwayat PTT", laid out as a chat message: others
/// on the left with an avatar, the signed-in user's own on the right without
/// one, in a soft brand tone. Speaker and clock time, a voice bar (play/pause,
/// seekable waveform, length) and the transcript below it.
///
/// Purely presentational; the screen feeds it the playback state of this
/// recording only, so a ticking position rebuilds one row, not the list.
class PttRecordingTile extends StatefulWidget {
  const PttRecordingTile({
    required this.recording,
    required this.isMe,
    required this.playback,
    required this.onTogglePlay,
    required this.onSeek,
    super.key,
    this.canDelete = false,
    this.isDeleting = false,
    this.onDelete,
  });

  static const double avatarSize = 34;

  /// Share of the row a message may take, so the two sides stay distinct.
  static const double widthFactor = 0.88;

  final PttRecordingEntity recording;
  final bool isMe;

  /// Playback state; only meaningful when it [PttPlaybackState.isActive] for
  /// this recording.
  final PttPlaybackState playback;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;

  /// Administrators only; the options menu is not built otherwise.
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  State<PttRecordingTile> createState() => _PttRecordingTileState();
}

class _PttRecordingTileState extends State<PttRecordingTile> {
  /// Waveform position while it is dragged, for the time label.
  double? _dragFraction;

  bool get _isActive => widget.playback.isActive(widget.recording.id);

  PttPlaybackStatus get _status =>
      _isActive ? widget.playback.status : PttPlaybackStatus.idle;

  double get _fraction {
    final total = widget.recording.duration.inMilliseconds;
    if (!_isActive || total <= 0) return 0;
    return (widget.playback.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Settled without text (silence, or a transcript that came back empty):
  /// "not available yet" would wrongly promise one.
  bool get _noTranscriptExpected => switch (widget.recording.transcriptStatus) {
    'no_speech' || 'done' => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final recording = widget.recording;
    final total = recording.duration;
    final transcript = recording.displayTranscript;
    final name = widget.isMe ? 'Anda' : recording.speakerName.trim();

    final isPlaying = _status == PttPlaybackStatus.playing;
    final isLoading = _status == PttPlaybackStatus.loading;
    final canSeek = _isActive && !isLoading;

    final shownFraction = _dragFraction ?? _fraction;
    final shownPosition = Duration(
      milliseconds: (total.inMilliseconds * shownFraction).round(),
    );
    final lengthLabel = canSeek
        ? '${formatPttDuration(shownPosition)} / ${formatPttDuration(total)}'
        : formatPttDuration(total);

    final playButton = SizedBox.square(
      dimension: AppStateLayer.minTouchTarget,
      child: isLoading
          ? Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: tones.ptt.color,
                ),
              ),
            )
          : IconButton.filled(
              onPressed: widget.onTogglePlay,
              tooltip: isPlaying ? 'Jeda rekaman' : 'Putar rekaman',
              style: IconButton.styleFrom(
                backgroundColor: tones.ptt.color,
                foregroundColor: tones.ptt.on,
              ),
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 26,
              ),
            ),
    );

    final voiceBar = Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: widget.isMe ? tones.ptt.soft : tones.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          playButton,
          const SizedBox(width: 8),
          Expanded(
            child: PttWaveform(
              bars: recording.waveform,
              value: shownFraction,
              total: total,
              playedColor: tones.ptt.color,
              unplayedColor: tones.ink2.withValues(alpha: 0.45),
              onChanged: canSeek
                  ? (value) => setState(() => _dragFraction = value)
                  : null,
              onChangeEnd: canSeek
                  ? (value) {
                      setState(() => _dragFraction = null);
                      widget.onSeek(
                        Duration(
                          milliseconds: (total.inMilliseconds * value).round(),
                        ),
                      );
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // Flexible so large text shrinks the label instead of overflowing.
          Flexible(
            child: Text(
              lengthLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.monoFigures.copyWith(
                color: tones.ink2,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    final isMe = widget.isMe;
    final options = widget.canDelete
        ? _OptionsButton(
            isDeleting: widget.isDeleting,
            onDelete: widget.onDelete,
          )
        // Keeps every row as tall as an admin's, so the list does not jump
        // between roles.
        : const SizedBox(height: AppStateLayer.minTouchTarget);
    final nameText = Flexible(
      child: Text(
        name.isEmpty ? 'Anggota' : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tones.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final clockText = Text(
      formatPttClock(recording.startedAt),
      style: AppTheme.monoFigures.copyWith(color: tones.ink2, fontSize: 13),
    );

    final message = Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          children: isMe
              ? [
                  options,
                  const Spacer(),
                  nameText,
                  const SizedBox(width: 8),
                  clockText,
                ]
              : [
                  nameText,
                  const SizedBox(width: 8),
                  clockText,
                  const Spacer(),
                  options,
                ],
        ),
        voiceBar,
        if (transcript != null)
          _TranscriptBlock(text: transcript, alignEnd: isMe)
        else if (!_noTranscriptExpected)
          Text(
            'Transkrip belum tersedia',
            style: TextStyle(
              color: tones.ink2,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: PttRecordingTile.widthFactor,
        child: isMe
            ? message
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: AppUserAvatar(
                      name: recording.speakerName,
                      imageUrl: recording.speakerAvatarUrl,
                      size: PttRecordingTile.avatarSize,
                      maxInitials: 2,
                      circle: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: message),
                ],
              ),
      ),
    );
  }
}

class _OptionsButton extends StatelessWidget {
  const _OptionsButton({required this.isDeleting, required this.onDelete});

  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    if (isDeleting) {
      return SizedBox.square(
        dimension: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: tones.ink2,
              semanticsLabel: 'Menghapus rekaman',
            ),
          ),
        ),
      );
    }
    return PopupMenuButton<bool>(
      tooltip: 'Opsi rekaman',
      style: IconButton.styleFrom(minimumSize: const Size.square(48)),
      icon: Icon(Icons.more_horiz_rounded, color: tones.ink),
      onSelected: (_) => onDelete?.call(),
      itemBuilder: (_) => [
        PopupMenuItem<bool>(
          value: true,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: tones.sos.color),
              const SizedBox(width: 12),
              Text('Hapus rekaman', style: TextStyle(color: tones.sos.color)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quoted transcript, collapsed to [collapsedLines] with a toggle only when
/// the text is longer.
class _TranscriptBlock extends StatefulWidget {
  const _TranscriptBlock({required this.text, required this.alignEnd});

  static const collapsedLines = 3;

  final String text;
  final bool alignEnd;

  @override
  State<_TranscriptBlock> createState() => _TranscriptBlockState();
}

class _TranscriptBlockState extends State<_TranscriptBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final bodyStyle = TextStyle(color: tones.ink2, fontSize: 13, height: 1.4);
    final quoted = '“${widget.text}”';

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: quoted, style: bodyStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: _TranscriptBlock.collapsedLines,
        )..layout(maxWidth: constraints.maxWidth);
        final isLong = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              quoted,
              textAlign: widget.alignEnd ? TextAlign.end : TextAlign.start,
              maxLines: _expanded || !isLong
                  ? null
                  : _TranscriptBlock.collapsedLines,
              overflow: _expanded || !isLong
                  ? TextOverflow.clip
                  : TextOverflow.ellipsis,
              style: bodyStyle,
            ),
            if (isLong)
              Semantics(
                button: true,
                expanded: _expanded,
                excludeSemantics: true,
                label: _expanded
                    ? 'Ringkas transkrip'
                    : 'Tampilkan transkrip lengkap',
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppStateLayer.minTouchTarget,
                      minWidth: AppStateLayer.minTouchTarget,
                    ),
                    child: Align(
                      alignment: widget.alignEnd
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      widthFactor: 1,
                      child: Text(
                        _expanded ? 'Ringkas' : 'Selengkapnya',
                        style: TextStyle(
                          color: tones.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: tones.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

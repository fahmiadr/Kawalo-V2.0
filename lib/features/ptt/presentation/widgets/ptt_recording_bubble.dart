import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_radius.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_state_layer.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/utils/ptt_duration_format.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_waveform.dart';

/// Voice-note style bubble of one recorded PTT turn: play/pause, seekable
/// waveform, length and clock time. Own turns sit on the right.
///
/// Consecutive turns of one speaker form a group: only the first shows the
/// avatar and name and carries the pointed corner, so a burst of short turns
/// reads as one block.
///
/// Purely presentational; the screen feeds it the playback state of this
/// recording only, so a ticking position rebuilds one bubble, not the list.
class PttRecordingBubble extends StatefulWidget {
  const PttRecordingBubble({
    required this.recording,
    required this.isMe,
    required this.playback,
    required this.onTogglePlay,
    required this.onSeek,
    super.key,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.canDelete = false,
    this.isDeleting = false,
    this.onDelete,
  });

  static const double avatarSize = 32;

  /// Bubbles without a transcript grow with the clip up to this length, the
  /// server's cap on one turn.
  static const Duration longestTurn = Duration(seconds: 30);
  static const double minWidth = 208;

  final PttRecordingEntity recording;
  final bool isMe;

  /// Playback state; only meaningful when it [PttPlaybackState.isActive] for
  /// this recording.
  final PttPlaybackState playback;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;

  final bool isFirstInGroup;
  final bool isLastInGroup;

  /// Administrators only; the delete button is not built otherwise.
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  State<PttRecordingBubble> createState() => _PttRecordingBubbleState();
}

class _PttRecordingBubbleState extends State<PttRecordingBubble> {
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

  String get _initial {
    final name = widget.recording.speakerName.trim();
    return name.isEmpty ? '?' : name.characters.first.toUpperCase();
  }

  String get _time {
    final t = widget.recording.startedAt;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  double _bubbleWidth(double available, {required bool hasTranscript}) {
    final max = available * 0.92;
    if (hasTranscript) return max;
    final min = math.min(PttRecordingBubble.minWidth, max);
    final share =
        widget.recording.duration.inMilliseconds /
        PttRecordingBubble.longestTurn.inMilliseconds;
    // Square root so the common 2 to 10 s turns still differ visibly.
    return min + (max - min) * math.sqrt(share.clamp(0.0, 1.0));
  }

  BorderRadius _shape() {
    const round = AppRadius.radiusLgIncreased;
    final tail = widget.isFirstInGroup
        ? AppRadius.radiusXs
        : AppRadius.radiusSm;
    final joined = widget.isLastInGroup ? round : AppRadius.radiusSm;
    return widget.isMe
        ? BorderRadius.only(
            topLeft: round,
            bottomLeft: round,
            topRight: tail,
            bottomRight: joined,
          )
        : BorderRadius.only(
            topLeft: tail,
            bottomLeft: joined,
            topRight: round,
            bottomRight: round,
          );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final isMe = widget.isMe;
    final total = widget.recording.duration;
    final transcript = widget.recording.displayTranscript;

    final bubbleColor = isMe
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final textColor = isMe
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final metaColor = isMe
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

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
          ? const Center(
              child: SizedBox.square(
                dimension: 24,
                child: AppLoadingIndicator(),
              ),
            )
          : IconButton.filled(
              onPressed: widget.onTogglePlay,
              tooltip: isPlaying ? 'Jeda rekaman' : 'Putar rekaman',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 28,
              ),
            ),
    );

    final metaStyle = typeScale.labelMedium.copyWith(color: metaColor);

    final audio = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            playButton,
            AppSpacing.hGap150,
            Expanded(
              child: PttWaveform(
                bars: widget.recording.waveform,
                value: shownFraction,
                total: total,
                playedColor: colorScheme.primary,
                unplayedColor: textColor.withValues(alpha: 0.3),
                onChanged: canSeek
                    ? (value) => setState(() => _dragFraction = value)
                    : null,
                onChangeEnd: canSeek
                    ? (value) {
                        setState(() => _dragFraction = null);
                        widget.onSeek(
                          Duration(
                            milliseconds: (total.inMilliseconds * value)
                                .round(),
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
        AppSpacing.vGap50,
        Row(
          children: [
            Expanded(child: Text(lengthLabel, style: metaStyle)),
            AppSpacing.hGap100,
            Text(_time, style: metaStyle),
          ],
        ),
      ],
    );

    // With a transcript the voice part becomes an inset card, so the text
    // below reads like a quote of the audio while both stay in one bubble.
    final audioPart = transcript == null
        ? audio
        : Container(
            padding: const EdgeInsets.all(AppSpacing.space150),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.08),
              borderRadius: AppRadius.borderMedium,
            ),
            child: audio,
          );

    final showName = !isMe && widget.isFirstInGroup;

    final bubbleBody = Container(
      padding: const EdgeInsets.all(AppSpacing.space150),
      decoration: BoxDecoration(color: bubbleColor, borderRadius: _shape()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showName) ...[
            _SpeakerName(name: widget.recording.speakerName),
            AppSpacing.vGap100,
          ],
          audioPart,
          if (transcript != null)
            _TranscriptBlock(text: transcript, color: textColor),
          if (widget.canDelete) ...[
            AppSpacing.vGap150,
            Align(
              alignment: Alignment.centerRight,
              child: _DeleteButton(
                isDeleting: widget.isDeleting,
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ],
      ),
    );

    final avatar = widget.isFirstInGroup
        ? CircleAvatar(
            radius: PttRecordingBubble.avatarSize / 2,
            backgroundColor: colorScheme.secondaryContainer,
            child: Text(
              _initial,
              style: typeScale.labelLarge.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          )
        : const SizedBox(width: PttRecordingBubble.avatarSize);

    return Padding(
      padding: EdgeInsets.only(
        top: widget.isFirstInGroup ? AppSpacing.space250 : AppSpacing.space75,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Both sides reserve the avatar column, so own and others' bubbles
          // share one width scale.
          const avatarSlot =
              PttRecordingBubble.avatarSize + AppSpacing.space100;
          final width = _bubbleWidth(
            constraints.maxWidth - avatarSlot,
            hasTranscript: transcript != null,
          );
          final bubble = SizedBox(width: width, child: bubbleBody);
          return Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[avatar, AppSpacing.hGap100],
              bubble,
            ],
          );
        },
      ),
    );
  }
}

class _SpeakerName extends StatelessWidget {
  const _SpeakerName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.emphasized.labelLarge.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}

/// Collapsed to [collapsedLines] with a toggle only when the text is longer.
class _TranscriptBlock extends StatefulWidget {
  const _TranscriptBlock({required this.text, required this.color});

  static const collapsedLines = 3;

  final String text;
  final Color color;

  @override
  State<_TranscriptBlock> createState() => _TranscriptBlockState();
}

class _TranscriptBlockState extends State<_TranscriptBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final typeScale = theme.typeScale;
    final bodyStyle = typeScale.bodyMedium.copyWith(color: widget.color);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.space50,
        right: AppSpacing.space50,
        top: AppSpacing.space150,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: bodyStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: _TranscriptBlock.collapsedLines,
          )..layout(maxWidth: constraints.maxWidth);
          final isLong = painter.didExceedMaxLines;
          painter.dispose();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
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
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: Text(
                          _expanded ? 'Ringkas' : 'Selengkapnya',
                          style: typeScale.labelLarge.copyWith(
                            color: widget.color,
                            decoration: TextDecoration.underline,
                            decorationColor: widget.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.isDeleting, required this.onPressed});

  final bool isDeleting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.of(context).colorScheme;
    return AppButton(
      enabled: !isDeleting,
      onPressed: isDeleting ? null : onPressed,
      semanticLabel: 'Hapus rekaman',
      size: AppButtonSize.custom(
        height: AppStateLayer.minTouchTarget,
        hPadding: AppSpacing.space200,
      ),
      decoration: AppButtonDecoration(
        backgroundColor: WidgetStatePropertyAll<Color?>(colorScheme.error),
        foregroundColor: WidgetStatePropertyAll<Color?>(colorScheme.onError),
      ),
      child: isDeleting
          ? const SizedBox.square(dimension: 16, child: AppLoadingIndicator())
          : const Text('Hapus'),
    );
  }
}

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

/// Voice-note style bubble of one recorded PTT turn: initial, play/pause,
/// seekable progress bar, duration and time. Own turns sit on the right.
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
    this.canDelete = false,
    this.isDeleting = false,
    this.onDelete,
  });

  final PttRecordingEntity recording;
  final bool isMe;

  /// Playback state; only meaningful when it [PttPlaybackState.isActive] for
  /// this recording.
  final PttPlaybackState playback;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;

  /// Administrators only; the delete button is not built otherwise.
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  State<PttRecordingBubble> createState() => _PttRecordingBubbleState();
}

class _PttRecordingBubbleState extends State<PttRecordingBubble> {
  /// Slider value while the thumb is dragged; the player position would
  /// otherwise pull it back under the finger.
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final colorScheme = theme.colorScheme;
    final typeScale = theme.typeScale;
    final isMe = widget.isMe;
    final total = widget.recording.duration;

    final bubbleColor = isMe
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final textColor = isMe
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final metaColor = isMe
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    final shownFraction = _dragFraction ?? _fraction;
    final shownPosition = _isActive
        ? Duration(milliseconds: (total.inMilliseconds * shownFraction).round())
        : Duration.zero;
    // Counts down while playing like a voice note; the full length otherwise.
    final timeLabel = _isActive && _status != PttPlaybackStatus.loading
        ? formatPttDuration(shownPosition)
        : formatPttDuration(total);

    final isPlaying = _status == PttPlaybackStatus.playing;
    final isLoading = _status == PttPlaybackStatus.loading;

    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: isMe
          ? colorScheme.primary
          : colorScheme.secondaryContainer,
      child: Text(
        _initial,
        style: typeScale.titleMedium.copyWith(
          color: isMe
              ? colorScheme.onPrimary
              : colorScheme.onSecondaryContainer,
        ),
      ),
    );

    final playButton = SizedBox.square(
      dimension: AppStateLayer.minTouchTarget,
      child: isLoading
          ? const Center(
              child: SizedBox.square(
                dimension: 24,
                child: AppLoadingIndicator(),
              ),
            )
          : IconButton(
              onPressed: widget.onTogglePlay,
              tooltip: isPlaying ? 'Jeda rekaman' : 'Putar rekaman',
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 32,
                color: textColor,
              ),
            ),
    );

    final transcript = widget.recording.displayTranscript;

    final audioBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.space150),
            child: Text(
              widget.recording.speakerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.emphasized.labelMedium.copyWith(
                color: textColor,
              ),
            ),
          ),
        Row(
          children: [
            playButton,
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.outlineVariant,
                  thumbColor: colorScheme.primary,
                ),
                child: Slider(
                  value: shownFraction,
                  semanticFormatterCallback: (_) =>
                      '$timeLabel dari ${formatPttDuration(total)}',
                  onChanged: _isActive && !isLoading
                      ? (value) => setState(() => _dragFraction = value)
                      : null,
                  onChangeEnd: (value) {
                    setState(() => _dragFraction = null);
                    widget.onSeek(
                      Duration(
                        milliseconds: (total.inMilliseconds * value).round(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.space150),
          child: Row(
            children: [
              Text(
                timeLabel,
                style: typeScale.labelSmall.copyWith(color: metaColor),
              ),
              const Spacer(),
              Text(
                _time,
                style: typeScale.labelSmall.copyWith(color: metaColor),
              ),
            ],
          ),
        ),
      ],
    );

    final audio = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe) ...[avatar, AppSpacing.hGapXs],
        Flexible(child: audioBody),
        if (isMe) ...[AppSpacing.hGapXs, avatar],
      ],
    );

    // With a transcript the voice part becomes an inset card, so the text
    // below reads like a quote of the audio while both stay in one bubble.
    final audioPart = transcript == null
        ? audio
        : Container(
            padding: const EdgeInsets.all(AppSpacing.space100),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: audio,
          );

    final maxWidth = MediaQuery.sizeOf(context).width * 0.88;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.space100),
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(AppSpacing.space100),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.lg),
          topRight: const Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(isMe ? AppRadius.lg : AppRadius.xs),
          bottomRight: Radius.circular(isMe ? AppRadius.xs : AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          audioPart,
          if (transcript != null)
            _TranscriptBlock(text: transcript, color: textColor),
          if (widget.canDelete) ...[
            AppSpacing.vGapSm,
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
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
        left: AppSpacing.space100,
        right: AppSpacing.space100,
        top: AppSpacing.space100,
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_recording_tile.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_waveform.dart';

import '../../ptt_recording_fixtures.dart';

void main() {
  Widget host({
    bool isMe = false,
    bool canDelete = false,
    bool isDeleting = false,
    PttPlaybackState playback = const PttPlaybackState(),
    VoidCallback? onTogglePlay,
    ValueChanged<Duration>? onSeek,
    VoidCallback? onDelete,
    String? transcript,
    String? transcriptStatus,
    ThemeData? theme,
    double textScale = 1,
    Duration duration = const Duration(seconds: 65),
    Uint8List? waveform,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightThemeData(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PttRecordingTile(
            recording: recording(
              'a',
              duration: duration,
              transcript: transcript,
              transcriptStatus: transcriptStatus,
              waveform: waveform,
            ),
            isMe: isMe,
            playback: playback,
            canDelete: canDelete,
            isDeleting: isDeleting,
            onTogglePlay: onTogglePlay ?? () {},
            onSeek: onSeek ?? (_) {},
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }

  testWidgets('shows speaker, initial, length and clock time', (tester) async {
    await tester.pumpWidget(host());

    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('09.30'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('own turns are labelled Anda', (tester) async {
    await tester.pumpWidget(host(isMe: true));

    expect(find.text('Anda'), findsOneWidget);
    expect(find.text('Budi'), findsNothing);
  });

  testWidgets('play button reports taps and pause icon shows while playing', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(host(onTogglePlay: () => taps++));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    expect(taps, 1);

    await tester.pumpWidget(
      host(
        playback: const PttPlaybackState(
          activeId: 'a',
          status: PttPlaybackStatus.playing,
          position: Duration(seconds: 7),
        ),
      ),
    );
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.text('0:07 / 1:05'), findsOneWidget);
  });

  testWidgets('another recording playing leaves this one idle', (tester) async {
    await tester.pumpWidget(
      host(
        playback: const PttPlaybackState(
          activeId: 'zzz',
          status: PttPlaybackStatus.playing,
          position: Duration(seconds: 30),
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('1:05'), findsOneWidget);
    expect(
      tester.widget<PttWaveform>(find.byType(PttWaveform)).onChanged,
      isNull,
    );
  });

  testWidgets('tapping the waveform seeks there', (tester) async {
    Duration? sought;
    await tester.pumpWidget(
      host(
        onSeek: (p) => sought = p,
        playback: const PttPlaybackState(
          activeId: 'a',
          status: PttPlaybackStatus.paused,
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byType(PttWaveform)));
    await tester.pump();

    expect(sought, isNotNull);
    expect(sought!.inSeconds, inInclusiveRange(20, 45));
  });

  testWidgets('options menu is absent unless the viewer may delete', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.byTooltip('Opsi rekaman'), findsNothing);

    await tester.pumpWidget(host(canDelete: true));
    expect(find.byTooltip('Opsi rekaman'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('Opsi rekaman')).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('delete from the menu calls back; inert while deleting', (
    tester,
  ) async {
    var deletes = 0;
    await tester.pumpWidget(host(canDelete: true, onDelete: () => deletes++));
    await tester.tap(find.byTooltip('Opsi rekaman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus rekaman'));
    await tester.pumpAndSettle();
    expect(deletes, 1);

    await tester.pumpWidget(
      host(canDelete: true, isDeleting: true, onDelete: () => deletes++),
    );
    expect(find.byTooltip('Opsi rekaman'), findsNothing);
    expect(find.bySemanticsLabel('Menghapus rekaman'), findsOneWidget);
  });

  const shortText = 'Pos satu aman, tidak ada kejadian.';
  final longText = List.filled(
    12,
    'Ada orang tidak dikenal di gerbang belakang',
  ).join(' ');

  testWidgets('a pending transcript says it is not available yet', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text('Transkrip belum tersedia'), findsOneWidget);

    await tester.pumpWidget(host(transcript: '  '));
    expect(find.text('Transkrip belum tersedia'), findsOneWidget);
  });

  testWidgets('a turn without speech promises no transcript', (tester) async {
    await tester.pumpWidget(host(transcriptStatus: 'no_speech'));

    expect(find.textContaining('Transkrip'), findsNothing);
  });

  testWidgets('short transcript is quoted, with no toggle', (tester) async {
    await tester.pumpWidget(host(transcript: shortText));

    expect(find.text('“$shortText”'), findsOneWidget);
    expect(find.text('Transkrip belum tersedia'), findsNothing);
    expect(find.text('Selengkapnya'), findsNothing);
    expect(
      tester.getRect(find.text('“$shortText”')).top,
      greaterThan(tester.getRect(find.byType(PttWaveform)).bottom),
    );
  });

  testWidgets('long transcript collapses to 3 lines and expands', (
    tester,
  ) async {
    await tester.pumpWidget(host(transcript: longText));

    final quoted = find.text('“$longText”');
    Text body() => tester.widget<Text>(quoted);
    expect(body().maxLines, 3);
    final collapsed = tester.getSize(quoted).height;

    final toggle = find.ancestor(
      of: find.text('Selengkapnya'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));

    await tester.tap(find.text('Selengkapnya'));
    await tester.pump();
    expect(body().maxLines, isNull);
    expect(tester.getSize(quoted).height, greaterThan(collapsed));

    await tester.tap(find.text('Ringkas'));
    await tester.pump();
    expect(body().maxLines, 3);
  });

  for (final dark in [false, true]) {
    testWidgets('320px, 1.5x text, ${dark ? 'dark' : 'light'}: no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          canDelete: true,
          transcript: longText,
          textScale: 1.5,
          waveform: bars,
          duration: const Duration(seconds: 1),
          playback: const PttPlaybackState(
            activeId: 'a',
            status: PttPlaybackStatus.playing,
          ),
          theme: dark ? AppTheme.darkThemeData() : AppTheme.lightThemeData(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('0:00 / 0:01'), findsOneWidget);

      await tester.tap(find.text('Selengkapnya'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dragging the waveform follows the finger and seeks on release', (
    tester,
  ) async {
    final sought = <Duration>[];
    await tester.pumpWidget(
      host(
        onSeek: sought.add,
        playback: const PttPlaybackState(
          activeId: 'a',
          status: PttPlaybackStatus.playing,
        ),
      ),
    );
    final rect = tester.getRect(find.byType(PttWaveform));

    final gesture = await tester.startGesture(
      rect.centerLeft + const Offset(4, 0),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveTo(Offset(rect.left + rect.width * 0.75, rect.center.dy));
    await tester.pump();
    expect(sought, isEmpty, reason: 'nothing is sought mid-drag');
    expect(find.text('0:48 / 1:05'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(sought, hasLength(1));
    expect(sought.single.inSeconds, inInclusiveRange(47, 50));
  });

  testWidgets('TalkBack can step the waveform while it is loaded', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final sought = <Duration>[];
    await tester.pumpWidget(
      host(
        onSeek: sought.add,
        playback: const PttPlaybackState(
          activeId: 'a',
          status: PttPlaybackStatus.paused,
          position: Duration(seconds: 13),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(PttWaveform)),
      matchesSemantics(
        isSlider: true,
        hasEnabledState: true,
        isEnabled: true,
        label: 'Posisi rekaman',
        value: '0:13 dari 1:05',
        increasedValue: '0:19 dari 1:05',
        decreasedValue: '0:06 dari 1:05',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    tester.semantics.increase(find.semantics.byLabel('Posisi rekaman'));
    await tester.pump();
    expect(sought.single.inMilliseconds, closeTo(19500, 50));
    semantics.dispose();
  });

  testWidgets('an idle waveform offers no seek actions', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host());

    expect(
      tester.getSemantics(find.byType(PttWaveform)),
      matchesSemantics(
        isSlider: true,
        hasEnabledState: true,
        label: 'Posisi rekaman',
        value: '0:00 dari 1:05',
      ),
    );
    semantics.dispose();
  });

  group('waveform bars', () {
    test('real values are resampled keeping each slice peak', () {
      final source = Uint8List.fromList([0, 255, 0, 0, 100, 0, 0, 0]);
      expect(PttWaveformPainter.levels(source, 4), [255, 0, 100, 0]);
      expect(PttWaveformPainter.levels(source, 16).toSet(), {0, 100, 255});
    });

    test('a recording without a waveform gets flat neutral bars', () {
      final levels = PttWaveformPainter.levels(null, 30);
      expect(levels, hasLength(30));
      expect(levels.toSet(), {PttWaveform.fallbackLevel});
    });

    test('bar count follows the available width', () {
      expect(PttWaveformPainter.barCountFor(98), 20);
      expect(PttWaveformPainter.barCountFor(0), 1);
    });
  });

  test('clock times use the Indonesian dot', () {
    expect(formatPttClock(DateTime(2026, 11, 13, 7, 5)), '07.05');
  });
}

final bars = Uint8List.fromList(List.generate(48, (i) => (i * 37) % 256));

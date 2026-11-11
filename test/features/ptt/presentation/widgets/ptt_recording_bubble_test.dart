import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_recording_entity.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_recording_bubble.dart';

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
    PttTranscriptSource? source = PttTranscriptSource.server,
    ThemeData? theme,
    double textScale = 1,
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
        // The real screen is a scrolling list; an expanded transcript is tall.
        body: SingleChildScrollView(
          child: PttRecordingBubble(
            recording: recording(
              'a',
              duration: const Duration(seconds: 65),
              transcript: transcript,
              transcriptSource: source,
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

  testWidgets('shows sender, initial, length and time of someone else', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('own turns sit on the right without a name', (tester) async {
    await tester.pumpWidget(host(isMe: true));

    expect(find.text('Budi'), findsNothing);
    final bubble = tester.getRect(find.byType(PttRecordingBubble));
    final inner = tester.getRect(find.byType(Container).first);
    expect(inner.right, bubble.right);
    expect(inner.left, greaterThan(bubble.left));
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
    expect(find.text('0:07'), findsOneWidget);
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
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  testWidgets('dragging the slider seeks on release', (tester) async {
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

    await tester.tapAt(tester.getCenter(find.byType(Slider)));
    await tester.pump();

    expect(sought, isNotNull);
    expect(sought!.inSeconds, inInclusiveRange(25, 40));
  });

  testWidgets('delete button is absent unless the viewer may delete', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text('Hapus'), findsNothing);

    await tester.pumpWidget(host(canDelete: true));
    expect(find.text('Hapus'), findsOneWidget);
    final size = tester.getSize(find.byType(AppButton));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('delete button calls back, and is inert while deleting', (
    tester,
  ) async {
    var deletes = 0;
    await tester.pumpWidget(host(canDelete: true, onDelete: () => deletes++));
    await tester.tap(find.text('Hapus'));
    expect(deletes, 1);

    await tester.pumpWidget(
      host(canDelete: true, isDeleting: true, onDelete: () => deletes++),
    );
    await tester.tap(find.byType(PttRecordingBubble), warnIfMissed: false);
    expect(deletes, 1);
    expect(find.text('Hapus'), findsNothing);
  });

  const shortText = 'Pos satu aman, tidak ada kejadian.';
  final longText = List.filled(
    12,
    'Ada orang tidak dikenal di gerbang belakang',
  ).join(' ');

  testWidgets('no transcript shows nothing extra', (tester) async {
    await tester.pumpWidget(host());

    expect(find.textContaining('Transkrip'), findsNothing);
    expect(find.text('Selengkapnya'), findsNothing);
  });

  testWidgets('blank transcript shows nothing extra', (tester) async {
    await tester.pumpWidget(host(transcript: '  '));

    expect(find.textContaining('Transkrip'), findsNothing);
  });

  testWidgets('short transcript shows label, source hint and no toggle', (
    tester,
  ) async {
    await tester.pumpWidget(host(transcript: shortText));

    expect(find.text('Transkrip otomatis · dari server'), findsOneWidget);
    expect(find.text(shortText), findsOneWidget);
    expect(find.text('Selengkapnya'), findsNothing);
  });

  testWidgets('device source and missing source hints', (tester) async {
    await tester.pumpWidget(
      host(transcript: shortText, source: PttTranscriptSource.device),
    );
    expect(find.text('Transkrip otomatis · dari perangkat'), findsOneWidget);

    await tester.pumpWidget(host(transcript: shortText, source: null));
    expect(find.text('Transkrip otomatis'), findsOneWidget);
  });

  testWidgets('long transcript collapses to 3 lines and expands', (
    tester,
  ) async {
    await tester.pumpWidget(host(transcript: longText));

    Text body() => tester.widget<Text>(find.text(longText));
    expect(body().maxLines, 3);
    expect(find.text('Selengkapnya'), findsOneWidget);
    final collapsed = tester.getSize(find.text(longText)).height;

    final toggle = find.ancestor(
      of: find.text('Selengkapnya'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(toggle).height, greaterThanOrEqualTo(44));

    await tester.tap(find.text('Selengkapnya'));
    await tester.pump();
    expect(body().maxLines, isNull);
    expect(find.text('Ringkas'), findsOneWidget);
    expect(tester.getSize(find.text(longText)).height, greaterThan(collapsed));

    await tester.tap(find.text('Ringkas'));
    await tester.pump();
    expect(body().maxLines, 3);
    expect(find.text('Selengkapnya'), findsOneWidget);
  });

  testWidgets('transcript follows the bubble side', (tester) async {
    await tester.pumpWidget(host(transcript: shortText));
    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    expect(tester.getTopLeft(find.text(shortText)).dx, lessThan(40));

    await tester.pumpWidget(host(isMe: true, transcript: shortText));
    expect(
      tester.getTopRight(find.text(shortText)).dx,
      greaterThan(screenWidth - 40),
    );
  });

  for (final isMe in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets('320px, 1.5x text, ${dark ? 'dark' : 'light'}, '
          '${isMe ? 'own' : 'others'}: no overflow', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          host(
            isMe: isMe,
            canDelete: true,
            transcript: longText,
            textScale: 1.5,
            theme: dark ? AppTheme.darkThemeData() : AppTheme.lightThemeData(),
          ),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Selengkapnya'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

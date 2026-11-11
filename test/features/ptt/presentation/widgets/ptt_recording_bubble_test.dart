import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
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
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: PttRecordingBubble(
          recording: recording('a', duration: const Duration(seconds: 65)),
          isMe: isMe,
          playback: playback,
          canDelete: canDelete,
          isDeleting: isDeleting,
          onTogglePlay: onTogglePlay ?? () {},
          onSeek: onSeek ?? (_) {},
          onDelete: onDelete,
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
}

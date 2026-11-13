import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_recording_bubble.dart';
import 'package:kawalo_mobile/features/ptt/presentation/widgets/ptt_waveform.dart';

import '../../ptt_recording_fixtures.dart';

/// The bubble and, with a transcript, its inset card: the rounded surfaces.
/// The avatar's circle is a Container too but has no border radius.
final Finder surfaces = find.descendant(
  of: find.byType(PttRecordingBubble),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).borderRadius != null,
  ),
);

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
    ThemeData? theme,
    double textScale = 1,
    Duration duration = const Duration(seconds: 65),
    String role = 'GUARD',
    Uint8List? waveform,
    bool isFirstInGroup = true,
    bool isLastInGroup = true,
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
              duration: duration,
              transcript: transcript,
              role: role,
              waveform: waveform,
            ),
            isMe: isMe,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
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
    final inner = tester.getRect(surfaces.first);
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

  testWidgets('short transcript shows only its text and no toggle', (
    tester,
  ) async {
    await tester.pumpWidget(host(transcript: shortText));

    expect(find.textContaining('Transkrip'), findsNothing);
    expect(find.text(shortText), findsOneWidget);
    expect(find.text('Selengkapnya'), findsNothing);
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

  for (final isMe in [false, true]) {
    testWidgets('${isMe ? 'own' : 'others'} transcript sits inside the card, '
        'below the time row', (tester) async {
      await tester.pumpWidget(host(isMe: isMe, transcript: shortText));

      final card = tester.getRect(surfaces.first);
      final text = tester.getRect(find.text(shortText));
      expect(card.contains(text.topLeft), isTrue);
      expect(card.contains(text.bottomRight), isTrue);
      expect(text.top, greaterThan(tester.getRect(find.text('09:30')).bottom));
    });
  }

  for (final isMe in [false, true]) {
    testWidgets('${isMe ? 'own' : 'others'} transcript is quoted: audio sits '
        'in an inset card, the text below it, one bubble', (tester) async {
      Iterable<Widget> containers() => tester.widgetList(surfaces);

      await tester.pumpWidget(host(isMe: isMe));
      final withoutText = containers().length;

      await tester.pumpWidget(host(isMe: isMe, transcript: shortText));
      expect(containers().length, withoutText + 1);

      final bubble = tester.getRect(surfaces.first);
      final card = tester.getRect(surfaces.at(1));
      final text = tester.getRect(find.text(shortText));
      final slider = tester.getRect(find.byType(PttWaveform));

      expect(bubble.contains(card.topLeft), isTrue);
      expect(bubble.contains(card.bottomRight), isTrue);
      expect(card.contains(slider.center), isTrue);
      expect(card.overlaps(text), isFalse);
      expect(text.top, greaterThanOrEqualTo(card.bottom));
      expect(bubble.contains(text.bottomRight), isTrue);
    });
  }

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
            role: 'ADMIN',
            waveform: bars,
            theme: dark ? AppTheme.darkThemeData() : AppTheme.lightThemeData(),
          ),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Selengkapnya'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('320px, 1.5x text, ${dark ? 'dark' : 'light'}, '
          '${isMe ? 'own' : 'others'}, shortest clip while playing: '
          'no overflow', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          host(
            isMe: isMe,
            canDelete: true,
            textScale: 1.5,
            role: 'SUPER_ADMIN',
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
      });
    }
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

    final node = tester.getSemantics(find.byType(PttWaveform));
    expect(
      node,
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

  testWidgets('bubble width grows with the clip; a transcript takes the most', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    double width() => tester.getSize(surfaces.first).width;

    await tester.pumpWidget(host(duration: const Duration(seconds: 2)));
    final short = width();
    await tester.pumpWidget(host(duration: const Duration(seconds: 12)));
    final medium = width();
    await tester.pumpWidget(host(duration: const Duration(seconds: 30)));
    final long = width();
    await tester.pumpWidget(
      host(duration: const Duration(seconds: 2), transcript: shortText),
    );
    final quoted = width();

    expect(short, greaterThanOrEqualTo(PttRecordingBubble.minWidth));
    expect(short, lessThan(medium));
    expect(medium, lessThan(long));
    expect(quoted, long);
  });

  testWidgets('later turns of a group drop the name and avatar', (
    tester,
  ) async {
    await tester.pumpWidget(host(isFirstInGroup: false));

    expect(find.text('Budi'), findsNothing);
    expect(find.text('B'), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('admin speakers get no extra role label', (tester) async {
    await tester.pumpWidget(host(role: 'ADMIN'));

    expect(find.text('Budi'), findsOneWidget);
    expect(find.textContaining('Admin'), findsNothing);
  });
}

final bars = Uint8List.fromList(List.generate(48, (i) => (i * 37) % 256));

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_playback_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_recordings_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_recordings_state.dart';
import 'package:kawalo_mobile/features/ptt/presentation/screens/ptt_history_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_recording_fixtures.dart';

class MockRecordingsCubit extends MockCubit<PttRecordingsState>
    implements PttRecordingsCubit {}

class MockPlaybackCubit extends MockCubit<PttPlaybackState>
    implements PttPlaybackCubit {}

void main() {
  late MockRecordingsCubit recordings;
  late MockPlaybackCubit playback;

  setUp(() {
    recordings = MockRecordingsCubit();
    playback = MockPlaybackCubit();
    when(() => playback.state).thenReturn(const PttPlaybackState());
    when(() => recordings.load()).thenAnswer((_) async {});
    when(() => recordings.refresh()).thenAnswer((_) async {});
    when(() => recordings.loadMore()).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    PttRecordingsState state, {
    AuthSessionEntity? user,
  }) async {
    when(() => recordings.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PttRecordingsCubit>.value(value: recordings),
            BlocProvider<PttPlaybackCubit>.value(value: playback),
            BlocProvider<UserSessionCubit>.value(value: UserSessionCubit(user)),
          ],
          child: const PttHistoryScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  PttRecordingsState loaded() {
    final now = DateTime.now();
    return PttRecordingsState(
      status: PttRecordingsStatus.loaded,
      items: [
        recording('a', email: 'admin@kawalo.id', name: 'Saya', startedAt: now),
        recording(
          'b',
          startedAt: DateTime(now.year, now.month, now.day - 1, 12),
        ),
      ],
    );
  }

  testWidgets('empty history reads "Belum ada rekaman"', (tester) async {
    await pump(
      tester,
      const PttRecordingsState(status: PttRecordingsStatus.loaded),
      user: session(),
    );

    expect(find.text('Belum ada rekaman'), findsOneWidget);
    expect(
      find.text('Setiap giliran bicara di kanal ini tersimpan di sini.'),
      findsOneWidget,
    );
  });

  testWidgets('error state offers a retry that reloads', (tester) async {
    await pump(
      tester,
      const PttRecordingsState(
        status: PttRecordingsStatus.failure,
        errorMessage: 'Tidak ada koneksi.',
      ),
      user: session(),
    );

    expect(find.text('Tidak ada koneksi.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    verify(() => recordings.load()).called(1);
  });

  testWidgets('non-admins see rows under day labels but no delete', (
    tester,
  ) async {
    await pump(tester, loaded(), user: session());

    expect(find.text('Budi'), findsOneWidget);
    // The signed-in user's own turn.
    expect(find.text('Anda'), findsOneWidget);
    expect(find.byTooltip('Opsi rekaman'), findsNothing);
    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('KEMARIN'), findsOneWidget);
  });

  testWidgets('reads like a chat: oldest on top, newest at the bottom', (
    tester,
  ) async {
    await pump(tester, loaded(), user: session());

    final yesterday = tester.getRect(find.text('KEMARIN')).top;
    final older = tester.getRect(find.text('Budi')).top;
    final today = tester.getRect(find.text('HARI INI')).top;
    final mine = tester.getRect(find.text('Anda')).top;
    expect(yesterday, lessThan(older));
    expect(older, lessThan(today));
    expect(today, lessThan(mine));
  });

  testWidgets('day labels are centered pills with their own background', (
    tester,
  ) async {
    await pump(tester, loaded(), user: session());

    final screen = tester.getRect(find.byType(PttHistoryScreen));
    for (final label in ['HARI INI', 'KEMARIN']) {
      final pill = find.ancestor(
        of: find.text(label),
        matching: find.byType(DecoratedBox),
      );
      final box = tester.widget<DecoratedBox>(pill.first);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, KawaloTones.light.ptt.soft);
      expect(decoration.borderRadius, BorderRadius.circular(999));
      expect(tester.getCenter(pill.first).dx, closeTo(screen.center.dx, 0.5));
    }
  });

  testWidgets('own turns sit on the right without an avatar, others left', (
    tester,
  ) async {
    await pump(tester, loaded(), user: session());

    final screen = tester.getRect(find.byType(PttHistoryScreen));
    Rect bubble(String id) => tester.getRect(
      find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    final mine = bubble('a');
    final theirs = bubble('b');
    expect(mine.right, screen.right - 16);
    expect(theirs.left, screen.left + 16);
    expect(mine.left, greaterThan(theirs.left));
    expect(theirs.right, lessThan(mine.right));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('a')),
        matching: find.byType(AppUserAvatar),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('b')),
        matching: find.byType(AppUserAvatar),
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens at the newest turn and loads older pages at the top', (
    tester,
  ) async {
    final base = DateTime.now();
    await pump(
      tester,
      PttRecordingsState(
        status: PttRecordingsStatus.loaded,
        // Newest first, as the cubit serves them.
        items: [
          for (var i = 0; i < 14; i++)
            recording(
              'r$i',
              name: 'Orang $i',
              startedAt: base.subtract(Duration(seconds: i)),
            ),
        ],
        nextBefore: 'c1',
      ),
      user: session(),
    );

    expect(find.text('Orang 0'), findsOneWidget, reason: 'newest is visible');
    expect(find.text('Orang 13'), findsNothing, reason: 'oldest is off-screen');
    verifyNever(() => recordings.loadMore());

    await tester.drag(find.byType(ListView), const Offset(0, 1500));
    await tester.pump();

    verify(() => recordings.loadMore()).called(greaterThan(0));
  });

  testWidgets('a GUARD with allowAdmin still cannot delete', (tester) async {
    await pump(tester, loaded(), user: session(allowAdmin: true));

    expect(find.byTooltip('Opsi rekaman'), findsNothing);
  });

  testWidgets('admins get an options menu per recording', (tester) async {
    await pump(tester, loaded(), user: session(admin: true));

    expect(find.byTooltip('Opsi rekaman'), findsNWidgets(2));
  });

  Future<void> openDelete(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Opsi rekaman').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus rekaman'));
    await tester.pumpAndSettle();
  }

  testWidgets('confirming names the effect and then deletes', (tester) async {
    when(() => playback.stopIfActive(any())).thenAnswer((_) async {});
    when(
      () => recordings.delete(any(), session: any(named: 'session')),
    ).thenAnswer((_) async => true);
    await pump(tester, loaded(), user: session(admin: true));

    await openDelete(tester);

    expect(find.text('Hapus rekaman ini?'), findsOneWidget);
    expect(
      find.textContaining('Rekaman Saya pukul'),
      findsOneWidget,
      reason: 'names who, when and how long',
    );
    expect(
      find.textContaining(
        'dihapus untuk semua anggota. Tidak bisa '
        'dibatalkan.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    verify(() => playback.stopIfActive('a')).called(1);
    verify(
      () => recordings.delete('a', session: any(named: 'session')),
    ).called(1);
  });

  testWidgets('cancelling the dialog deletes nothing', (tester) async {
    await pump(tester, loaded(), user: session(admin: true));

    await openDelete(tester);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => recordings.delete(any(), session: any(named: 'session')));
  });
}

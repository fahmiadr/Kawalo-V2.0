import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
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

  testWidgets('non-admins see bubbles and date separators but no delete', (
    tester,
  ) async {
    await pump(tester, loaded(), user: session());

    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Hapus'), findsNothing);
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Kemarin'), findsOneWidget);
  });

  testWidgets('admins see a delete button per recording', (tester) async {
    await pump(tester, loaded(), user: session(admin: true));

    expect(find.text('Hapus'), findsNWidgets(2));
  });

  testWidgets('confirming names the effect and then deletes', (tester) async {
    when(() => playback.stopIfActive(any())).thenAnswer((_) async {});
    when(
      () => recordings.delete(any(), session: any(named: 'session')),
    ).thenAnswer((_) async => true);
    await pump(tester, loaded(), user: session(admin: true));

    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();

    expect(find.text('Hapus Rekaman?'), findsOneWidget);
    expect(find.textContaining('semua anggota grup'), findsOneWidget);

    await tester.tap(find.text('Hapus Rekaman'));
    await tester.pumpAndSettle();

    verify(
      () => recordings.delete('a', session: any(named: 'session')),
    ).called(1);
  });

  testWidgets('cancelling the dialog deletes nothing', (tester) async {
    await pump(tester, loaded(), user: session(admin: true));

    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => recordings.delete(any(), session: any(named: 'session')));
  });
}

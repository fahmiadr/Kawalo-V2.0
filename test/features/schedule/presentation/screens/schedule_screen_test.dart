import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:kawalo_mobile/features/schedule/presentation/widgets/schedule_card.dart';
import 'package:kawalo_mobile/features/schedule/presentation/widgets/schedule_card_skeleton.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleCubit extends MockCubit<ScheduleState>
    implements ScheduleCubit {}

ScheduleEntity _shift(
  String id,
  DateTime date, {
  String name = 'Shift Pagi',
  String? location,
}) => ScheduleEntity(
  id: id,
  date: date,
  shiftName: name,
  startTime: '08:00',
  endTime: '16:00',
  shiftColor: '#10B981',
  locationName: location,
);

void main() {
  late _MockScheduleCubit cubit;
  final now = DateTime(2026, 6, 30, 7);

  setUp(() {
    cubit = _MockScheduleCubit();
    when(
      () => cubit.fetch(silent: any(named: 'silent')),
    ).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester, ScheduleState state) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<ScheduleState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: ScheduleScreen(cubit: cubit, clock: () => now),
      ),
    );
    await tester.pump();
  }

  testWidgets('loads on open and shows skeletons while loading', (
    tester,
  ) async {
    await pump(tester, const ScheduleLoading());

    verify(() => cubit.fetch()).called(1);
    expect(find.byType(ScheduleCardSkeleton), findsWidgets);
  });

  testWidgets('empty state', (tester) async {
    await pump(tester, const ScheduleLoaded([]));

    expect(find.text('Belum ada jadwal'), findsOneWidget);
  });

  testWidgets('error state retries', (tester) async {
    await pump(tester, const ScheduleError('Tidak ada koneksi.'));

    expect(find.text('Gagal memuat jadwal kerja'), findsOneWidget);
    expect(find.text('Tidak ada koneksi.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    // One call on open, one for the retry.
    verify(() => cubit.fetch()).called(2);
  });

  testWidgets('groups shifts under a day header with details', (tester) async {
    await pump(
      tester,
      ScheduleLoaded([
        _shift('1', DateTime(2026, 6, 30), location: 'Pos 1'),
        _shift('2', DateTime(2026, 6, 30), name: 'Shift Siang'),
        _shift('3', DateTime(2026, 7, 2)),
      ]),
    );

    expect(find.text('Hari ini · Selasa, 30 Jun 2026'), findsOneWidget);
    expect(find.text('Kamis, 2 Jul 2026'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsNWidgets(3));
    expect(find.text('Pos 1'), findsOneWidget);
    expect(find.text('Shift Siang'), findsOneWidget);
    expect(find.text('08:00-16:00'), findsNWidgets(3));
    expect(
      find.byKey(const ValueKey('schedule_shift_marker')),
      findsNWidgets(3),
    );
  });

  testWidgets('pull-to-refresh refreshes silently through the cubit', (
    tester,
  ) async {
    await pump(tester, ScheduleLoaded([_shift('1', DateTime(2026, 6, 30))]));

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    verify(() => cubit.fetch(silent: true)).called(1);
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_shortcuts_section.dart';
import 'package:kawalo_mobile/features/schedule/domain/entities/schedule_entity.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:kawalo_mobile/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:kawalo_mobile/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleCubit extends MockCubit<ScheduleState>
    implements ScheduleCubit {}

ScheduleEntity _shift(DateTime date) => ScheduleEntity(
  id: '$date',
  date: date,
  shiftName: 'Shift Pagi',
  startTime: '00:00',
  endTime: '23:59',
);

void main() {
  late _MockScheduleCubit cubit;

  setUp(() {
    cubit = _MockScheduleCubit();
    when(
      () => cubit.fetch(silent: any(named: 'silent')),
    ).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester, ScheduleState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      BlocProvider<ScheduleCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: SingleChildScrollView(child: HomeShortcutsSection()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  DateTime day(int offset) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + offset);
  }

  group('Jadwal Kerja shortcut subtitle', () {
    testWidgets('today', (tester) async {
      await pump(tester, ScheduleLoaded([_shift(day(0))]));
      expect(find.text('Hari ini · 00:00-23:59'), findsOneWidget);
    });

    testWidgets('tomorrow', (tester) async {
      await pump(tester, ScheduleLoaded([_shift(day(1))]));
      expect(find.text('Besok · 00:00-23:59'), findsOneWidget);
    });

    testWidgets('a later day shows a short date', (tester) async {
      await pump(tester, ScheduleLoaded([_shift(day(5))]));
      expect(
        find.textContaining(RegExp(r'^\d{1,2} \w{3} · 00:00-23:59$')),
        findsOneWidget,
      );
    });

    testWidgets('no schedule', (tester) async {
      await pump(tester, const ScheduleLoaded([]));
      expect(find.text('Belum ada jadwal'), findsOneWidget);
    });

    testWidgets('loading and error leave the card without a subtitle', (
      tester,
    ) async {
      await pump(tester, const ScheduleLoading());
      expect(find.text('Jadwal Kerja'), findsOneWidget);
      expect(find.text('Belum ada jadwal'), findsNothing);

      await pump(tester, const ScheduleError('x'));
      expect(find.text('Jadwal Kerja'), findsOneWidget);
      expect(find.text('Belum ada jadwal'), findsNothing);
    });

    testWidgets('tapping opens the schedule screen', (tester) async {
      await pump(tester, const ScheduleLoaded([]));

      await tester.tap(find.text('Jadwal Kerja'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ScheduleScreen), findsOneWidget);
    });
  });
}

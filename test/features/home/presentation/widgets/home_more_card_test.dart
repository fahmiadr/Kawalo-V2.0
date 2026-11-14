import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_slot.dart';
import 'package:kawalo_mobile/features/home/presentation/cubit/home_attendance_cubit.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_more_card.dart';
import 'package:mocktail/mocktail.dart';

class _MockCubit extends MockCubit<HomeAttendanceState>
    implements HomeAttendanceCubit {}

final _slot = AttendanceSlot(
  date: DateTime(2026, 11, 13),
  shiftName: 'Shift Pagi',
  startTime: '07:00',
  endTime: '15:00',
  locationName: 'Pos Utama',
  checkin: '06:52:10',
  checkout: '15:03:00',
);

void main() {
  Future<void> pump(WidgetTester tester, HomeAttendanceState state) async {
    final cubit = _MockCubit();
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: BlocProvider<HomeAttendanceCubit>.value(
            value: cubit,
            child: HomeMoreCard(onArrange: () {}),
          ),
        ),
      ),
    );
  }

  testWidgets('check-in state', (tester) async {
    await pump(
      tester,
      HomeAttendanceLoaded(AttendancePlan.act(_slot, AttendanceAction.checkIn)),
    );
    expect(find.text('Shift Pagi 07.00–15.00'), findsOneWidget);
    expect(find.text('Check-in dengan Wajah'), findsOneWidget);
    expect(find.text('Titik absen: Pos Utama'), findsOneWidget);
  });

  testWidgets('check-out state', (tester) async {
    await pump(
      tester,
      HomeAttendanceLoaded(
        AttendancePlan.act(_slot, AttendanceAction.checkOut),
      ),
    );
    expect(find.text('Check-out dengan Wajah'), findsOneWidget);
    expect(find.text('Masuk 06.52 · pulang setelah 15.00'), findsOneWidget);
  });

  testWidgets('done and no-schedule states', (tester) async {
    await pump(tester, HomeAttendanceLoaded(AttendancePlan.completed(_slot)));
    expect(find.text('Absensi hari ini selesai'), findsOneWidget);
    expect(find.text('Masuk 06.52 · Pulang 15.03'), findsOneWidget);

    await pump(tester, const HomeAttendanceLoaded(AttendancePlan.noSchedule()));
    expect(find.text('Tidak ada jadwal hari ini'), findsOneWidget);
    expect(find.text('Tidak ada jadwal'), findsOneWidget);
  });

  testWidgets('lists the nine feature tiles', (tester) async {
    await pump(tester, const HomeAttendanceFailed());
    for (final label in [
      'Buku Tamu',
      'Jadwal',
      'Informasi',
      'Riwayat PTT',
      'Riwayat Absen',
      'Operasional',
      'Personil',
      'Akun',
      'Atur Beranda',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });
}

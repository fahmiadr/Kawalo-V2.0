import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/guest/presentation/screens/guest_detail_screen.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_recent_guests_card.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_recent_guests_section.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_screen_cubits.dart';

/// [count] guests named `Tamu 01..`, where a higher number is more recent.
List<GuestItemEntity> _guests(int count) => [
  for (var i = 1; i <= count; i++)
    GuestItemEntity(
      id: 'g$i',
      guestName: 'Tamu ${i.toString().padLeft(2, '0')}',
      guestDestination: 'Pos $i',
      guestDt: '2026-07-${i.toString().padLeft(2, '0')}T10:00:00',
    ),
];

void main() {
  late MockGuestCubit cubit;

  setUp(() {
    cubit = MockGuestCubit();
    when(cubit.fetchGuests).thenAnswer((_) async => AppFetchResult.success);
    when(() => cubit.currentGreeting).thenReturn('');
  });

  Widget build() {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: BlocProvider<GuestCubit>.value(
        value: cubit,
        child: const Scaffold(
          body: SingleChildScrollView(child: HomeRecentGuestsSection()),
        ),
      ),
    );
  }

  group('buildRecentGuestPages', () {
    test('keeps the 12 newest guests, newest first, three per page', () {
      final pages = buildRecentGuestPages(_guests(15));

      expect(pages, hasLength(4));
      expect(pages.every((p) => p.length == 3), isTrue);
      expect(pages.first.map((i) => i.identifier), [
        'Tamu 15',
        'Tamu 14',
        'Tamu 13',
      ]);
      expect(pages.last.last.identifier, 'Tamu 04');
    });

    test('puts a trailing partial page last and tolerates bad dates', () {
      final pages = buildRecentGuestPages([
        const GuestItemEntity(id: 'x', guestName: 'Tanpa Tanggal'),
        ..._guests(3),
      ]);

      expect(pages, hasLength(2));
      expect(pages.last.single.identifier, 'Tanpa Tanggal');
    });

    test('is empty without guests', () {
      expect(buildRecentGuestPages(const []), isEmpty);
    });
  });

  group('HomeRecentGuestsSection', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      when(() => cubit.state).thenReturn(const GuestLoading());

      await tester.pumpWidget(build());

      expect(find.bySemanticsLabel('Memuat tamu terakhir'), findsOneWidget);
      expect(find.text('Belum ada data tamu.'), findsNothing);
    });

    testWidgets('shows an empty message without guests', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const GuestLoaded(guests: [], lastSync: ''));

      await tester.pumpWidget(build());

      expect(find.text('Belum ada data tamu.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsNothing);
    });

    testWidgets('shows the error with a working retry button', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const GuestError(message: 'Server tidak merespons.'));

      await tester.pumpWidget(build());

      expect(find.text('Server tidak merespons.'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      verify(cubit.fetchGuests).called(1);
    });

    testWidgets('shows real guests: identity, destination and time', (
      tester,
    ) async {
      when(
        () => cubit.state,
      ).thenReturn(GuestLoaded(guests: _guests(5), lastSync: ''));

      await tester.pumpWidget(build());

      expect(find.text('Tamu 05'), findsOneWidget);
      expect(find.text('Pos 5'), findsOneWidget);
      expect(find.text('05 Jul 2026 10:00'), findsOneWidget);
      expect(find.text('Data tersimpan'), findsNothing);
    });

    testWidgets('pages through the 12 newest guests only', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(GuestLoaded(guests: _guests(15), lastSync: ''));

      await tester.pumpWidget(build());
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pumpAndSettle();
      }

      expect(find.text('Tamu 04'), findsOneWidget);
      expect(find.text('Tamu 03'), findsNothing);
    });

    testWidgets('marks cached data while offline', (tester) async {
      when(() => cubit.state).thenReturn(
        GuestLoaded(guests: _guests(2), lastSync: '', isFromCache: true),
      );

      await tester.pumpWidget(build());

      expect(find.text('Data tersimpan'), findsOneWidget);
    });

    testWidgets('keeps cached guests visible when a refresh failed', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(
        GuestError(
          message: 'Gagal',
          failure: const ServerFailure(),
          cachedGuests: _guests(2),
        ),
      );

      await tester.pumpWidget(build());

      expect(find.text('Tamu 02'), findsOneWidget);
      expect(find.text('Gagal'), findsNothing);
    });

    testWidgets('tapping a guest opens its detail screen', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(GuestLoaded(guests: _guests(3), lastSync: ''));

      await tester.pumpWidget(build());
      await tester.tap(find.text('Tamu 03'));
      await tester.pumpAndSettle();

      final screen = tester.widget<GuestDetailScreen>(
        find.byType(GuestDetailScreen),
      );
      expect(screen.item.id, 'g3');
      expect(screen.cubit, same(cubit));
    });

    testWidgets('renders the empty state without a GuestCubit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(body: HomeRecentGuestsSection()),
        ),
      );

      expect(find.text('Belum ada data tamu.'), findsOneWidget);
    });
  });
}

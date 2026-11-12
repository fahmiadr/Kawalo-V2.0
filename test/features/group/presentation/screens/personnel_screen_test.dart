import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/presentation/cubit/personnel_cubit.dart';
import 'package:kawalo_mobile/features/group/presentation/cubit/personnel_state.dart';
import 'package:kawalo_mobile/features/group/presentation/screens/personnel_screen.dart';
import 'package:kawalo_mobile/features/group/presentation/widgets/personnel_card.dart';
import 'package:kawalo_mobile/features/group/presentation/widgets/personnel_card_skeleton.dart';
import 'package:mocktail/mocktail.dart';

class _MockPersonnelCubit extends MockCubit<PersonnelState>
    implements PersonnelCubit {}

void main() {
  late _MockPersonnelCubit cubit;

  setUp(() {
    cubit = _MockPersonnelCubit();
    when(
      () => cubit.fetch(silent: any(named: 'silent')),
    ).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester, PersonnelState state) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<PersonnelState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: PersonnelScreen(cubit: cubit),
      ),
    );
    await tester.pump();
  }

  testWidgets('loads on open and shows skeletons while loading', (
    tester,
  ) async {
    await pump(tester, const PersonnelLoading());

    verify(() => cubit.fetch()).called(1);
    expect(find.byType(PersonnelCardSkeleton), findsWidgets);
  });

  testWidgets('lists name and email, falling back to the email', (
    tester,
  ) async {
    await pump(
      tester,
      const PersonnelLoaded([
        GroupMemberEntity(email: 'budi@test.id', name: 'Budi'),
        GroupMemberEntity(email: 'tanpa@test.id'),
        GroupMemberEntity(email: 'kosong@test.id', name: '  '),
      ]),
    );

    expect(find.byType(PersonnelCard), findsNWidgets(3));
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('budi@test.id'), findsOneWidget);
    // Without a name the email is the title and is not repeated.
    expect(find.text('tanpa@test.id'), findsOneWidget);
    expect(find.text('kosong@test.id'), findsOneWidget);
    // Initial avatar fallback.
    expect(find.text('B'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    await pump(tester, const PersonnelLoaded([]));

    expect(find.text('Belum ada personil'), findsOneWidget);
  });

  testWidgets('error state retries', (tester) async {
    await pump(tester, const PersonnelError('Tidak ada koneksi.'));

    expect(find.text('Gagal memuat daftar personil'), findsOneWidget);
    expect(find.text('Tidak ada koneksi.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    // One call on open, one for the retry.
    verify(() => cubit.fetch()).called(2);
  });

  testWidgets('pull-to-refresh refetches silently', (tester) async {
    await pump(
      tester,
      const PersonnelLoaded([GroupMemberEntity(email: 'a@test.id', name: 'A')]),
    );

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    verify(() => cubit.fetch(silent: true)).called(1);
  });

  testWidgets('a failed refresh tells the user', (tester) async {
    when(() => cubit.fetch(silent: true)).thenAnswer((_) async => false);
    await pump(
      tester,
      const PersonnelLoaded([GroupMemberEntity(email: 'a@test.id', name: 'A')]),
    );

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Gagal memperbarui daftar personil.'), findsOneWidget);
  });

  const people = PersonnelLoaded([
    GroupMemberEntity(email: 'budi@test.id', name: 'Budi Santoso'),
    GroupMemberEntity(email: 'siti@test.id', name: 'Siti'),
    GroupMemberEntity(email: 'tanpa@kantor.id'),
  ]);

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(EditableText), query);
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('search filters by name, case-insensitive', (tester) async {
    await pump(tester, people);

    await search(tester, 'BUDI');

    expect(find.byType(PersonnelCard), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('search filters by email', (tester) async {
    await pump(tester, people);

    await search(tester, 'kantor');

    expect(find.byType(PersonnelCard), findsOneWidget);
    expect(find.text('tanpa@kantor.id'), findsOneWidget);
  });

  testWidgets('search without a match shows the not-found state', (
    tester,
  ) async {
    await pump(tester, people);

    await search(tester, 'zzz');

    expect(find.byType(PersonnelCard), findsNothing);
    expect(find.text('Personil tidak ditemukan'), findsOneWidget);

    await search(tester, '');
    expect(find.byType(PersonnelCard), findsNWidgets(3));
  });

  testWidgets('the empty group has no search field', (tester) async {
    await pump(tester, const PersonnelLoaded([]));

    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('cards use the shared avatar with the initial fallback', (
    tester,
  ) async {
    await pump(
      tester,
      const PersonnelLoaded([
        GroupMemberEntity(
          email: 'budi@test.id',
          name: 'Budi',
          profilePic: 'bukan-url',
        ),
      ]),
    );

    expect(find.byType(AppUserAvatar), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}

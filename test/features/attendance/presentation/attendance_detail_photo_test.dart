import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/attendance/domain/entities/attendance_item_entity.dart';
import 'package:kawalo_mobile/features/attendance/photo/authenticated_photo_fetcher.dart';
import 'package:kawalo_mobile/features/attendance/presentation/widgets/attendance_detail_bottom_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockPhotoFetcher extends Mock implements AuthenticatedPhotoFetcher {}

AuthSessionEntity _session(String role) => AuthSessionEntity(
  userId: '1',
  email: 'a@kawalo.id',
  name: 'A',
  role: role,
  allowAdmin: false,
  allowPatrol: true,
  allowMonPatrol: false,
);

AttendanceItemEntity _item({
  bool? hasPhoto,
  bool? faceVerified,
  int? similarity,
}) => AttendanceItemEntity(
  id: '9',
  category: 'MASUK',
  diffMinutes: 0,
  userName: 'Siti',
  hasPhoto: hasPhoto,
  faceVerified: faceVerified,
  faceSimilarityPercent: similarity,
);

void main() {
  late MockPhotoFetcher fetcher;

  setUp(() => fetcher = MockPhotoFetcher());

  Future<void> pump(
    WidgetTester tester, {
    required String role,
    required AttendanceItemEntity item,
  }) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider<UserSessionCubit>.value(
        value: UserSessionCubit(_session(role)),
        child: M3EMaterialApp(
          data: AppTheme.m3eLight(),
          home: Scaffold(
            body: AttendanceDetailBottomSheet(
              item: item,
              photoFetcher: fetcher,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('admin with a stored photo can open it', (tester) async {
    when(
      () => fetcher.fetch(any(), name: any(named: 'name')),
    ).thenAnswer((_) async => const Left(ServerFailure('Foto tidak ada.')));

    await pump(tester, role: 'ADMIN', item: _item(hasPhoto: true));
    await tester.tap(find.text('Lihat foto'));
    await tester.pump();

    verify(
      () => fetcher.fetch('/v1/attendance/9/photo', name: 'attendance_9'),
    ).called(1);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('guard never sees the photo button', (tester) async {
    await pump(tester, role: 'GUARD', item: _item(hasPhoto: true));
    expect(find.text('Lihat foto'), findsNothing);
  });

  testWidgets('no button when the row has no photo or the flag is unknown', (
    tester,
  ) async {
    await pump(tester, role: 'ADMIN', item: _item(hasPhoto: false));
    expect(find.text('Lihat foto'), findsNothing);
    await pump(tester, role: 'ADMIN', item: _item());
    expect(find.text('Lihat foto'), findsNothing);
  });

  testWidgets('face verification row follows faceVerified', (tester) async {
    await pump(tester, role: 'GUARD', item: _item(faceVerified: false));
    expect(find.text('Tidak terverifikasi'), findsOneWidget);
    await pump(tester, role: 'GUARD', item: _item(faceVerified: true));
    expect(find.text('Terverifikasi'), findsOneWidget);
    await pump(tester, role: 'GUARD', item: _item());
    expect(find.text('Verifikasi wajah'), findsNothing);
  });

  testWidgets('similarity row is admin-only and hidden when null', (
    tester,
  ) async {
    await pump(
      tester,
      role: 'ADMIN',
      item: _item(faceVerified: true, similarity: 87),
    );
    expect(find.text('Kemiripan wajah 87%'), findsOneWidget);

    await pump(tester, role: 'ADMIN', item: _item(faceVerified: true));
    expect(find.textContaining('Kemiripan'), findsNothing);

    await pump(
      tester,
      role: 'GUARD',
      item: _item(faceVerified: true, similarity: 87),
    );
    expect(find.textContaining('Kemiripan'), findsNothing);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/entities/manual_request_entity.dart';
import 'package:kawalo_mobile/features/attendance_admin/domain/repositories/attendance_admin_repository.dart';
import 'package:kawalo_mobile/features/attendance_admin/presentation/cubit/manual_requests_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockRepository extends Mock implements AttendanceAdminRepository {}

void main() {
  late MockRepository repository;
  late ManualRequestsCubit cubit;

  setUpAll(() => registerFallbackValue(ManualRequestStatus.pending));

  setUp(() {
    repository = MockRepository();
    cubit = ManualRequestsCubit(repository: repository, pageSize: 2);
  });
  tearDown(() => cubit.close());

  void stubList(
    ManualRequestStatus status,
    int offset,
    List<ManualRequestEntity> items,
  ) => when(
    () =>
        repository.getManualRequests(status: status, limit: 2, offset: offset),
  ).thenAnswer((_) async => Right(items));

  test('loads the first page and knows there may be more', () async {
    stubList(ManualRequestStatus.pending, 0, [
      manualRequest(),
      manualRequest(id: '6'),
    ]);

    await cubit.load();

    expect(cubit.state.phase, ManualRequestsPhase.loaded);
    expect(cubit.state.items.map((i) => i.id), ['5', '6']);
    expect(cubit.state.hasMore, isTrue);
  });

  test('switching tab lists that status', () async {
    stubList(ManualRequestStatus.rejected, 0, [
      manualRequest(status: ManualRequestStatus.rejected),
    ]);

    await cubit.load(status: ManualRequestStatus.rejected);

    expect(cubit.state.status, ManualRequestStatus.rejected);
    expect(cubit.state.items.single.status, ManualRequestStatus.rejected);
    expect(cubit.state.hasMore, isFalse);
  });

  test('loadMore appends the next page', () async {
    stubList(ManualRequestStatus.pending, 0, [
      manualRequest(),
      manualRequest(id: '6'),
    ]);
    stubList(ManualRequestStatus.pending, 2, [manualRequest(id: '7')]);

    await cubit.load();
    await cubit.loadMore();

    expect(cubit.state.items.map((i) => i.id), ['5', '6', '7']);
    expect(cubit.state.hasMore, isFalse);
  });

  test('a failed first load shows the failure', () async {
    when(
      () => repository.getManualRequests(
        status: any(named: 'status'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('Gagal memuat')));

    await cubit.load();

    expect(cubit.state.phase, ManualRequestsPhase.failure);
    expect(cubit.state.errorMessage, 'Gagal memuat');
  });

  group('decide', () {
    setUp(() async {
      stubList(ManualRequestStatus.pending, 0, [manualRequest()]);
      await cubit.load();
    });

    test('approval removes the request and sends the note', () async {
      when(
        () => repository.decideManualRequest(
          id: '5',
          approve: true,
          note: 'Silakan',
        ),
      ).thenAnswer((_) async => const Right(null));

      final done = await cubit.decide(
        request: manualRequest(),
        approve: true,
        note: ' Silakan ',
        session: session('ADMIN'),
      );

      expect(done, isTrue);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.decidingIds, isEmpty);
      expect(cubit.state.notice, contains('disetujui'));
    });

    test('a server refusal keeps the request and reports it', () async {
      when(
        () => repository.decideManualRequest(
          id: any(named: 'id'),
          approve: any(named: 'approve'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(ServerFailure('Permintaan ini sudah diputuskan.')),
      );

      final done = await cubit.decide(
        request: manualRequest(),
        approve: false,
        session: session('ADMIN'),
      );

      expect(done, isFalse);
      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.decidingIds, isEmpty);
      expect(cubit.state.notice, 'Permintaan ini sudah diputuskan.');
    });

    test('a non-admin never reaches the server', () async {
      final done = await cubit.decide(
        request: manualRequest(),
        approve: true,
        session: session('GUARD'),
      );

      expect(done, isFalse);
      verifyNever(
        () => repository.decideManualRequest(
          id: any(named: 'id'),
          approve: any(named: 'approve'),
          note: any(named: 'note'),
        ),
      );
    });
  });
}

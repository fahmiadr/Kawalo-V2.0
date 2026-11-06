import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_stream_event.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/delete_incident/delete_incident_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/delete_incident/delete_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incident_detail/get_incident_detail_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/get_incident_detail/get_incident_detail_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/post_incident_reply/post_incident_reply_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/post_incident_reply/post_incident_reply_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/watch_incident_replies/watch_incident_replies_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/watch_incident_replies/watch_incident_replies_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_detail_result.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_detail_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetIncidentDetailUseCase extends Mock
    implements GetIncidentDetailUseCase {}

class MockWatchIncidentRepliesUseCase extends Mock
    implements WatchIncidentRepliesUseCase {}

class MockPostIncidentReplyUseCase extends Mock
    implements PostIncidentReplyUseCase {}

class MockResolveIncidentUseCase extends Mock
    implements ResolveIncidentUseCase {}

class MockDeleteIncidentUseCase extends Mock implements DeleteIncidentUseCase {}

class FakeGetIncidentDetailParams extends Fake
    implements GetIncidentDetailParams {}

class FakeWatchIncidentRepliesParams extends Fake
    implements WatchIncidentRepliesParams {}

class FakePostIncidentReplyParams extends Fake
    implements PostIncidentReplyParams {}

class FakeResolveIncidentParams extends Fake implements ResolveIncidentParams {}

class FakeDeleteIncidentParams extends Fake implements DeleteIncidentParams {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeGetIncidentDetailParams());
    registerFallbackValue(FakeWatchIncidentRepliesParams());
    registerFallbackValue(FakePostIncidentReplyParams());
    registerFallbackValue(FakeResolveIncidentParams());
    registerFallbackValue(FakeDeleteIncidentParams());
  });

  late MockGetIncidentDetailUseCase mockGetDetail;
  late MockWatchIncidentRepliesUseCase mockWatchReplies;
  late MockPostIncidentReplyUseCase mockPostReply;
  late MockResolveIncidentUseCase mockResolve;
  late MockDeleteIncidentUseCase mockDelete;
  late IncidentDetailCubit cubit;

  setUp(() {
    mockGetDetail = MockGetIncidentDetailUseCase();
    mockWatchReplies = MockWatchIncidentRepliesUseCase();
    mockPostReply = MockPostIncidentReplyUseCase();
    mockResolve = MockResolveIncidentUseCase();
    mockDelete = MockDeleteIncidentUseCase();

    cubit = IncidentDetailCubit(
      incidentId: 'inc_1',
      getIncidentDetailUseCase: mockGetDetail,
      watchIncidentRepliesUseCase: mockWatchReplies,
      postIncidentReplyUseCase: mockPostReply,
      resolveIncidentUseCase: mockResolve,
      deleteIncidentUseCase: mockDelete,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tSession = AuthSessionEntity(
    userId: 'u1',
    email: 'guard@k.id',
    name: 'Budi',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
    groupUid: 'grp_1',
  );

  final tIncident = IncidentEntity(
    id: 'inc_1',
    groupId: 'grp_1',
    title: 'Pintu Gerbang Rusak',
    status: IncidentStatus.open,
    createdBy: 'u1',
    createdAt: DateTime.now(),
  );

  group('IncidentDetailCubit Tests', () {
    test('initial state is correct', () {
      expect(cubit.state, equals(const IncidentDetailState()));
    });

    blocTest<IncidentDetailCubit, IncidentDetailState>(
      'init loads detail and subscribes to stream',
      build: () {
        when(() => mockGetDetail(any())).thenAnswer(
          (_) async => Right(
            IncidentDetailResult(incident: tIncident, replies: const []),
          ),
        );
        when(() => mockWatchReplies(any())).thenAnswer(
          (_) =>
              StreamController<Either<Failure, IncidentStreamEvent>>().stream,
        );
        return cubit;
      },
      act: (c) => c.init(session: tSession),
      expect: () => [
        const IncidentDetailState(status: IncidentDetailStatus.loading),
        predicate<IncidentDetailState>((s) {
          return s.status == IncidentDetailStatus.success &&
              s.incident?.id == 'inc_1' &&
              !s.isReadOnly;
        }),
      ],
    );

    blocTest<IncidentDetailCubit, IncidentDetailState>(
      'postReply catches HTTP 409 Conflict, locks thread, and preserves draft',
      build: () {
        when(() => mockPostReply(any())).thenAnswer(
          (_) async => const Left(
            ServerFailure('Already resolved', 409, 'ALREADY_RESOLVED'),
          ),
        );
        return cubit;
      },
      seed: () => IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident,
        draftMessage: 'Lagi diperbaiki',
      ),
      act: (c) => c.postReply(session: tSession),
      expect: () => [
        predicate<IncidentDetailState>((s) => s.isPostingReply),
        predicate<IncidentDetailState>((s) {
          return !s.isPostingReply &&
              s.isReadOnly &&
              s.draftMessage == 'Lagi diperbaiki' &&
              s.conflictNotice == 'Insiden telah diselesaikan oleh rekan Anda.';
        }),
      ],
    );

    blocTest<IncidentDetailCubit, IncidentDetailState>(
      'resolveIncident successfully updates incident and locks thread',
      build: () {
        final resolved = tIncident.copyWith(
          status: IncidentStatus.resolved,
          resolvedByName: 'Budi',
        );
        when(() => mockResolve(any())).thenAnswer((_) async => Right(resolved));
        return cubit;
      },
      seed: () => IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident,
      ),
      act: (c) => c.resolveIncident(session: tSession),
      expect: () => [
        predicate<IncidentDetailState>((s) => s.isResolving),
        predicate<IncidentDetailState>((s) {
          return !s.isResolving &&
              s.isReadOnly &&
              s.incident?.status == IncidentStatus.resolved &&
              s.infoNotice == 'Insiden berhasil diselesaikan.';
        }),
      ],
    );
  });
}

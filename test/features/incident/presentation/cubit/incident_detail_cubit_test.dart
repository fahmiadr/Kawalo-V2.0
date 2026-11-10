import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/upload/upload_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_reply_entity.dart';
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
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
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

class MockUploadRepository extends Mock implements UploadRepository {}

class FakeAppMediaFile extends Fake implements AppMediaFile {}

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
    registerFallbackValue(FakeAppMediaFile());
  });

  late MockGetIncidentDetailUseCase mockGetDetail;
  late MockWatchIncidentRepliesUseCase mockWatchReplies;
  late MockPostIncidentReplyUseCase mockPostReply;
  late MockResolveIncidentUseCase mockResolve;
  late MockDeleteIncidentUseCase mockDelete;
  late MockUploadRepository mockUpload;
  late IncidentDetailCubit cubit;

  setUp(() {
    mockGetDetail = MockGetIncidentDetailUseCase();
    mockWatchReplies = MockWatchIncidentRepliesUseCase();
    mockPostReply = MockPostIncidentReplyUseCase();
    mockResolve = MockResolveIncidentUseCase();
    mockDelete = MockDeleteIncidentUseCase();
    mockUpload = MockUploadRepository();

    cubit = IncidentDetailCubit(
      incidentId: 'inc_1',
      getIncidentDetailUseCase: mockGetDetail,
      watchIncidentRepliesUseCase: mockWatchReplies,
      postIncidentReplyUseCase: mockPostReply,
      resolveIncidentUseCase: mockResolve,
      deleteIncidentUseCase: mockDelete,
      uploadRepository: mockUpload,
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
      'postReply handles HTTP 400 "already resolved", locks thread, keeps '
      'draft and reloads the detail',
      build: () {
        when(() => mockPostReply(any())).thenAnswer(
          (_) async => const Left(
            ServerFailure('Insiden sudah diselesaikan, diskusi ditutup.', 400),
          ),
        );
        when(() => mockGetDetail(any())).thenAnswer(
          (_) async => Right(
            IncidentDetailResult(
              incident: tIncident.copyWith(status: IncidentStatus.resolved),
              replies: const [],
            ),
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
        predicate<IncidentDetailState>(
          (s) => s.incident?.status == IncidentStatus.resolved && s.isReadOnly,
        ),
      ],
      verify: (_) => verify(() => mockGetDetail(any())).called(1),
    );

    blocTest<IncidentDetailCubit, IncidentDetailState>(
      'postReply with another HTTP 400 only shows the message',
      build: () {
        when(() => mockPostReply(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Pesan terlalu panjang.', 400)),
        );
        return cubit;
      },
      seed: () => IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident,
        draftMessage: 'Halo',
      ),
      act: (c) => c.postReply(session: tSession),
      expect: () => [
        predicate<IncidentDetailState>((s) => s.isPostingReply),
        predicate<IncidentDetailState>(
          (s) =>
              !s.isPostingReply &&
              !s.isReadOnly &&
              s.errorMessage == 'Pesan terlalu panjang.' &&
              s.draftMessage == 'Halo',
        ),
      ],
      verify: (_) => verifyNever(() => mockGetDetail(any())),
    );

    blocTest<IncidentDetailCubit, IncidentDetailState>(
      'resolveIncident shows server errors without a conflict branch',
      build: () {
        when(() => mockResolve(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Gagal menyelesaikan.', 409)),
        );
        return cubit;
      },
      seed: () => IncidentDetailState(
        status: IncidentDetailStatus.success,
        incident: tIncident,
      ),
      act: (c) => c.resolveIncident(session: tSession),
      expect: () => [
        predicate<IncidentDetailState>((s) => s.isResolving),
        predicate<IncidentDetailState>(
          (s) =>
              !s.isResolving &&
              !s.isReadOnly &&
              s.conflictNotice == null &&
              s.errorMessage == 'Gagal menyelesaikan.',
        ),
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

  group('IncidentDetailCubit reply photo upload', () {
    IncidentMediaItem photo(int i) =>
        IncidentMediaItem(id: 'p$i', name: 'foto_$i.jpg', path: '/tmp/$i.jpg');

    void stubUpload(
      Future<Either<Failure, String>> Function(AppMediaFile file) answer,
    ) {
      when(
        () =>
            mockUpload.uploadImage(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer(
        (inv) => answer(inv.positionalArguments.first as AppMediaFile),
      );
    }

    Either<Failure, String> okUrl(AppMediaFile f) =>
        Right('https://cdn.kawalo.id/${f.name}.webp');

    IncidentDetailState seeded(List<IncidentMediaItem> photos) =>
        IncidentDetailState(
          status: IncidentDetailStatus.success,
          incident: tIncident,
          draftPhotos: photos,
        );

    void stubPostOk() {
      when(() => mockPostReply(any())).thenAnswer(
        (inv) async => Right(
          IncidentReplyEntity(
            id: 'rpl_1',
            incidentId: 'inc_1',
            senderId: 'guard@k.id',
            senderName: 'Budi',
            senderRole: 'GUARD',
            message: 'ok',
            photos: (inv.positionalArguments.first as PostIncidentReplyParams)
                .photos,
            createdAt: DateTime.now(),
          ),
        ),
      );
    }

    test('uploads draft photos and posts only the uploaded URLs', () async {
      stubUpload((f) async => okUrl(f));
      stubPostOk();
      cubit.emit(seeded([photo(1), photo(2)]));

      await cubit.postReply(session: tSession);

      final params =
          verify(() => mockPostReply(captureAny())).captured.single
              as PostIncidentReplyParams;
      expect(params.photos, [
        'https://cdn.kawalo.id/foto_1.jpg.webp',
        'https://cdn.kawalo.id/foto_2.jpg.webp',
      ]);
      expect(cubit.state.draftPhotos, isEmpty);
      expect(cubit.state.isPostingReply, isFalse);
    });

    test(
      'partial failure keeps the draft and never posts a local file',
      () async {
        stubUpload(
          (f) async => f.name == 'foto_2.jpg'
              ? const Left(NetworkFailure('Koneksi terputus.'))
              : okUrl(f),
        );
        cubit.emit(seeded([photo(1), photo(2)]));

        await cubit.postReply(session: tSession);

        verifyNever(() => mockPostReply(any()));
        expect(cubit.state.isPostingReply, isFalse);
        expect(cubit.state.errorMessage, contains('1 foto gagal diunggah'));
        expect(cubit.state.draftPhotos[0].isUploaded, isTrue);
        expect(
          cubit.state.draftPhotos[1].uploadStatus,
          IncidentUploadStatus.failed,
        );
        expect(cubit.state.draftPhotos[1].uploadError, 'Koneksi terputus.');
      },
    );

    test('retryDraftPhotoUpload uploads only the failed photo', () async {
      var fail = true;
      stubUpload((f) async {
        if (fail) return const Left(NetworkFailure('Koneksi terputus.'));
        return okUrl(f);
      });
      stubPostOk();
      cubit.emit(seeded([photo(1)]));
      await cubit.postReply(session: tSession);
      expect(cubit.state.draftPhotos.single.needsUpload, isTrue);

      fail = false;
      await cubit.retryDraftPhotoUpload('p1');
      expect(cubit.state.draftPhotos.single.isUploaded, isTrue);

      await cubit.postReply(session: tSession);
      verify(
        () =>
            mockUpload.uploadImage(any(), onProgress: any(named: 'onProgress')),
      ).called(2); // failed attempt + retry; the final post re-uploads nothing
      verify(() => mockPostReply(any())).called(1);
    });

    test('postReply is ignored while a photo is uploading', () async {
      final completer = Completer<Either<Failure, String>>();
      stubUpload((_) => completer.future);
      stubPostOk();
      cubit.emit(seeded([photo(1)]));

      final first = cubit.postReply(session: tSession);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isPostingReply, isTrue);
      expect(cubit.state.isUploadingPhotos, isTrue);

      await cubit.postReply(session: tSession); // ignored
      completer.complete(const Right('https://cdn.kawalo.id/a.webp'));
      await first;

      verify(
        () =>
            mockUpload.uploadImage(any(), onProgress: any(named: 'onProgress')),
      ).called(1);
      verify(() => mockPostReply(any())).called(1);
    });
  });
}

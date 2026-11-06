import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/repositories/incident_repository.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_params.dart';
import 'package:kawalo_mobile/features/incident/domain/usecases/resolve_incident/resolve_incident_usecase.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentRepository extends Mock implements IncidentRepository {}

void main() {
  late MockIncidentRepository mockRepository;
  late ResolveIncidentUseCase useCase;

  setUp(() {
    mockRepository = MockIncidentRepository();
    useCase = ResolveIncidentUseCase(mockRepository);
  });

  final tOpenIncident = IncidentEntity(
    id: 'inc_10',
    groupId: 'grp_1',
    title: 'Pipa Bocor',
    status: IncidentStatus.open,
    createdBy: 'usr_1',
    createdAt: DateTime.now(),
  );

  const tSession = AuthSessionEntity(
    userId: 'usr_1',
    email: 'guard@k.id',
    name: 'Budi',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
    groupUid: 'grp_1',
  );

  group('ResolveIncidentUseCase Tests', () {
    test('calls repository.resolveIncident when authorized', () async {
      final tResolved = tOpenIncident.copyWith(status: IncidentStatus.resolved);

      when(
        () => mockRepository.resolveIncident(
          incidentId: 'inc_10',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => Right(tResolved));

      final params = ResolveIncidentParams(
        incident: tOpenIncident,
        session: tSession,
      );

      final result = await useCase(params);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (incident) => expect(incident.status, equals(IncidentStatus.resolved)),
      );

      verify(() => mockRepository.resolveIncident(incidentId: 'inc_10'))
          .called(1);
    });

    test('returns ForbiddenFailure when unauthorized (different group)',
        () async {
      const otherSession = AuthSessionEntity(
        userId: 'usr_other',
        email: 'other@k.id',
        name: 'Other',
        allowAdmin: false,
        allowPatrol: true,
        allowMonPatrol: false,
        groupUid: 'grp_other',
      );

      final params = ResolveIncidentParams(
        incident: tOpenIncident,
        session: otherSession,
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ForbiddenFailure>()),
        (_) => fail('Should be left'),
      );

      verifyNever(
        () => mockRepository.resolveIncident(
          incidentId: any(named: 'incidentId'),
        ),
      );
    });

    test('propagates ServerFailure (HTTP 409 Conflict) from repository',
        () async {
      when(
        () => mockRepository.resolveIncident(
          incidentId: 'inc_10',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ServerFailure('Already resolved', 409),
        ),
      );

      final params = ResolveIncidentParams(
        incident: tOpenIncident,
        session: tSession,
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, equals(409));
        },
        (_) => fail('Should be left'),
      );
    });
  });
}

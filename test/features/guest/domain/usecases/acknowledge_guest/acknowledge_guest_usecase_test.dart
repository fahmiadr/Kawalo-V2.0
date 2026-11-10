import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/acknowledge_guest/acknowledge_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/acknowledge_guest/acknowledge_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/value_objects/acknowledge_guest_data.dart';
import 'package:mocktail/mocktail.dart';

class _MockGuestRepository extends Mock implements GuestRepository {}

AuthSessionEntity _session(String email, {String? role}) => AuthSessionEntity(
  userId: '1',
  email: email,
  name: 'User',
  role: role,
  allowAdmin: role == 'ADMIN',
  allowPatrol: role == 'GUARD',
  allowMonPatrol: false,
);

void main() {
  const waiting = GuestItemEntity(
    id: '42',
    guestName: 'Budi',
    guestToUserEmail: 'Host@Kawalo.id',
  );
  final admin = _session('admin@kawalo.id', role: 'ADMIN');
  final guard = _session('guard@kawalo.id', role: 'GUARD');
  final host = _session('host@kawalo.id', role: 'USER');
  final stranger = _session('lain@kawalo.id', role: 'USER');

  group('GuestItemEntity.canBeAcknowledgedBySession', () {
    test('staff and the invited host may confirm a waiting guest', () {
      expect(waiting.canBeAcknowledgedBySession(admin), isTrue);
      expect(waiting.canBeAcknowledgedBySession(guard), isTrue);
      expect(waiting.canBeAcknowledgedBySession(host), isTrue);
    });

    test('another resident, a null session or a guest without host cannot', () {
      expect(waiting.canBeAcknowledgedBySession(stranger), isFalse);
      expect(waiting.canBeAcknowledgedBySession(null), isFalse);
      const noHost = GuestItemEntity(id: '1');
      expect(noHost.canBeAcknowledgedBySession(host), isFalse);
    });

    test('nobody may confirm a guest already confirmed or checked out', () {
      const confirmed = GuestItemEntity(
        id: '1',
        guestAckDt: '2026-11-02T10:00:00.000Z',
      );
      const exited = GuestItemEntity(
        id: '2',
        guestOutDt: '2026-11-02T11:00:00.000Z',
      );
      expect(confirmed.canBeAcknowledgedBySession(admin), isFalse);
      expect(exited.canBeAcknowledgedBySession(admin), isFalse);
    });
  });

  group('AcknowledgeGuestUseCase', () {
    late _MockGuestRepository repository;
    late AcknowledgeGuestUseCase useCase;

    setUpAll(() {
      registerFallbackValue(const AcknowledgeGuestData(id: 'x'));
    });

    setUp(() {
      repository = _MockGuestRepository();
      useCase = AcknowledgeGuestUseCase(repository);
    });

    test('rejects an invalid id without calling the repository', () async {
      final result = await useCase(
        AcknowledgeGuestParams(id: '', session: admin, item: waiting),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyZeroInteractions(repository);
    });

    test('rejects an unauthorized session', () async {
      final result = await useCase(
        AcknowledgeGuestParams(id: '42', session: stranger, item: waiting),
      );

      result.fold(
        (f) => expect(f, isA<ForbiddenFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyZeroInteractions(repository);
    });

    test('delegates to the repository for the invited host', () async {
      const confirmed = GuestItemEntity(
        id: '42',
        guestAckDt: '2026-11-02T10:00:00.000Z',
      );
      when(
        () => repository.acknowledgeGuest(any()),
      ).thenAnswer((_) async => const Right(confirmed));

      final result = await useCase(
        AcknowledgeGuestParams(
          id: '42',
          session: host,
          item: waiting,
          qrUid: 'QR-42',
        ),
      );

      expect(result, const Right<Failure, GuestItemEntity>(confirmed));
      verify(
        () => repository.acknowledgeGuest(
          const AcknowledgeGuestData(id: '42', qrUid: 'QR-42'),
        ),
      ).called(1);
    });
  });
}

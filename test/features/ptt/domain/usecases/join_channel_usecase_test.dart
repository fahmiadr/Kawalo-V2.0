import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_repository.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_params.dart';
import 'package:kawalo_mobile/features/ptt/domain/usecases/join_channel/join_channel_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockPttRepository extends Mock implements PttRepository {}

void main() {
  late MockPttRepository mockRepository;
  late JoinChannelUseCase useCase;

  setUp(() {
    mockRepository = MockPttRepository();
    useCase = JoinChannelUseCase(mockRepository);
  });

  const tChannelUrl = 'wss://api.kawalo.id/ws/ptt/grp_security_01';
  const tGroupUid = 'grp_security_01';
  const tToken = 'jwt_valid_token';

  group('JoinChannelUseCase', () {
    test('mengembalikan ServerFailure jika channelUrl kosong', () async {
      final result = await useCase(
        const JoinChannelParams(
          channelUrl: '',
          groupUid: tGroupUid,
          token: tToken,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.message,
          'Parameter saluran PTT tidak boleh kosong.',
        ),
        (_) => fail('Harus mengembalikan failure'),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('mengembalikan ServerFailure jika groupUid kosong', () async {
      final result = await useCase(
        const JoinChannelParams(
          channelUrl: tChannelUrl,
          groupUid: '   ',
          token: tToken,
        ),
      );

      expect(result.isLeft(), isTrue);
      verifyZeroInteractions(mockRepository);
    });

    test('mengembalikan ServerFailure jika token kosong', () async {
      final result = await useCase(
        const JoinChannelParams(
          channelUrl: tChannelUrl,
          groupUid: tGroupUid,
          token: '',
        ),
      );

      expect(result.isLeft(), isTrue);
      verifyZeroInteractions(mockRepository);
    });

    test('mendelegasikan ke repositori ketika parameter valid', () async {
      when(
        () => mockRepository.joinChannel(
          channelUrl: tChannelUrl,
          groupUid: tGroupUid,
          token: tToken,
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        const JoinChannelParams(
          channelUrl: tChannelUrl,
          groupUid: tGroupUid,
          token: tToken,
        ),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.joinChannel(
          channelUrl: tChannelUrl,
          groupUid: tGroupUid,
          token: tToken,
        ),
      ).called(1);
    });

    test('meneruskan ServerFailure dari repositori jika gagal', () async {
      when(
        () => mockRepository.joinChannel(
          channelUrl: tChannelUrl,
          groupUid: tGroupUid,
          token: tToken,
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('Connection refused')),
      );

      final result = await useCase(
        const JoinChannelParams(
          channelUrl: tChannelUrl,
          groupUid: tGroupUid,
          token: tToken,
        ),
      );

      expect(
        result,
        const Left<Failure, void>(ServerFailure('Connection refused')),
      );
    });
  });
}

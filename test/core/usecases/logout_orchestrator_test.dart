import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/storage/cache_wiper.dart';
import 'package:kawalo_mobile/core/usecases/logout_orchestrator.dart';
import 'package:kawalo_mobile/core/usecases/usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthLogoutUseCase extends Mock implements UseCase<void, NoParams> {}

class MockCacheWiper extends Mock implements CacheWiper {}

void main() {
  late MockAuthLogoutUseCase authLogout;
  late MockCacheWiper cacheWiper;
  late LogoutOrchestrator orchestrator;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    authLogout = MockAuthLogoutUseCase();
    cacheWiper = MockCacheWiper();
    when(() => cacheWiper.wipeAll()).thenAnswer((_) async {});
    orchestrator = LogoutOrchestrator(
      authLogoutUseCase: authLogout,
      cacheWiper: cacheWiper,
    );
  });

  group('LogoutOrchestrator', () {
    test('returns Right and wipes cache when auth logout succeeds', () async {
      when(() => authLogout(any())).thenAnswer((_) async => const Right(null));

      final result = await orchestrator(const NoParams());

      expect(result.isRight(), isTrue);
      verify(() => authLogout(any())).called(1);
      verify(() => cacheWiper.wipeAll()).called(1);
    });

    test(
      'propagates Left and still wipes cache when auth logout fails',
      () async {
        const failure = ServerFailure('gagal logout');
        when(
          () => authLogout(any()),
        ).thenAnswer((_) async => const Left(failure));

        final result = await orchestrator(const NoParams());

        expect(result, const Left<Failure, void>(failure));
        verify(() => cacheWiper.wipeAll()).called(1);
      },
    );

    test('keeps thrown Failure as is and still wipes cache', () async {
      const failure = NetworkFailure();
      when(() => authLogout(any())).thenThrow(failure);

      final result = await orchestrator(const NoParams());

      expect(result, const Left<Failure, void>(failure));
      verify(() => cacheWiper.wipeAll()).called(1);
    });

    test(
      'maps generic exception to ServerFailure and still wipes cache',
      () async {
        when(() => authLogout(any())).thenThrow(Exception('boom'));

        final result = await orchestrator(const NoParams());

        expect(result.isLeft(), isTrue);
        result.match(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Seharusnya Left'),
        );
        verify(() => cacheWiper.wipeAll()).called(1);
      },
    );
  });
}

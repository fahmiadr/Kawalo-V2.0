import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_qr_scan_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_qr_scan_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/guest_fixtures.dart';

class _MockRepo extends Mock implements GuestRepository {}

void main() {
  const uid = 'QR-VER-RENI-10822';
  const guest = GuestFixtures.sampleWaitingGuest;

  late _MockRepo repo;
  late DateTime now;

  GuestQrScanCubit build() =>
      GuestQrScanCubit(repository: repo, clock: () => now);

  void stubLookup(Either<Failure, dynamic> result) {
    when(
      () => repo.getGuestByIdentifier(
        any(),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => result.map((r) => guest));
  }

  setUp(() {
    repo = _MockRepo();
    now = DateTime(2026, 11, 10, 9);
  });

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'resolves a valid code to the guest',
    setUp: () => stubLookup(const Right(guest)),
    build: build,
    act: (cubit) => cubit.onCode(' $uid '),
    expect: () => [const GuestQrResolving(uid), const GuestQrResolved(guest)],
    verify: (_) => verify(() => repo.getGuestByIdentifier(uid)).called(1),
  );

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'rejects a code that cannot be a qr_uid without calling the API',
    build: build,
    act: (cubit) => cubit.onCode('https://example.com'),
    expect: () => [const GuestQrInvalid()],
    verify: (_) => verifyZeroInteractions(repo),
  );

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'maps 404 to not found',
    setUp: () => stubLookup(
      const Left(ServerFailure('Data tamu tidak ditemukan.', 404)),
    ),
    build: build,
    act: (cubit) => cubit.onCode(uid),
    expect: () => [const GuestQrResolving(uid), const GuestQrNotFound(uid)],
  );

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'maps 403 to forbidden',
    setUp: () => stubLookup(const Left(AuthFailure('Dilarang.', 403))),
    build: build,
    act: (cubit) => cubit.onCode(uid),
    expect: () => [
      const GuestQrResolving(uid),
      const GuestQrForbidden('Dilarang.'),
    ],
  );

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'maps offline and server errors to a retryable failure',
    setUp: () => stubLookup(const Left(NoInternetFailure())),
    build: build,
    act: (cubit) => cubit.onCode(uid),
    expect: () => [
      const GuestQrResolving(uid),
      const GuestQrFailed(
        uid,
        'Tidak ada koneksi internet. Periksa koneksi data atau Wi-Fi Anda.',
      ),
    ],
  );

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'retry repeats the lookup of the failed code and can succeed',
    build: build,
    act: (cubit) async {
      stubLookup(const Left(NoInternetFailure()));
      await cubit.onCode(uid);
      stubLookup(const Right(guest));
      await cubit.retry();
    },
    skip: 2,
    expect: () => [const GuestQrResolving(uid), const GuestQrResolved(guest)],
  );

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'retry does nothing outside the failed state',
    build: build,
    act: (cubit) => cubit.retry(),
    expect: () => <GuestQrScanState>[],
  );

  blocTest<GuestQrScanCubit, GuestQrScanState>(
    'ignores every further code while a lookup is running or shown',
    setUp: () => stubLookup(const Right(guest)),
    build: build,
    act: (cubit) async {
      final first = cubit.onCode(uid);
      await cubit.onCode('another-guest');
      await first;
      await cubit.onCode('third-guest');
    },
    expect: () => [const GuestQrResolving(uid), const GuestQrResolved(guest)],
    verify: (_) => verify(() => repo.getGuestByIdentifier(any())).called(1),
  );

  group('debounce after "Pindai lagi"', () {
    blocTest<GuestQrScanCubit, GuestQrScanState>(
      'ignores the same code within the cooldown, accepts it afterwards',
      setUp: () => stubLookup(
        const Left(ServerFailure('Data tamu tidak ditemukan.', 404)),
      ),
      build: build,
      act: (cubit) async {
        await cubit.onCode(uid);
        cubit.resumeScanning();
        await cubit.onCode(uid);
        now = now.add(const Duration(seconds: 4));
        await cubit.onCode(uid);
      },
      skip: 2,
      expect: () => [
        const GuestQrScanning(),
        const GuestQrResolving(uid),
        const GuestQrNotFound(uid),
      ],
    );

    blocTest<GuestQrScanCubit, GuestQrScanState>(
      'a different code is accepted immediately',
      setUp: () => stubLookup(
        const Left(ServerFailure('Data tamu tidak ditemukan.', 404)),
      ),
      build: build,
      act: (cubit) async {
        await cubit.onCode(uid);
        cubit.resumeScanning();
        await cubit.onCode('other-code');
      },
      verify: (_) {
        verify(() => repo.getGuestByIdentifier(uid)).called(1);
        verify(() => repo.getGuestByIdentifier('other-code')).called(1);
      },
    );

    blocTest<GuestQrScanCubit, GuestQrScanState>(
      'resumeScanning is a no-op while resolving',
      setUp: () => stubLookup(const Right(guest)),
      build: build,
      act: (cubit) async {
        final pending = cubit.onCode(uid);
        cubit.resumeScanning();
        await pending;
      },
      expect: () => [const GuestQrResolving(uid), const GuestQrResolved(guest)],
    );
  });
}

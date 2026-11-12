import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_options.dart';
import 'package:kawalo_mobile/features/forecast/domain/entities/forecast_preview.dart';
import 'package:kawalo_mobile/features/forecast/domain/repositories/forecast_repository.dart';
import 'package:kawalo_mobile/features/forecast/domain/value_objects/forecast_config.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_cubit.dart';
import 'package:kawalo_mobile/features/forecast/presentation/cubit/forecast_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ForecastRepository {}

class _FakeConfig extends Fake implements ForecastConfig {}

class _FakePreview extends Fake implements ForecastPreview {}

const _options = ForecastOptions(
  shifts: [
    ForecastShift(
      uid: 's1',
      name: 'Pagi',
      startTime: '07:00',
      endTime: '15:00',
    ),
    ForecastShift(
      uid: 's2',
      name: 'Malam',
      startTime: '23:00',
      endTime: '07:00',
    ),
  ],
  people: [
    ForecastPerson(email: 'g1@x.id', role: 'GUARD', name: 'Gani'),
    ForecastPerson(email: 'a1@x.id', role: 'ADMIN'),
    ForecastPerson(email: 'g2@x.id', role: 'GUARD'),
  ],
);

ForecastPreview _preview({int seed = 7, int created = 5}) => ForecastPreview(
  seed: seed,
  token: 'tok$seed',
  existingCount: 0,
  deleteCount: 4,
  lockedCount: 1,
  plan: const [],
  stats: ForecastStats(
    totalCreated: created,
    totalDays: 7,
    totalPersonnel: 2,
    totalShifts: 2,
    totalCapacity: 14,
    perShift: const [],
    perPersonnel: const [],
    loadMin: 0,
    loadMax: 0,
    underStaffed: const [],
    underStaffedTotal: 0,
  ),
);

void main() {
  late _MockRepository repository;
  late ForecastCubit cubit;
  var nextSeed = 100;

  setUpAll(() {
    registerFallbackValue(_FakeConfig());
    registerFallbackValue(_FakePreview());
  });

  setUp(() {
    repository = _MockRepository();
    nextSeed = 100;
    cubit = ForecastCubit(
      repository: repository,
      clock: () => DateTime(2026, 11, 12, 9, 30),
      newSeed: () => nextSeed++,
    );
    when(
      () => repository.loadOptions(),
    ).thenAnswer((_) async => const Right(_options));
  });

  tearDown(() => cubit.close());

  void stubPreview(Either<Failure, ForecastPreview> result) {
    when(
      () => repository.preview(any(), seed: any(named: 'seed')),
    ).thenAnswer((_) async => result);
  }

  void stubApply(Either<Failure, ForecastResult> result) {
    when(
      () => repository.apply(
        any(),
        preview: any(named: 'preview'),
        confirmOverwrite: any(named: 'confirmOverwrite'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<ForecastConfiguring> loaded() async {
    await cubit.load();
    return cubit.state as ForecastConfiguring;
  }

  Future<ForecastPreviewReady> previewed() async {
    await loaded();
    stubPreview(Right(_preview()));
    await cubit.requestPreview();
    return cubit.state as ForecastPreviewReady;
  }

  group('load', () {
    test(
      'defaults: 7 days from today, every shift x1, only GUARD ticked',
      () async {
        final state = await loaded();

        expect(state.config.startDate, DateTime(2026, 11, 12));
        expect(state.config.endDate, DateTime(2026, 11, 18));
        expect(state.config.quotas, {'s1': 1, 's2': 1});
        expect(state.config.personnel, ['g1@x.id', 'g2@x.id']);
        expect(state.config.fillMode, ForecastFillMode.empty);
        expect(state.config.restEnabled, isTrue);
        expect(state.config.maxConsecutive, 6);
      },
    );

    test('failure gives a load error that load() can retry', () async {
      when(
        () => repository.loadOptions(),
      ).thenAnswer((_) async => const Left(NoInternetFailure()));

      await cubit.load();
      expect(cubit.state, isA<ForecastLoadError>());

      when(
        () => repository.loadOptions(),
      ).thenAnswer((_) async => const Right(_options));
      await cubit.load();
      expect(cubit.state, isA<ForecastConfiguring>());
    });
  });

  group('editing the form', () {
    test('range presets, start date keeps the length', () async {
      await loaded();

      cubit.setRangeDays(14);
      expect((cubit.state as ForecastConfiguring).config.rangeDays, 14);

      cubit.setStartDate(DateTime(2026, 12, 1, 15));
      final config = (cubit.state as ForecastConfiguring).config;
      expect(config.startDate, DateTime(2026, 12));
      expect(config.endDate, DateTime(2026, 12, 14));
    });

    test(
      'toggling a shift adds it with quota 1 and removes it again',
      () async {
        await loaded();

        cubit.toggleShift('s1');
        expect((cubit.state as ForecastConfiguring).config.quotas, {'s2': 1});
        cubit.toggleShift('s1');
        expect((cubit.state as ForecastConfiguring).config.quotas, {
          's2': 1,
          's1': 1,
        });
      },
    );

    test(
      'quota is clamped to 1..50 and ignored for unselected shifts',
      () async {
        await loaded();

        cubit.setQuota('s1', 99);
        expect((cubit.state as ForecastConfiguring).config.quotas['s1'], 50);
        cubit.setQuota('s1', 0);
        expect((cubit.state as ForecastConfiguring).config.quotas['s1'], 1);

        cubit
          ..toggleShift('s2')
          ..setQuota('s2', 3);
        expect(
          (cubit.state as ForecastConfiguring).config.quotas.containsKey('s2'),
          isFalse,
        );
      },
    );

    test('rest rule and fill mode', () async {
      await loaded();

      cubit
        ..setMaxConsecutive(99)
        ..setRestEnabled(enabled: false)
        ..setFillMode(ForecastFillMode.overwrite)
        ..setPersonnel(['a1@x.id']);

      final config = (cubit.state as ForecastConfiguring).config;
      expect(config.maxConsecutive, 31);
      expect(config.restEnabled, isFalse);
      expect(config.fillMode, ForecastFillMode.overwrite);
      expect(config.personnel, ['a1@x.id']);
    });
  });

  group('requestPreview', () {
    test('an invalid form shows the errors and calls nothing', () async {
      await loaded();
      cubit.setPersonnel(const []);

      await cubit.requestPreview();

      final state = cubit.state as ForecastConfiguring;
      expect(state.showErrors, isTrue);
      verifyNever(() => repository.preview(any(), seed: any(named: 'seed')));
    });

    test('a past start date is refused locally', () async {
      await loaded();
      cubit.setStartDate(DateTime(2026, 11, 11));

      await cubit.requestPreview();

      expect((cubit.state as ForecastConfiguring).showErrors, isTrue);
      verifyNever(() => repository.preview(any(), seed: any(named: 'seed')));
    });

    test(
      'success goes loading then ready, first call without a seed',
      () async {
        await loaded();
        stubPreview(Right(_preview()));
        final states = <ForecastState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.requestPreview();
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(states.first, isA<ForecastPreviewLoading>());
        expect(states.last, isA<ForecastPreviewReady>());
        // The first preview must not pin a seed; the server picks one.
        // ignore: avoid_redundant_argument_values
        verify(() => repository.preview(any(), seed: null)).called(1);
      },
    );

    test('a failed request returns to the form with the message', () async {
      await loaded();
      stubPreview(const Left(ServerFailure('Shift tidak ditemukan.', 400)));

      await cubit.requestPreview();

      final state = cubit.state as ForecastConfiguring;
      expect(state.error, 'Shift tidak ditemukan.');
      expect(state.config.quotas, {'s1': 1, 's2': 1});
    });
  });

  group('reshuffle', () {
    test('asks for a new seed with the same form values', () async {
      final first = await previewed();
      stubPreview(Right(_preview(seed: 100)));

      await cubit.reshuffle();

      verify(() => repository.preview(first.config, seed: 100)).called(1);
      expect((cubit.state as ForecastPreviewReady).preview.seed, 100);
    });

    test('a failure keeps the plan on screen with the error', () async {
      final first = await previewed();
      stubPreview(const Left(NoInternetFailure()));

      await cubit.reshuffle();

      final state = cubit.state as ForecastPreviewReady;
      expect(state.preview, first.preview);
      expect(state.error, isNotNull);
    });
  });

  group('apply', () {
    test('empty mode saves with confirm_overwrite false', () async {
      final ready = await previewed();
      stubApply(const Right(ForecastResult(created: 5, deleted: 0)));

      await cubit.apply();

      verify(
        () => repository.apply(
          ready.config,
          preview: ready.preview,
          confirmOverwrite: false,
        ),
      ).called(1);
      final state = cubit.state as ForecastApplied;
      expect(state.result, const ForecastResult(created: 5, deleted: 0));
    });

    test('overwrite without confirmation sends nothing', () async {
      await loaded();
      cubit.setFillMode(ForecastFillMode.overwrite);
      stubPreview(Right(_preview()));
      await cubit.requestPreview();

      await cubit.apply();

      verifyNever(
        () => repository.apply(
          any(),
          preview: any(named: 'preview'),
          confirmOverwrite: any(named: 'confirmOverwrite'),
        ),
      );
      expect(cubit.state, isA<ForecastPreviewReady>());
    });

    test('confirmed overwrite sends confirm_overwrite true', () async {
      await loaded();
      cubit.setFillMode(ForecastFillMode.overwrite);
      stubPreview(Right(_preview()));
      await cubit.requestPreview();
      stubApply(const Right(ForecastResult(created: 5, deleted: 4)));

      await cubit.apply(overwriteConfirmed: true);

      verify(
        () => repository.apply(
          any(),
          preview: any(named: 'preview'),
          confirmOverwrite: true,
        ),
      ).called(1);
      expect((cubit.state as ForecastApplied).result.deleted, 4);
    });

    test(
      'shows applying while the request runs and ignores a second tap',
      () async {
        await previewed();
        final completer = Completer<Either<Failure, ForecastResult>>();
        when(
          () => repository.apply(
            any(),
            preview: any(named: 'preview'),
            confirmOverwrite: any(named: 'confirmOverwrite'),
          ),
        ).thenAnswer((_) => completer.future);

        final first = cubit.apply();
        expect((cubit.state as ForecastPreviewReady).applying, isTrue);
        await cubit.apply();
        completer.complete(const Right(ForecastResult(created: 1, deleted: 0)));
        await first;

        verify(
          () => repository.apply(
            any(),
            preview: any(named: 'preview'),
            confirmOverwrite: any(named: 'confirmOverwrite'),
          ),
        ).called(1);
      },
    );

    test('409 becomes the stale state; retry asks for a new preview', () async {
      final ready = await previewed();
      stubApply(
        const Left(
          ServerFailure('Data jadwal berubah sejak pratinjau dibuat.', 409),
        ),
      );

      await cubit.apply();

      final stale = cubit.state as ForecastStale;
      expect(stale.message, 'Data jadwal berubah sejak pratinjau dibuat.');
      expect(stale.config, ready.config);

      stubPreview(Right(_preview(seed: 8)));
      await cubit.retryPreview();
      expect((cubit.state as ForecastPreviewReady).preview.seed, 8);
    });

    test('another failure keeps the preview with the error', () async {
      final ready = await previewed();
      stubApply(const Left(ServerFailure('Terjadi kendala pada sistem.', 500)));

      await cubit.apply();

      final state = cubit.state as ForecastPreviewReady;
      expect(state.preview, ready.preview);
      expect(state.applying, isFalse);
      expect(state.error, 'Terjadi kendala pada sistem.');
    });
  });

  group('backToConfig', () {
    test('keeps the form values from the preview and stale steps', () async {
      final ready = await previewed();

      cubit.backToConfig();
      final back = cubit.state as ForecastConfiguring;
      expect(back.config, ready.config);
      expect(back.showErrors, isFalse);
    });

    test('is blocked while saving and after success', () async {
      await previewed();
      final completer = Completer<Either<Failure, ForecastResult>>();
      when(
        () => repository.apply(
          any(),
          preview: any(named: 'preview'),
          confirmOverwrite: any(named: 'confirmOverwrite'),
        ),
      ).thenAnswer((_) => completer.future);
      final running = cubit.apply();

      cubit.backToConfig();
      expect(cubit.state, isA<ForecastPreviewReady>());

      completer.complete(const Right(ForecastResult(created: 1, deleted: 0)));
      await running;
      cubit.backToConfig();
      expect(cubit.state, isA<ForecastApplied>());
    });

    test('a preview that finishes after going back is dropped', () async {
      await loaded();
      final completer = Completer<Either<Failure, ForecastPreview>>();
      when(
        () => repository.preview(any(), seed: any(named: 'seed')),
      ).thenAnswer((_) => completer.future);
      final pending = cubit.requestPreview();

      cubit.backToConfig();
      completer.complete(Right(_preview()));
      await pending;

      expect(cubit.state, isA<ForecastConfiguring>());
    });
  });
}

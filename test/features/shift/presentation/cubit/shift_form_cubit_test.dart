import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/shift/domain/entities/shift_entity.dart';
import 'package:kawalo_mobile/features/shift/domain/repositories/shift_repository.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_clock.dart';
import 'package:kawalo_mobile/features/shift/domain/value_objects/shift_input.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_cubit.dart';
import 'package:kawalo_mobile/features/shift/presentation/cubit/shift_form_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ShiftRepository {}

class _FakeInput extends Fake implements ShiftInput {}

const _saved = ShiftEntity(
  uid: 'a',
  name: 'Shift Pagi',
  startTime: ShiftClock(7, 0),
  endTime: ShiftClock(15, 0),
  color: '#F2A900',
  locationName: 'Pos',
  latitude: -6.2,
  longitude: 106.8,
  radius: 150,
);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(_FakeInput()));

  setUp(() => repository = _MockRepository());

  ShiftFormCubit create({ShiftEntity? initial}) =>
      ShiftFormCubit(repository: repository, initial: initial);

  void fillValid(ShiftFormCubit cubit) {
    cubit
      ..setName('Shift Siang')
      ..setStartTime(const ShiftClock(15, 0))
      ..setEndTime(const ShiftClock(23, 0));
  }

  group('initial state', () {
    test('a new shift starts with the defaults', () {
      final cubit = create();
      final values = cubit.state.values;
      expect(cubit.isEdit, isFalse);
      expect(values.limitLocation, isFalse);
      expect(values.radiusText, '100');
      expect(values.color, '#F2A900');
      expect(cubit.state.isCustomRadius, isFalse);
      expect(cubit.state.isDirty, isFalse);
      addTearDown(cubit.close);
    });

    test('editing loads the shift; a non-preset radius opens "Lainnya"', () {
      final cubit = create(initial: _saved);
      expect(cubit.isEdit, isTrue);
      expect(cubit.state.values.name, 'Shift Pagi');
      expect(cubit.state.values.limitLocation, isTrue);
      expect(cubit.state.values.radiusText, '150');
      expect(cubit.state.isCustomRadius, isTrue);
      expect(cubit.state.isDirty, isFalse);
      addTearDown(cubit.close);
    });

    test('a purple legacy colour falls back to the default', () {
      final cubit = create(
        initial: const ShiftEntity(
          uid: 'a',
          name: 'x',
          startTime: ShiftClock(7, 0),
          endTime: ShiftClock(8, 0),
          color: '#8E24AA',
        ),
      );
      expect(cubit.state.values.color, '#F2A900');
      addTearDown(cubit.close);
    });
  });

  group('editing', () {
    test('radius presets and "Lainnya" switch the mode', () {
      final cubit = create()..selectCustomRadius();
      expect(cubit.state.isCustomRadius, isTrue);
      expect(cubit.state.values.radiusText, '100');

      cubit.setRadiusText('250');
      expect(cubit.state.values.radius, 250);

      cubit.selectRadiusPreset(500);
      expect(cubit.state.isCustomRadius, isFalse);
      expect(cubit.state.values.radiusText, '500');
      addTearDown(cubit.close);
    });

    test('errors stay hidden until the first save attempt', () async {
      final cubit = create();
      expect(cubit.state.errors.isValid, isTrue);

      final result = await cubit.submit();

      expect(result, isNull);
      expect(cubit.state.errors.name, 'Nama shift wajib diisi.');
      expect(cubit.state.errors.startTime, 'Pilih jam mulai.');
      verifyZeroInteractions(repository);
      addTearDown(cubit.close);
    });

    test('once shown, errors follow the edits', () async {
      final cubit = create();
      await cubit.submit();
      cubit.setName('Shift');
      expect(cubit.state.errors.name, isNull);
      addTearDown(cubit.close);
    });
  });

  group('submit', () {
    test('creates a valid new shift and returns it', () async {
      when(
        () => repository.createShift(any()),
      ).thenAnswer((_) async => const Right(_saved));
      final cubit = create();
      fillValid(cubit);

      final result = await cubit.submit();

      expect(result!.getRight().toNullable(), _saved);
      final sent =
          verify(() => repository.createShift(captureAny())).captured.single
              as ShiftInput;
      expect(sent.name, 'Shift Siang');
      expect(sent.startTime, const ShiftClock(15, 0));
      expect(sent.latitude, isNull);
      expect(cubit.state.status, ShiftFormStatus.editing);
      addTearDown(cubit.close);
    });

    test('updates by uid when editing', () async {
      when(
        () => repository.updateShift('a', any()),
      ).thenAnswer((_) async => const Right(_saved));
      final cubit = create(initial: _saved)..setName('Shift Pagi 2');

      await cubit.submit();

      verify(() => repository.updateShift('a', any())).called(1);
      verifyNever(() => repository.createShift(any()));
      addTearDown(cubit.close);
    });

    test('passes the chosen location and radius', () async {
      when(
        () => repository.createShift(any()),
      ).thenAnswer((_) async => const Right(_saved));
      final cubit = create();
      fillValid(cubit);
      cubit
        ..setLimitLocation(true)
        ..setCoordinates(-6.2146, 106.8199)
        ..selectRadiusPreset(50);

      await cubit.submit();

      final sent =
          verify(() => repository.createShift(captureAny())).captured.single
              as ShiftInput;
      expect(sent.latitude, -6.2146);
      expect(sent.radius, 50);
      addTearDown(cubit.close);
    });

    test('blocks a limited shift without a point', () async {
      final cubit = create();
      fillValid(cubit);
      cubit.setLimitLocation(true);

      expect(await cubit.submit(), isNull);
      expect(cubit.state.errors.location, 'Pilih titik lokasi absen di peta.');
      verifyZeroInteractions(repository);
      addTearDown(cubit.close);
    });

    test('shows a 409 on the name field until the name changes', () async {
      when(() => repository.createShift(any())).thenAnswer(
        (_) async => const Left(
          ServerFailure('Nama shift sudah dipakai di grup ini.', 409),
        ),
      );
      final cubit = create();
      fillValid(cubit);

      final result = await cubit.submit();

      expect(result, isNull);
      expect(cubit.state.errors.name, 'Nama shift sudah dipakai di grup ini.');
      expect(cubit.state.status, ShiftFormStatus.editing);

      cubit.setName('Shift Siang 2');
      expect(cubit.state.errors.name, isNull);
      addTearDown(cubit.close);
    });

    test('returns other failures for the screen to show', () async {
      when(() => repository.createShift(any())).thenAnswer(
        (_) async =>
            const Left(ServerFailure('Warna harus berformat #RRGGBB.', 400)),
      );
      final cubit = create();
      fillValid(cubit);

      final result = await cubit.submit();

      expect(result!.getLeft().toNullable()!.message, contains('Warna'));
      expect(cubit.state.errors.name, isNull);
      addTearDown(cubit.close);
    });

    test('is saving while the request is in flight', () async {
      final pending = Future<Either<Failure, ShiftEntity>>.delayed(
        const Duration(milliseconds: 10),
        () => const Right(_saved),
      );
      when(() => repository.createShift(any())).thenAnswer((_) => pending);
      final cubit = create();
      fillValid(cubit);

      final first = cubit.submit();
      expect(cubit.state.status, ShiftFormStatus.saving);
      expect(await cubit.submit(), isNull);
      await first;

      verify(() => repository.createShift(any())).called(1);
      addTearDown(cubit.close);
    });
  });

  group('delete', () {
    test('does nothing when creating', () async {
      final cubit = create();
      expect(await cubit.delete(), isNull);
      verifyZeroInteractions(repository);
      addTearDown(cubit.close);
    });

    test('deletes by uid', () async {
      when(
        () => repository.deleteShift('a'),
      ).thenAnswer((_) async => const Right(null));
      final cubit = create(initial: _saved);

      final result = await cubit.delete();

      expect(result!.isRight(), isTrue);
      expect(cubit.state.status, ShiftFormStatus.editing);
      addTearDown(cubit.close);
    });

    test('returns the 409 message of a shift still in use', () async {
      when(() => repository.deleteShift('a')).thenAnswer(
        (_) async => const Left(
          ServerFailure('Shift masih dipakai 6 jadwal mulai hari ini.', 409),
        ),
      );
      final cubit = create(initial: _saved);

      final failure = (await cubit.delete())!.getLeft().toNullable()!;

      expect(failure.statusCode, 409);
      expect(failure.message, contains('6 jadwal'));
      addTearDown(cubit.close);
    });
  });
}

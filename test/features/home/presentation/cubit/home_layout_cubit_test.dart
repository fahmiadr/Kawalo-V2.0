import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:kawalo_mobile/features/home/domain/repositories/home_layout_repository.dart';
import 'package:kawalo_mobile/features/home/presentation/cubit/home_layout_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements HomeLayoutRepository {}

const _session = AuthSessionEntity(
  userId: 'u1',
  email: 'budi@kawalo.id',
  name: 'Budi',
  groupUid: 'g1',
  allowAdmin: false,
  allowPatrol: false,
  allowMonPatrol: false,
);
const _cached = HomeLayout(order: [HomeCard.sos, HomeCard.inc]);
const _server = HomeLayout(order: [HomeCard.inc, HomeCard.sos]);

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(HomeLayout.fallback));
  setUp(() => repository = _MockRepository());

  test('scope is user and group; none without a group', () {
    expect(HomeLayoutCubit.scopeOf(_session), 'u1@g1');
    expect(HomeLayoutCubit.scopeOf(null), isNull);
  });

  blocTest<HomeLayoutCubit, HomeLayout>(
    'load shows the cached layout first, then the server one',
    setUp: () {
      when(() => repository.cached('u1@g1')).thenAnswer((_) async => _cached);
      when(() => repository.load('u1@g1')).thenAnswer((_) async => _server);
    },
    build: () => HomeLayoutCubit(repository: repository),
    act: (cubit) => cubit.load(_session),
    expect: () => [_cached, _server],
  );

  blocTest<HomeLayoutCubit, HomeLayout>(
    'save applies at once and takes the server copy',
    setUp: () {
      when(() => repository.cached(any())).thenAnswer((_) async => null);
      when(
        () => repository.load(any()),
      ).thenAnswer((_) async => HomeLayout.fallback);
      when(
        () => repository.save('u1@g1', _cached),
      ).thenAnswer((_) async => _server);
    },
    build: () => HomeLayoutCubit(repository: repository),
    act: (cubit) async {
      await cubit.load(_session);
      await cubit.save(_cached);
    },
    skip: 1,
    expect: () => [_cached, _server],
  );

  blocTest<HomeLayoutCubit, HomeLayout>(
    'a save during a slow load is not overwritten by it',
    setUp: () {
      when(() => repository.cached(any())).thenAnswer((_) async => null);
      when(() => repository.load(any())).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 20),
          () => HomeLayout.fallback,
        ),
      );
      when(
        () => repository.save(any(), any()),
      ).thenAnswer((_) async => _cached);
    },
    build: () => HomeLayoutCubit(repository: repository),
    act: (cubit) async {
      final loading = cubit.load(_session);
      await Future<void>.delayed(Duration.zero);
      await cubit.save(_cached);
      await loading;
    },
    verify: (cubit) => expect(cubit.state, _cached),
  );
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/domain/repositories/group_repository.dart';
import 'package:kawalo_mobile/features/group/presentation/cubit/personnel_cubit.dart';
import 'package:kawalo_mobile/features/group/presentation/cubit/personnel_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements GroupRepository {}

const _budi = GroupMemberEntity(email: 'budi@test.id', name: 'Budi');

void main() {
  late _MockRepository repository;
  late PersonnelCubit cubit;

  setUp(() {
    repository = _MockRepository();
    cubit = PersonnelCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  void stub(Either<Failure, List<GroupMemberEntity>> result) {
    when(
      () => repository.getMembers(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => result);
  }

  Future<List<PersonnelState>> record(Future<void> Function() action) async {
    final states = <PersonnelState>[];
    final sub = cubit.stream.listen(states.add);
    await action();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return states;
  }

  test('starts initial', () {
    expect(cubit.state, const PersonnelInitial());
  });

  test('emits loading then loaded', () async {
    stub(const Right([_budi]));

    final states = await record(cubit.fetch);

    expect(states, const [
      PersonnelLoading(),
      PersonnelLoaded([_budi]),
    ]);
  });

  test('emits loaded with an empty list', () async {
    stub(const Right([]));

    final states = await record(cubit.fetch);

    expect(states.last, const PersonnelLoaded([]));
  });

  test('emits error and returns false on failure', () async {
    stub(const Left(NoInternetFailure()));

    late bool ok;
    final states = await record(() async => ok = await cubit.fetch());

    expect(ok, isFalse);
    expect(states.last, isA<PersonnelError>());
  });

  test('refresh keeps the content while loading', () async {
    stub(const Right([_budi]));
    await cubit.fetch();
    const ani = GroupMemberEntity(email: 'ani@test.id');
    stub(const Right([ani]));

    final states = await record(() => cubit.fetch(silent: true));

    expect(states, const [
      PersonnelLoaded([ani]),
    ]);
  });

  test('a failed refresh keeps the loaded content', () async {
    stub(const Right([_budi]));
    await cubit.fetch();
    stub(const Left(NoInternetFailure()));

    final ok = await cubit.fetch(silent: true);

    expect(ok, isFalse);
    expect(cubit.state, const PersonnelLoaded([_budi]));
  });

  test('a stale response does not overwrite a newer one', () async {
    final slow = Completer<Either<Failure, List<GroupMemberEntity>>>();
    var calls = 0;
    when(
      () => repository.getMembers(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer(
      (_) => ++calls == 1 ? slow.future : Future.value(const Right([_budi])),
    );

    final first = cubit.fetch();
    await cubit.fetch();
    slow.complete(const Right([]));

    expect(await first, isFalse);
    expect(cubit.state, const PersonnelLoaded([_budi]));
  });
}

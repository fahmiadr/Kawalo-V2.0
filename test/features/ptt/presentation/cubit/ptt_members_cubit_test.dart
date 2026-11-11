import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_channel_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/entities/ptt_member_entity.dart';
import 'package:kawalo_mobile/features/ptt/domain/repositories/ptt_member_repository.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_members_cubit.dart';
import 'package:kawalo_mobile/features/ptt/presentation/cubit/ptt_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../ptt_member_fixtures.dart';

class MockPttCubit extends MockCubit<PttState> implements PttCubit {}

class MockMemberRepository extends Mock implements PttMemberRepository {}

typedef _Members = Either<Failure, List<PttMemberEntity>>;

void main() {
  late MockPttCubit ptt;
  late MockMemberRepository repository;
  late StreamController<PttState> pttStates;

  setUp(() {
    ptt = MockPttCubit();
    repository = MockMemberRepository();
    pttStates = StreamController<PttState>.broadcast();
  });

  tearDown(() => pttStates.close());

  PttMembersCubit build(PttState initial) {
    whenListen(ptt, pttStates.stream, initialState: initial);
    return PttMembersCubit(repository: repository, ptt: ptt);
  }

  void stubMembers(List<PttMemberEntity> members) {
    when(
      () => repository.getMembers(),
    ).thenAnswer((_) async => Right<Failure, List<PttMemberEntity>>(members));
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);
  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  test('fetches at once when the channel is already connected', () async {
    stubMembers([member('a'), member('b')]);

    final cubit = build(idleState());
    await settle();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.members.map((m) => m.userId), ['a', 'b']);
    await cubit.close();
  });

  test('does not fetch while the channel is not connected', () async {
    final cubit = build(idleState(status: PttConnectionStatus.connecting));
    pttStates.add(idleState(status: PttConnectionStatus.reconnecting));
    await settle();

    verifyNever(() => repository.getMembers());
    expect(cubit.state.isLoading, isTrue);
    await cubit.close();
  });

  test('fetches once the channel connects', () async {
    stubMembers([member('a')]);
    final cubit = build(idleState(status: PttConnectionStatus.connecting));

    pttStates.add(idleState());
    await wait(700);

    verify(() => repository.getMembers()).called(1);
    expect(cubit.state.members, hasLength(1));
    await cubit.close();
  });

  test('a burst of count changes causes one debounced refetch', () async {
    stubMembers([member('a')]);
    final cubit = build(idleState(memberCount: 1));
    await settle();
    clearInteractions(repository);

    pttStates
      ..add(idleState(memberCount: 2))
      ..add(idleState(memberCount: 3))
      ..add(idleState(memberCount: 4));
    await wait(200);
    verifyNever(() => repository.getMembers());

    await wait(500);
    verify(() => repository.getMembers()).called(1);
    await cubit.close();
  });

  test('floor changes without a count change do not refetch', () async {
    stubMembers([member('a')]);
    final cubit = build(idleState(memberCount: 2));
    await settle();
    clearInteractions(repository);

    pttStates.add(listeningState(speakerId: 'a', memberCount: 2));
    await wait(700);

    verifyNever(() => repository.getMembers());
    await cubit.close();
  });

  test('a stale response cannot overwrite a newer list', () async {
    final slow = Completer<_Members>();
    var calls = 0;
    when(() => repository.getMembers()).thenAnswer((_) {
      calls++;
      return calls == 1
          ? slow.future
          : Future.value(
              Right<Failure, List<PttMemberEntity>>([member('new')]),
            );
    });
    final cubit = build(idleState(memberCount: 1));
    await settle();

    pttStates.add(idleState(memberCount: 2));
    await wait(700);
    expect(cubit.state.members.map((m) => m.userId), ['new']);

    slow.complete(Right<Failure, List<PttMemberEntity>>([member('old')]));
    await settle();

    expect(cubit.state.members.map((m) => m.userId), ['new']);
    await cubit.close();
  });

  test('a failed refetch keeps the last list and a retry recovers', () async {
    stubMembers([member('a')]);
    final cubit = build(idleState(memberCount: 1));
    await settle();

    when(() => repository.getMembers()).thenAnswer(
      (_) async =>
          const Left<Failure, List<PttMemberEntity>>(ServerFailure('gagal')),
    );
    pttStates.add(idleState(memberCount: 2));
    await wait(700);

    expect(cubit.state.failed, isTrue);
    expect(cubit.state.members.map((m) => m.userId), ['a']);

    stubMembers([member('a'), member('b')]);
    await cubit.retry();

    expect(cubit.state.failed, isFalse);
    expect(cubit.state.members, hasLength(2));
    await cubit.close();
  });

  test('closing cancels a pending debounced fetch', () async {
    stubMembers([member('a')]);
    final cubit = build(idleState(memberCount: 1));
    await settle();
    clearInteractions(repository);

    pttStates.add(idleState(memberCount: 2));
    await cubit.close();
    await wait(700);

    verifyNever(() => repository.getMembers());
  });
}

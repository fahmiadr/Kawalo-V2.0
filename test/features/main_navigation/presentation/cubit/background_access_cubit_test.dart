import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/background_access_service.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/cubit/background_access_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockBackgroundAccessService extends Mock
    implements BackgroundAccessService {}

const _missing = BackgroundAccessStatus(
  grants: {
    BackgroundAccessItem.notifications: BackgroundAccessGrant.askable,
    BackgroundAccessItem.microphone: BackgroundAccessGrant.granted,
    BackgroundAccessItem.battery: BackgroundAccessGrant.askable,
  },
);

const _afterRequest = BackgroundAccessStatus(
  grants: {
    BackgroundAccessItem.notifications: BackgroundAccessGrant.granted,
    BackgroundAccessItem.microphone: BackgroundAccessGrant.granted,
    BackgroundAccessItem.battery: BackgroundAccessGrant.refused,
  },
);

void main() {
  setUpAll(() => registerFallbackValue(BackgroundAccessItem.notifications));

  late MockBackgroundAccessService service;

  setUp(() {
    service = MockBackgroundAccessService();
    when(() => service.request(any())).thenAnswer((_) async => true);
    when(() => service.skip()).thenAnswer((_) async {});
  });

  blocTest<BackgroundAccessCubit, BackgroundAccessState>(
    'load without a native side leaves nothing to prompt',
    setUp: () => when(
      () => service.status(),
    ).thenThrow(MissingPluginException('no channel')),
    build: () => BackgroundAccessCubit(service: service),
    act: (cubit) => cubit.load(),
    expect: () => [const BackgroundAccessState()],
    verify: (cubit) => expect(cubit.state.shouldPrompt, isFalse),
  );

  blocTest<BackgroundAccessCubit, BackgroundAccessState>(
    'requestAll asks only the askable items, in order, and reloads',
    setUp: () {
      var reads = 0;
      when(
        () => service.status(),
      ).thenAnswer((_) async => reads++ == 0 ? _missing : _afterRequest);
    },
    build: () => BackgroundAccessCubit(service: service),
    act: (cubit) async {
      await cubit.load();
      await cubit.requestAll();
    },
    expect: () => [
      const BackgroundAccessState(status: _missing),
      const BackgroundAccessState(status: _missing, requesting: true),
      const BackgroundAccessState(status: _afterRequest),
    ],
    verify: (cubit) {
      verifyInOrder([
        () => service.request(BackgroundAccessItem.notifications),
        () => service.request(BackgroundAccessItem.battery),
      ]);
      verifyNever(() => service.request(BackgroundAccessItem.microphone));
      expect(cubit.state.shouldPrompt, isFalse);
    },
  );

  blocTest<BackgroundAccessCubit, BackgroundAccessState>(
    'one failing request does not stop the next',
    setUp: () {
      when(() => service.status()).thenAnswer((_) async => _missing);
      when(
        () => service.request(BackgroundAccessItem.notifications),
      ).thenThrow(PlatformException(code: 'x'));
    },
    build: () => BackgroundAccessCubit(service: service),
    act: (cubit) async {
      await cubit.load();
      await cubit.requestAll();
    },
    verify: (_) =>
        verify(() => service.request(BackgroundAccessItem.battery)).called(1),
  );

  test('skip is remembered natively', () async {
    final cubit = BackgroundAccessCubit(service: service);
    await cubit.skip();
    verify(() => service.skip()).called(1);
    await cubit.close();
  });
}

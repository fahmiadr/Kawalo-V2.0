import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:kawalo_mobile/features/auth/presentation/cubit/saved_email_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;

  setUp(() => storage = MockSecureStorageService());

  blocTest<SavedEmailCubit, String?>(
    'emits the saved email',
    setUp: () => when(storage.getLastEmail).thenAnswer((_) async => 'a@k.id'),
    build: () => SavedEmailCubit(storage),
    act: (cubit) => cubit.load(),
    expect: () => ['a@k.id'],
  );

  blocTest<SavedEmailCubit, String?>(
    'emits nothing when no email is saved',
    setUp: () => when(storage.getLastEmail).thenAnswer((_) async => null),
    build: () => SavedEmailCubit(storage),
    act: (cubit) => cubit.load(),
    expect: () => <String?>[],
  );

  blocTest<SavedEmailCubit, String?>(
    'emits nothing for an empty email',
    setUp: () => when(storage.getLastEmail).thenAnswer((_) async => ''),
    build: () => SavedEmailCubit(storage),
    act: (cubit) => cubit.load(),
    expect: () => <String?>[],
  );

  blocTest<SavedEmailCubit, String?>(
    'swallows storage failures',
    setUp: () => when(storage.getLastEmail).thenThrow(StateError('boom')),
    build: () => SavedEmailCubit(storage),
    act: (cubit) => cubit.load(),
    expect: () => <String?>[],
  );

  blocTest<SavedEmailCubit, String?>(
    'does nothing without storage',
    build: () => SavedEmailCubit(null),
    act: (cubit) => cubit.load(),
    expect: () => <String?>[],
  );
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/cubit/theme_mode_cubit.dart';
import 'package:kawalo_mobile/core/storage/secure_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;

  setUp(() {
    storage = MockSecureStorageService();
    when(() => storage.saveThemeMode(any())).thenAnswer((_) async {});
  });

  test('defaults to light', () {
    expect(ThemeModeCubit(storage).state, ThemeMode.light);
  });

  blocTest<ThemeModeCubit, ThemeMode>(
    'load emits the saved mode',
    setUp: () => when(storage.getThemeMode).thenAnswer((_) async => 'dark'),
    build: () => ThemeModeCubit(storage),
    act: (cubit) => cubit.load(),
    expect: () => [ThemeMode.dark],
  );

  blocTest<ThemeModeCubit, ThemeMode>(
    'load keeps light when nothing is saved',
    setUp: () => when(storage.getThemeMode).thenAnswer((_) async => null),
    build: () => ThemeModeCubit(storage),
    act: (cubit) => cubit.load(),
    expect: () => <ThemeMode>[],
  );

  blocTest<ThemeModeCubit, ThemeMode>(
    'load ignores an unknown value and storage failures',
    setUp: () => when(storage.getThemeMode).thenAnswer((_) async => 'neon'),
    build: () => ThemeModeCubit(storage),
    act: (cubit) async {
      await cubit.load();
      when(storage.getThemeMode).thenThrow(StateError('boom'));
      await cubit.load();
    },
    expect: () => <ThemeMode>[],
  );

  blocTest<ThemeModeCubit, ThemeMode>(
    'select emits and persists the mode',
    build: () => ThemeModeCubit(storage),
    act: (cubit) => cubit.select(ThemeMode.system),
    expect: () => [ThemeMode.system],
    verify: (_) => verify(() => storage.saveThemeMode('system')).called(1),
  );

  blocTest<ThemeModeCubit, ThemeMode>(
    'select still emits when persisting fails',
    setUp: () =>
        when(() => storage.saveThemeMode(any())).thenThrow(StateError('x')),
    build: () => ThemeModeCubit(storage),
    act: (cubit) => cubit.select(ThemeMode.dark),
    expect: () => [ThemeMode.dark],
  );
}

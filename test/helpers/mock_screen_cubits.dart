import 'package:bloc_test/bloc_test.dart';
import 'package:kawalo_mobile/core/network/app_fetch_result.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_state.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_state.dart';
import 'package:mocktail/mocktail.dart';

/// Mock [InformationCubit] untuk tes yang merender `MainNavigationScreen`
/// secara tidak langsung (navigasi dari splash, login, atau pilih grup).
class MockInformationCubit extends MockCubit<InformationState>
    implements InformationCubit {}

/// Mock [GuestCubit] untuk tes yang menavigasi ke `GuestScreen`.
class MockGuestCubit extends MockCubit<GuestState> implements GuestCubit {}

/// Membuat [MockInformationCubit] yang siap pakai: state termuat kosong dan
/// `fetchInformation` berhasil tanpa efek samping.
MockInformationCubit createStubbedInformationCubit() {
  final cubit = MockInformationCubit();
  when(
    () => cubit.state,
  ).thenReturn(const InformationLoaded(information: [], lastSync: 'Baru saja'));
  when(cubit.fetchInformation).thenAnswer((_) async => AppFetchResult.success);
  return cubit;
}

/// Membuat [MockGuestCubit] yang siap pakai: state termuat kosong dan
/// `fetchGuests` berhasil tanpa efek samping.
MockGuestCubit createStubbedGuestCubit() {
  final cubit = MockGuestCubit();
  when(
    () => cubit.state,
  ).thenReturn(const GuestLoaded(guests: [], lastSync: 'Baru saja'));
  when(cubit.fetchGuests).thenAnswer((_) async => AppFetchResult.success);
  return cubit;
}

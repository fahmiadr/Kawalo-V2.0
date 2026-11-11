import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/features/guest/domain/entities/guest_item_entity.dart';
import 'package:kawalo_mobile/features/guest/domain/repositories/guest_repository.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_params.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/create_guest/create_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/domain/usecases/update_guest/update_guest_usecase.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_cubit.dart';
import 'package:kawalo_mobile/features/guest/presentation/cubit/guest_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:mocktail/mocktail.dart';

import '../../../information/upload_test_helpers.dart';

class _MockCreate extends Mock implements CreateGuestUseCase {}

class _MockUpdate extends Mock implements UpdateGuestUseCase {}

class _MockGuestRepo extends Mock implements GuestRepository {}

void main() {
  const saved = GuestItemEntity(id: '1', guestName: 'Budi');
  const photo = InformationFormMediaItem(
    id: 'p',
    name: 'budi.jpg',
    path: '/tmp/budi.jpg',
  );

  late _MockCreate create;
  late FakeUploadRepository uploads;

  setUpAll(() {
    registerFallbackValue(
      const CreateGuestParams(
        guestName: 'x',
        guestDestination: 'x',
        guestType: 'x',
      ),
    );
  });

  setUp(() {
    create = _MockCreate();
    uploads = FakeUploadRepository();
    when(() => create(any())).thenAnswer((_) async => const Right(saved));
  });

  GuestFormCubit build() {
    final guests = _MockGuestRepo();
    when(
      () => guests.getMasterGuestTypes(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer((_) async => const Right([]));
    return GuestFormCubit(
        createGuestUseCase: create,
        updateGuestUseCase: _MockUpdate(),
        guestRepository: guests,
        uploadRepository: uploads,
      )
      ..onNameChanged('Budi')
      ..onDestinationChanged('Blok A')
      ..onGuestTypeChanged('TAMU')
      ..onPhotoMediaChanged(photo);
  }

  CreateGuestParams sentParams() =>
      verify(() => create(captureAny())).captured.single as CreateGuestParams;

  test('uploads the local photo and sends only the hosted url', () async {
    final cubit = build();

    await cubit.submit();

    expect(uploads.images, ['budi.jpg']);
    expect(sentParams().guestPhoto, 'https://cdn.test/budi.jpg');
    expect(cubit.state.status, GuestFormStatus.success);
    expect(cubit.state.photoMedia?.uploadStatus, MediaUploadStatus.done);
    await cubit.close();
  });

  test('a failed upload stops the request and retry succeeds', () async {
    uploads.failing.add('budi.jpg');
    final cubit = build();

    await cubit.submit();

    expect(cubit.state.status, GuestFormStatus.failure);
    expect(cubit.state.errorMessage, contains('1 berkas gagal diunggah'));
    expect(cubit.state.photoMedia?.uploadStatus, MediaUploadStatus.failed);
    verifyNever(() => create(any()));

    uploads.healAfterFirstAttempt();
    await cubit.submit();

    expect(uploads.images, ['budi.jpg', 'budi.jpg']);
    expect(cubit.state.status, GuestFormStatus.success);
    await cubit.close();
  });

  test('a guest without a photo uploads nothing', () async {
    final cubit = build()..onRemovePhoto();

    await cubit.submit();

    expect(uploads.images, isEmpty);
    expect(sentParams().guestPhoto, isNull);
    await cubit.close();
  });
}

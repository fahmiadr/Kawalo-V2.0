import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:mocktail/mocktail.dart';

import '../../upload_test_helpers.dart';

class _MockCreate extends Mock implements CreateInformationUseCase {}

class _MockUpdate extends Mock implements UpdateInformationUseCase {}

InformationFormMediaItem _photo(String name) => InformationFormMediaItem(
  id: name,
  name: name,
  path: '/tmp/$name',
  fileSize: 1000,
);

void main() {
  const session = AuthSessionEntity(
    userId: '1',
    email: 'admin@kawalo.id',
    name: 'Admin',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );
  const created = InformationItemEntity(id: '1', photos: [], title: 'Judul');

  late _MockCreate create;
  late FakeUploadRepository uploads;

  setUpAll(() {
    registerFallbackValue(const CreateInformationParams(title: 'x'));
  });

  setUp(() {
    create = _MockCreate();
    uploads = FakeUploadRepository();
    when(() => create(any())).thenAnswer((_) async => const Right(created));
  });

  InformationFormCubit build() => InformationFormCubit(
    createInformationUseCase: create,
    updateInformationUseCase: _MockUpdate(),
    uploadRepository: uploads,
  )..onTitleChanged('Judul');

  CreateInformationParams sentParams() =>
      verify(() => create(captureAny())).captured.single
          as CreateInformationParams;

  test(
    'uploads photos and document first, payload only has hosted urls',
    () async {
      final cubit = build()
        ..onAddMediaPhotos([_photo('a.jpg'), _photo('b.jpg')])
        ..onSetDocumentMedia(
          const InformationFormMediaItem(
            id: 'd',
            name: 'sop.pdf',
            path: '/t/d',
          ),
        );

      await cubit.submit(session: session);

      expect(uploads.images, ['a.jpg', 'b.jpg']);
      expect(uploads.documents, ['sop.pdf']);
      final params = sentParams();
      expect(params.photos, [
        'https://cdn.test/a.jpg',
        'https://cdn.test/b.jpg',
      ]);
      expect(params.feedFile, 'https://cdn.test/sop.pdf');
      expect(cubit.state.status, InformationFormStatus.success);
      expect(
        cubit.state.photos.map((p) => p.uploadStatus),
        everyElement(MediaUploadStatus.done),
      );
      await cubit.close();
    },
  );

  test(
    'a rejected document stops the submit before any photo is sent',
    () async {
      uploads.failing.add('besar.pdf');
      final cubit = build()
        ..onAddMediaPhotos([_photo('a.jpg'), _photo('b.jpg')])
        ..onSetDocumentMedia(
          const InformationFormMediaItem(
            id: 'd',
            name: 'besar.pdf',
            path: '/t/d',
          ),
        );

      await cubit.submit(session: session);

      expect(uploads.documents, ['besar.pdf']);
      expect(uploads.images, isEmpty);
      expect(cubit.state.status, InformationFormStatus.failure);
      expect(cubit.state.errorMessage, contains('1 berkas gagal diunggah'));
      expect(cubit.state.documentMedia?.uploadStatus, MediaUploadStatus.failed);
      expect(
        cubit.state.photos.map((p) => p.uploadStatus),
        everyElement(MediaUploadStatus.idle),
      );
      verifyNever(() => create(any()));
      await cubit.close();
    },
  );

  test(
    'partial failure blocks the request; retry uploads only failed files',
    () async {
      uploads.failing.add('b.jpg');
      final cubit = build()
        ..onAddMediaPhotos([_photo('a.jpg'), _photo('b.jpg')]);

      await cubit.submit(session: session);

      expect(cubit.state.status, InformationFormStatus.failure);
      expect(cubit.state.errorMessage, contains('1 berkas gagal diunggah'));
      expect(cubit.state.photos[0].uploadStatus, MediaUploadStatus.done);
      expect(cubit.state.photos[1].uploadStatus, MediaUploadStatus.failed);
      expect(cubit.state.photos[1].uploadError, 'Koneksi terputus.');
      verifyNever(() => create(any()));

      uploads.healAfterFirstAttempt();
      await cubit.submit(session: session);

      expect(uploads.images, ['a.jpg', 'b.jpg', 'b.jpg']);
      expect(sentParams().photos, [
        'https://cdn.test/a.jpg',
        'https://cdn.test/b.jpg',
      ]);
      expect(cubit.state.status, InformationFormStatus.success);
      await cubit.close();
    },
  );

  test(
    'runs at most three uploads at once and locks submit meanwhile',
    () async {
      final gate = Completer<void>();
      uploads.gate = gate.future;
      final cubit = build()
        ..onAddMediaPhotos([
          _photo('1.jpg'),
          _photo('2.jpg'),
          _photo('3.jpg'),
          _photo('4.jpg'),
        ]);

      final submitting = cubit.submit(session: session);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.canPressSubmit, isFalse);
      expect(
        cubit.state.photos.where(
          (p) => p.uploadStatus == MediaUploadStatus.uploading,
        ),
        hasLength(3),
      );
      expect(cubit.state.photos.last.uploadStatus, MediaUploadStatus.idle);

      await cubit.submit(session: session); // ignored while in flight
      expect(uploads.images, hasLength(3));

      gate.complete();
      await submitting;

      expect(uploads.maxInFlight, 3);
      expect(uploads.images, hasLength(4));
      expect(cubit.state.status, InformationFormStatus.success);
      await cubit.close();
    },
  );

  test('remote attachments are not uploaded again', () async {
    final cubit = build()..onAddPhoto('https://cdn.test/old.webp');

    await cubit.submit(session: session);

    expect(uploads.images, isEmpty);
    expect(sentParams().photos, ['https://cdn.test/old.webp']);
    await cubit.close();
  });
}

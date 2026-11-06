import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_state.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateInformationUseCase extends Mock
    implements CreateInformationUseCase {}

class MockUpdateInformationUseCase extends Mock
    implements UpdateInformationUseCase {}

void main() {
  late MockCreateInformationUseCase mockCreateUseCase;
  late MockUpdateInformationUseCase mockUpdateUseCase;

  const dummySession = AuthSessionEntity(
    userId: '1',
    email: 'admin@kawalo.id',
    name: 'Admin',
    role: 'ADMIN',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  const dummyItem = InformationItemEntity(
    id: '10',
    title: 'Pengumuman Penting',
    text: 'Harap seluruh personil berkumpul.',
    photos: ['https://example.com/photo1.jpg'],
    feedType: 'EVENT',
    feedFile: 'https://example.com/doc.pdf',
    eventLocation: 'Gedung Utama',
    glat: -6.2088,
    glong: 106.8456,
  );

  setUpAll(() {
    registerFallbackValue(
      const CreateInformationParams(
        title: 'Fallback Title',
      ),
    );
    registerFallbackValue(
      const UpdateInformationParams(
        id: '1',
      ),
    );
  });

  setUp(() {
    mockCreateUseCase = MockCreateInformationUseCase();
    mockUpdateUseCase = MockUpdateInformationUseCase();
  });

  group('InformationFormCubit - Initialization', () {
    test('initializes in create mode when initialItem is null', () {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      expect(cubit.state.isCreateMode, isTrue);
      expect(cubit.state.isUpdateMode, isFalse);
      expect(cubit.state.status, InformationFormStatus.ready);
      expect(cubit.state.title, isEmpty);
      expect(cubit.state.feedType, 'GENERAL');
      expect(cubit.state.photos, isEmpty);
      expect(cubit.state.isValid, isFalse); // title empty

      cubit.close();
    });

    test('initializes in update mode when initialItem is provided', () {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
        initialItem: dummyItem,
      );

      expect(cubit.state.isCreateMode, isFalse);
      expect(cubit.state.isUpdateMode, isTrue);
      expect(cubit.state.title, 'Pengumuman Penting');
      expect(cubit.state.text, 'Harap seluruh personil berkumpul.');
      expect(cubit.state.feedType, 'EVENT');
      expect(
        cubit.state.photos.map((p) => p.displaySource).toList(),
        ['https://example.com/photo1.jpg'],
      );
      expect(cubit.state.feedFile, 'https://example.com/doc.pdf');
      expect(cubit.state.documentMedia?.name, 'doc.pdf');
      expect(cubit.state.eventLocation, 'Gedung Utama');
      expect(cubit.state.glat, '-6.2088');
      expect(cubit.state.glong, '106.8456');
      expect(cubit.state.latitude, -6.2088);
      expect(cubit.state.longitude, 106.8456);
      expect(cubit.state.hasLocation, isTrue);
      expect(cubit.state.isValid, isTrue);
      expect(cubit.state.isDirty, isFalse);

      cubit.close();
    });
  });

  group('InformationFormCubit - Field Changes & Validation', () {
    test(
      'onTitleChanged updates title without premature error until submit',
      () async {
        // 1. Initial typing / clearing does NOT trigger premature titleError
        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        )..onTitleChanged('   ');

        expect(cubit.state.titleError, isNull);
        expect(cubit.state.isValid, isFalse);
        expect(cubit.state.canPressSubmit, isTrue);

        // 2. Submit triggers validation and highlights titleError
        await cubit.submit(session: dummySession);
        expect(cubit.state.titleError, isNotNull);
        expect(cubit.state.validationAttempt, 1);

        // 3. Subsequent typing revalidates live and clears error once valid
        cubit.onTitleChanged('Patroli Malam');
        expect(cubit.state.title, 'Patroli Malam');
        expect(cubit.state.titleError, isNull);
        expect(cubit.state.isValid, isTrue);

        await cubit.close();
      },
    );

    test('onFeedTypeChanged updates category and validates', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )..onFeedTypeChanged('INCIDENT');

      expect(cubit.state.feedType, 'INCIDENT');
      expect(cubit.state.feedTypeError, isNull);

      cubit.onFeedTypeChanged('INVALID_TYPE');
      expect(cubit.state.feedTypeError, isNotNull);

      await cubit.close();
    });

    test('onAddPhoto, onRemovePhoto, onClearAllPhotos, and onReorderPhotos',
        () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      expect(cubit.onAddPhoto('https://example.com/1.jpg'), isTrue);
      expect(cubit.onAddPhoto('https://example.com/2.jpg'), isTrue);
      expect(cubit.state.photos.length, 2);

      // Duplicate check
      expect(cubit.onAddPhoto('https://example.com/1.jpg'), isFalse);
      expect(cubit.state.photosError, isNotNull);

      expect(cubit.onAddPhoto('https://example.com/3.jpg'), isTrue);
      expect(cubit.onAddPhoto('https://example.com/4.jpg'), isTrue);

      // Max 4 photos check
      expect(cubit.onAddPhoto('https://example.com/5.jpg'), isFalse);
      expect(cubit.state.photos.length, 4);

      // Reorder photos: move index 0 to index 2
      cubit.onReorderPhotos(0, 2);
      expect(cubit.state.photos[2].displaySource, 'https://example.com/1.jpg');

      // Remove photo
      cubit.onRemovePhoto(0);
      expect(cubit.state.photos.length, 3);

      // Replace photo by ID
      final itemToReplace = cubit.state.photos.first;
      const replacement = InformationFormMediaItem(
        id: 'replacement_id',
        name: 'replaced.jpg',
        path: '/path/replaced.jpg',
      );
      final replaceSuccess = cubit.onReplacePhoto(
        targetId: itemToReplace.id,
        newItem: replacement,
      );
      expect(replaceSuccess, isTrue);
      expect(cubit.state.photos.first.id, 'replacement_id');

      // Remove photo by ID
      final removeByIdSuccess = cubit.onRemovePhotoById('replacement_id');
      expect(removeByIdSuccess, isTrue);
      expect(
        cubit.state.photos.any((p) => p.id == 'replacement_id'),
        isFalse,
      );

      // Clear all photos
      cubit.onClearAllPhotos();
      expect(cubit.state.photos, isEmpty);
      expect(cubit.state.photosError, isNull);

      await cubit.close();
    });

    test('submit is blocked when any photo is in loading state', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )
        ..onTitleChanged('Judul Valid')
        ..onTextChanged('Deskripsi valid')
        ..onAddMediaPhoto(
          InformationFormMediaItem.loading(
            id: 'loading_1',
          ),
        );

      expect(cubit.state.photos.first.isLoading, isTrue);

      await cubit.submit(session: dummySession);

      expect(
        cubit.state.photosError,
        'Tunggu hingga semua foto selesai diproses.',
      );
      expect(cubit.state.status, isNot(InformationFormStatus.submitting));

      await cubit.close();
    });

    test('onAddMediaPhotos adds multiple items and caps at 4', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      final photos = List.generate(
        5,
        (i) => InformationFormMediaItem(
          id: 'photo_$i',
          name: 'foto_$i.jpg',
          path: '/path/foto_$i.jpg',
        ),
      );

      final addedCount = cubit.onAddMediaPhotos(photos);

      expect(addedCount, 4);
      expect(cubit.state.photos.length, 4);
      expect(cubit.state.remainingPhotoSlots, 0);
      expect(cubit.state.isPhotoLimitReached, isTrue);
      expect(cubit.state.photosError, isNull);

      // Attempting to add more when full
      final extraAdded = cubit.onAddMediaPhotos([
        const InformationFormMediaItem(
          id: 'photo_extra',
          name: 'extra.jpg',
          path: '/path/extra.jpg',
        ),
      ]);

      expect(extraAdded, 0);
      expect(cubit.state.photosError, 'Maksimal 4 foto dapat dilampirkan.');

      await cubit.close();
    });

    test('onAddMediaPhotos filters duplicates', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      const photoA = InformationFormMediaItem(
        id: 'photo_a',
        name: 'a.jpg',
        path: '/path/a.jpg',
      );

      cubit.onAddMediaPhoto(photoA);
      expect(cubit.state.photos.length, 1);

      final addedCount = cubit.onAddMediaPhotos([
        photoA, // duplicate
        const InformationFormMediaItem(
          id: 'photo_b',
          name: 'b.jpg',
          path: '/path/b.jpg',
        ),
      ]);

      expect(addedCount, 1);
      expect(cubit.state.photos.length, 2);

      await cubit.close();
    });

    test('onSetLocationCoordinates and onClearLocationCoordinates', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      expect(cubit.state.hasLocation, isFalse);

      // Pre-fill nama lokasi tempat acara
      cubit.onEventLocationChanged('Pos Satpam');
      expect(cubit.state.eventLocation, 'Pos Satpam');

      // Pasang koordinat GPS / Peta - eventLocation TIDAK boleh termutasi
      cubit.onSetLocationCoordinates(
        lat: -6.2088,
        lng: 106.8456,
      );

      expect(cubit.state.hasLocation, isTrue);
      expect(cubit.state.latitude, -6.2088);
      expect(cubit.state.longitude, 106.8456);
      expect(cubit.state.eventLocation, 'Pos Satpam');

      // Hapus koordinat - eventLocation tetap dipertahankan
      cubit.onClearLocationCoordinates();
      expect(cubit.state.hasLocation, isFalse);
      expect(cubit.state.latitude, isNull);
      expect(cubit.state.longitude, isNull);
      expect(cubit.state.eventLocation, 'Pos Satpam');

      await cubit.close();
    });

    test('onSetDocumentMedia and onClearDocumentMedia', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      expect(cubit.state.documentMedia, isNull);

      const media = InformationFormMediaItem(
        id: 'doc-1',
        name: 'laporan.pdf',
      );
      cubit.onSetDocumentMedia(media);

      expect(cubit.state.documentMedia, media);
      expect(cubit.state.feedFile, 'laporan.pdf');

      cubit.onClearDocumentMedia();
      expect(cubit.state.documentMedia, isNull);
      expect(cubit.state.feedFile, isEmpty);

      await cubit.close();
    });

    test('onGlatChanged and onGlongChanged validate coordinates', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )..onGlatChanged('100.5'); // out of range
      expect(cubit.state.glatError, isNotNull);

      cubit.onGlatChanged('-6.2088');
      expect(cubit.state.glatError, isNull);

      cubit.onGlongChanged('200.0'); // out of range
      expect(cubit.state.glongError, isNotNull);

      cubit.onGlongChanged('106.8456');
      expect(cubit.state.glongError, isNull);

      await cubit.close();
    });
  });

  group('InformationFormCubit - Submit', () {
    test('submit create succeeds and emits success', () async {
      when(() => mockCreateUseCase(any())).thenAnswer(
        (_) async => const Right(dummyItem),
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )
        ..onTitleChanged('Patroli Pos A')
        ..onTextChanged('Kondisi terkendali.');

      await cubit.submit(session: dummySession);

      expect(cubit.state.status, InformationFormStatus.success);
      expect(cubit.state.createdOrUpdatedItem, dummyItem);
      verify(() => mockCreateUseCase(any())).called(1);

      await cubit.close();
    });

    test('submit update succeeds and emits success', () async {
      when(() => mockUpdateUseCase(any())).thenAnswer(
        (_) async => const Right(dummyItem),
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
        initialItem: dummyItem,
      )..onTitleChanged('Judul Baru Diperbarui');

      await cubit.submit(session: dummySession);

      expect(cubit.state.status, InformationFormStatus.success);
      expect(cubit.state.createdOrUpdatedItem, dummyItem);
      verify(() => mockUpdateUseCase(any())).called(1);

      await cubit.close();
    });

    test('submit emits failure when use case returns Failure', () async {
      when(() => mockCreateUseCase(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Gagal menyimpan ke server.')),
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )..onTitleChanged('Pengumuman');

      await cubit.submit(session: dummySession);

      expect(cubit.state.status, InformationFormStatus.failure);
      expect(cubit.state.errorMessage, 'Gagal menyimpan ke server.');

      await cubit.close();
    });

    test(
      'submit in update mode sends empty photos list when photos are cleared',
      () async {
      UpdateInformationParams? capturedParams;
      when(() => mockUpdateUseCase(any())).thenAnswer(
        (invocation) async {
          capturedParams =
              invocation.positionalArguments[0] as UpdateInformationParams;
          return const Right(dummyItem);
        },
      );

      const itemWithPhotos = InformationItemEntity(
        id: '10',
        title: 'Pengumuman',
        photos: ['photo1.jpg', 'photo2.jpg'],
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
        initialItem: itemWithPhotos,
      );

      expect(cubit.state.photos.length, 2);
      expect(cubit.state.canSubmit, isFalse); // not dirty yet

      cubit.onClearAllPhotos();
      expect(cubit.state.photos, isEmpty);
      expect(cubit.state.isDirty, isTrue);
      expect(cubit.state.canSubmit, isTrue);

      await cubit.submit(session: dummySession);

      expect(cubit.state.status, InformationFormStatus.success);
      expect(capturedParams, isNotNull);
      expect(capturedParams!.photos, isEmpty); // verifies [] is sent, not null!

      await cubit.close();
    });

    test('validates coordinate pairing and blocks submit if partial', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )
        ..onTitleChanged('Kegiatan Warga')
        ..onGlatChanged('-6.2088'); // glat without glong

      expect(cubit.state.isValid, isFalse);
      expect(cubit.state.canSubmit, isFalse);

      await cubit.submit(session: dummySession);

      expect(cubit.state.status, isNot(InformationFormStatus.submitting));
      expect(cubit.state.glongError, isNotNull);
      verifyNever(() => mockCreateUseCase(any()));

      cubit.onGlongChanged('106.8456');
      expect(cubit.state.isValid, isTrue);
      expect(cubit.state.canSubmit, isTrue);

      await cubit.close();
    });

    test('canSubmit evaluates loading photos correctly', () async {
      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )..onTitleChanged('Kegiatan');

      expect(cubit.state.canSubmit, isTrue);

      const loadingPhoto = InformationFormMediaItem(
        id: 'p1',
        name: 'photo.jpg',
        isLoading: true,
      );
      cubit.onAddMediaPhoto(loadingPhoto);

      expect(cubit.state.canSubmit, isFalse);

      await cubit.close();
    });
  });
}

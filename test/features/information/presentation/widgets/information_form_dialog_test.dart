import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/services/app_launcher_service.dart';
import 'package:kawalo_mobile/core/services/location_service.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_image_viewer.dart';
import 'package:kawalo_mobile/core/widgets/app_map_picker_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/features/information/domain/entities/information_item_entity.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_params.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateInformationUseCase extends Mock
    implements CreateInformationUseCase {}

class MockUpdateInformationUseCase extends Mock
    implements UpdateInformationUseCase {}

class MockMediaPickerService extends Mock implements MediaPickerService {}

class MockReverseGeocodeService extends Mock implements ReverseGeocodeService {}

Widget _buildFormTestApp({
  required InformationFormCubit cubit,
  MediaPickerService? mediaPickerService,
  Future<LocationResult> Function()? locationProvider,
  ReverseGeocodeService? reverseGeocodeService,
  AppLauncherService launcherService = const DefaultAppLauncherService(),
  Future<bool> Function()? openAppSettingsFn,
  Future<bool> Function()? openLocationSettingsFn,
}) {
  return MaterialApp(
    builder: (context, child) => M3ETheme(
      data: AppTheme.m3eLight(),
      child: child!,
    ),
    home: Scaffold(
      body: InformationFormDialog(
        cubit: cubit,
        mediaPickerService: mediaPickerService,
        locationProvider: locationProvider,
        reverseGeocodeService: reverseGeocodeService,
        launcherService: launcherService,
        openAppSettingsFn: openAppSettingsFn,
        openLocationSettingsFn: openLocationSettingsFn,
      ),
    ),
  );
}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  late MockCreateInformationUseCase mockCreateUseCase;
  late MockUpdateInformationUseCase mockUpdateUseCase;
  late MockMediaPickerService mockMediaPicker;

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
    photos: [],
    feedType: 'EVENT',
    feedFile: 'https://example.com/doc.pdf',
    eventLocation: 'Gedung Utama',
    glat: -6.2088,
    glong: 106.8456,
  );

  Position dummyPosition({
    double latitude = -6.2088,
    double longitude = 106.8456,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime(2026),
      accuracy: 5,
      altitude: 10,
      altitudeAccuracy: 5,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(
      const CreateInformationParams(
        title: 'Fallback',
        session: dummySession,
      ),
    );
    registerFallbackValue(
      const UpdateInformationParams(
        id: '10',
        title: 'Fallback',
        session: dummySession,
        item: dummyItem,
      ),
    );
  });

  setUp(() {
    mockCreateUseCase = MockCreateInformationUseCase();
    mockUpdateUseCase = MockUpdateInformationUseCase();
    mockMediaPicker = MockMediaPickerService();
  });

  void configureTestView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('InformationFormDialog Widget Tests', () {
    testWidgets('renders create form with empty fields and default category',
        (tester) async {
      configureTestView(tester);

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      // Card titles
      expect(find.text('Detail publikasi'), findsOneWidget);
      expect(find.text('Dokumentasi foto (0/4)'), findsOneWidget);
      expect(find.text('Dokumen lampiran (maksimal 1)'), findsOneWidget);
      expect(find.text('Lokasi kegiatan dan titik peta'), findsOneWidget);

      // Category chips
      expect(find.text('Informasi Umum'), findsOneWidget);
      expect(find.text('Personil Baru'), findsOneWidget);
      expect(find.text('Acara'), findsOneWidget);
      expect(find.text('Insiden'), findsOneWidget);
      expect(find.text('Lainnya'), findsOneWidget);

      // Placeholders
      expect(find.text('Belum ada foto terlampir'), findsOneWidget);
      expect(find.text('Belum ada dokumen'), findsOneWidget);
      expect(find.text('Belum ada titik lokasi'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders update form with populated fields and AppStaticMap',
        (tester) async {
      configureTestView(tester);

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
        initialItem: dummyItem,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengumuman Penting'), findsOneWidget);
      expect(find.text('Harap seluruh personil berkumpul.'), findsOneWidget);
      expect(find.text('Gedung Utama'), findsOneWidget);
      expect(find.byType(AppStaticMap), findsOneWidget);
      expect(find.text('Ubah lokasi'), findsOneWidget);
      expect(find.text('Hapus titik'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('selecting category chip updates cubit state', (tester) async {
      configureTestView(tester);

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      expect(cubit.state.feedType, 'GENERAL');

      // Tap 'Acara' chip
      await tester.tap(find.text('Acara'));
      await tester.pumpAndSettle();

      expect(cubit.state.feedType, 'EVENT');

      // Tap 'Insiden' chip
      await tester.tap(find.text('Insiden'));
      await tester.pumpAndSettle();

      expect(cubit.state.feedType, 'INCIDENT');

      await cubit.close();
    });

    testWidgets('entering title updates cubit and clears empty error',
        (tester) async {
      configureTestView(tester);

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.byType(EditableText);
      expect(titleFinder, findsWidgets);

      await tester.enterText(titleFinder.first, 'Info Baru');
      await tester.pumpAndSettle();

      expect(cubit.state.title, 'Info Baru');
      expect(cubit.state.titleError, isNull);

      await cubit.close();
    });

    testWidgets(
      'validation UX: no premature error on focus or typing, '
      'submit triggers error & focuses field, live correction clears error',
      (tester) async {
        configureTestView(tester);

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
          ),
        );
        await tester.pumpAndSettle();

        final titleFinder = find.byType(EditableText).first;

        // 1. Focusing and entering whitespace does NOT trigger error
        await tester.tap(titleFinder);
        await tester.pumpAndSettle();
        expect(find.text('Judul informasi wajib diisi'), findsNothing);

        await tester.enterText(titleFinder, '   ');
        await tester.pumpAndSettle();
        expect(find.text('Judul informasi wajib diisi'), findsNothing);

        // 2. Submit attempt triggers validation error & focuses title field
        await cubit.submit(session: dummySession);
        await tester.pumpAndSettle();

        expect(find.text('Judul informasi wajib diisi'), findsOneWidget);
        final titleEditable = tester.widget<EditableText>(titleFinder);
        expect(titleEditable.focusNode.hasFocus, isTrue);

        // 3. Live correction: typing valid text clears error immediately
        await tester.enterText(titleFinder, 'Informasi Patroli');
        await tester.pumpAndSettle();

        expect(find.text('Judul informasi wajib diisi'), findsNothing);
        expect(cubit.state.title, 'Informasi Patroli');
        expect(cubit.state.titleError, isNull);

        await cubit.close();
      },
    );

    testWidgets('opens photo bottom sheet and picks photo from camera',
        (tester) async {
      configureTestView(tester);

      when(
        () => mockMediaPicker.captureMultiImagesFromCamera(
          any(),
          maxPhotos: any(named: 'maxPhotos'),
          alreadyAttachedCount: any(named: 'alreadyAttachedCount'),
        ),
      ).thenAnswer(
        (_) async => const [
          AppMediaFile(
            name: 'foto_kamera.jpg',
            path: '/path/foto_kamera.jpg',
          ),
        ],
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Belum ada foto terlampir'
      await tester.tap(find.text('Belum ada foto terlampir'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih sumber foto'), findsOneWidget);
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);

      // Tap 'Kamera'
      await tester.tap(find.text('Kamera'));
      await tester.pumpAndSettle();

      expect(cubit.state.photos.length, 1);
      expect(cubit.state.photos.first.name, 'foto_kamera.jpg');

      await cubit.close();
    });

    testWidgets('opens photo bottom sheet and picks multi photos from gallery',
        (tester) async {
      configureTestView(tester);

      when(
        () => mockMediaPicker.pickMultiImagesFromGallery(
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const [
          AppMediaFile(
            name: 'gallery1.jpg',
            path: '/path/gallery1.jpg',
          ),
          AppMediaFile(
            name: 'gallery2.jpg',
            path: '/path/gallery2.jpg',
          ),
        ],
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Belum ada foto terlampir'
      await tester.tap(find.text('Belum ada foto terlampir'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih sumber foto'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);

      // Tap 'Galeri'
      await tester.tap(find.text('Galeri'));
      await tester.pumpAndSettle();

      expect(cubit.state.photos.length, 2);
      expect(cubit.state.photos[0].name, 'gallery1.jpg');
      expect(cubit.state.photos[1].name, 'gallery2.jpg');
      expect(find.text('Dokumentasi foto (2/4)'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('picks document file and renders document tile',
        (tester) async {
      configureTestView(tester);

      when(() => mockMediaPicker.pickDocumentFile()).thenAnswer(
        (_) async => const AppMediaFile(
          name: 'laporan_kegiatan.pdf',
          path: '/path/laporan_kegiatan.pdf',
        ),
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Belum ada dokumen'
      await tester.tap(find.text('Belum ada dokumen'));
      await tester.pumpAndSettle();

      expect(find.text('laporan_kegiatan.pdf'), findsOneWidget);
      expect(cubit.state.documentMedia?.name, 'laporan_kegiatan.pdf');

      await cubit.close();
    });

    testWidgets('clearing location coordinates removes AppStaticMap',
        (tester) async {
      configureTestView(tester);

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
        initialItem: dummyItem,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppStaticMap), findsOneWidget);
      expect(find.text('Ubah lokasi'), findsOneWidget);
      expect(find.text('Hapus titik'), findsOneWidget);

      // Tap 'Hapus titik'
      await tester.tap(find.text('Hapus titik'));
      await tester.pumpAndSettle();

      expect(find.byType(AppStaticMap), findsNothing);
      expect(find.text('Belum ada titik lokasi'), findsOneWidget);
      expect(cubit.state.hasLocation, isFalse);

      await cubit.close();
    });

    testWidgets(
        'tapping empty location placeholder opens location bottom sheet',
        (tester) async {
      configureTestView(tester);

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada titik lokasi'), findsOneWidget);

      await tester.tap(find.text('Belum ada titik lokasi'));
      await tester.pumpAndSettle();

      expect(find.text('Tentukan titik lokasi'), findsOneWidget);
      expect(find.text('Lokasi saat ini'), findsOneWidget);
      expect(find.text('Pilih di peta'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
        'renders GridView with 2 columns and opens AppImageViewer on tap',
        (tester) async {
      configureTestView(tester);

      when(
        () => mockMediaPicker.captureMultiImagesFromCamera(
          any(),
          maxPhotos: any(named: 'maxPhotos'),
          alreadyAttachedCount: any(named: 'alreadyAttachedCount'),
        ),
      ).thenAnswer(
        (_) async => const [
          AppMediaFile(
            name: 'foto1.jpg',
            path: '/path/foto1.jpg',
          ),
        ],
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Belum ada foto terlampir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kamera'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap thumbnail photo to open AppImageViewer
      await tester.tap(
        find.byKey(const ValueKey<String>('photo_thumbnail_0')),
      );
      await tester.pumpAndSettle();

      final viewerFinder = find.byType(AppImageViewer);
      expect(viewerFinder, findsOneWidget);
      final viewer = tester.widget<AppImageViewer>(viewerFinder);
      expect(viewer.heroTagPrefix, 'info_form_photo');

      await cubit.close();
    });

    testWidgets('shows snackbar error when submit fails', (tester) async {
      configureTestView(tester);

      when(() => mockCreateUseCase.call(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Gagal membuat postingan')),
      );

      final cubit = InformationFormCubit(
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      );

      await tester.pumpWidget(
        _buildFormTestApp(
          cubit: cubit,
          mediaPickerService: mockMediaPicker,
        ),
      );
      await tester.pumpAndSettle();

      cubit.onTitleChanged('Post Baru');
      await cubit.submit(session: dummySession);
      await tester.pumpAndSettle();

      expect(find.text('Gagal membuat postingan'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      'displays LocationActionableError bottom sheet when GPS is disabled '
      'and navigates to AppMapPickerDialog on tapping secondary action',
      (tester) async {
        configureTestView(tester);

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
            locationProvider: () async =>
                const LocationResult.serviceDisabled(),
          ),
        );
        await tester.pumpAndSettle();

        // Buka bottom sheet pemilihan sumber lokasi
        final locationPlaceholder = find.text('Belum ada titik lokasi');
        await tester.ensureVisible(locationPlaceholder);
        await tester.tap(locationPlaceholder);
        await tester.pumpAndSettle();

        // Ketuk opsi "Lokasi saat ini"
        await tester.tap(find.text('Lokasi saat ini'));
        await tester.pumpAndSettle();

        // Verifikasi bahwa modal bottom sheet LocationActionableError muncul
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);
        expect(find.text('Aktifkan lokasi'), findsOneWidget);
        expect(find.text('Pilih di peta'), findsOneWidget);

        // Mengetuk tombol 'Pilih di peta' untuk fallback navigasi ke peta
        await tester.tap(find.text('Pilih di peta'));
        await tester.pumpAndSettle();

        // Sheet galat telah tertutup dan dialog peta sekarang aktif terbuka
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
        expect(find.byType(AppMapPickerDialog), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      'displays LocationActionableError bottom sheet when permission is denied '
      'with secondary action Pilih di peta',
      (tester) async {
        configureTestView(tester);

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
            locationProvider: () async =>
                const LocationResult.permissionDenied(),
          ),
        );
        await tester.pumpAndSettle();

        final locationPlaceholder = find.text('Belum ada titik lokasi');
        await tester.ensureVisible(locationPlaceholder);
        await tester.tap(locationPlaceholder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lokasi saat ini'));
        await tester.pumpAndSettle();

        expect(find.text('Izin akses lokasi dibutuhkan'), findsOneWidget);
        expect(find.text('Pilih di peta'), findsOneWidget);

        await tester.tap(find.text('Pilih di peta'));
        await tester.pumpAndSettle();

        expect(find.text('Izin akses lokasi dibutuhkan'), findsNothing);
        expect(find.byType(AppMapPickerDialog), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      'displays timeout snackbar with retry action when location times out',
      (tester) async {
        configureTestView(tester);

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        var locationAttempts = 0;
        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
            locationProvider: () async {
              locationAttempts++;
              return const LocationResult.timeout();
            },
          ),
        );
        await tester.pumpAndSettle();

        final locationPlaceholder = find.text('Belum ada titik lokasi');
        await tester.ensureVisible(locationPlaceholder);
        await tester.tap(locationPlaceholder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lokasi saat ini'));
        await tester.pumpAndSettle();

        expect(locationAttempts, equals(1));
        expect(
          find.text(
            'Waktu deteksi lokasi habis. Pastikan berada di area terbuka.',
          ),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(find.text('Waktu deteksi lokasi habis'), findsNothing);
        expect(find.text('Pilih di peta'), findsNothing);

        await tester.tap(find.text('Coba lagi'));
        await tester.pumpAndSettle();

        expect(locationAttempts, equals(2));

        await cubit.close();
      },
    );

    testWidgets(
      'displays LocationActionableError bottom sheet when mock location '
      'detected and dismisses with Kembali without opening map',
      (tester) async {
        configureTestView(tester);

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
            locationProvider: () async =>
                const LocationResult.mockDetected(),
          ),
        );
        await tester.pumpAndSettle();

        final locationPlaceholder = find.text('Belum ada titik lokasi');
        await tester.ensureVisible(locationPlaceholder);
        await tester.tap(locationPlaceholder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lokasi saat ini'));
        await tester.pumpAndSettle();

        expect(find.text('Lokasi tiruan terdeteksi'), findsOneWidget);
        expect(find.text('Kembali'), findsOneWidget);

        await tester.tap(find.text('Kembali'));
        await tester.pumpAndSettle();

        expect(find.text('Lokasi tiruan terdeteksi'), findsNothing);
        expect(find.byType(AppMapPickerDialog), findsNothing);

        await cubit.close();
      },
    );

    testWidgets(
      'forwards injected reverseGeocodeService to '
      'InformationLocationSection and AppStaticMap',
      (tester) async {
        final mockReverseGeocode = MockReverseGeocodeService();
        when(
          () => mockReverseGeocode.reverseGeocode(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const ReverseGeocodeResult.success(
            latitude: -6.2088,
            longitude: 106.8456,
            address: 'Jl. Injeksi DI No. 99',
          ),
        );

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
          initialItem: dummyItem,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            reverseGeocodeService: mockReverseGeocode,
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi AppStaticMap menerima instance service yang diinjeksi
        final staticMapFinder = find.byType(AppStaticMap);
        expect(staticMapFinder, findsOneWidget);
        final staticMap = tester.widget<AppStaticMap>(staticMapFinder);
        expect(staticMap.reverseGeocodeService, equals(mockReverseGeocode));

        verify(
          () => mockReverseGeocode.reverseGeocode(
            latitude: -6.2088,
            longitude: 106.8456,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);

        await cubit.close();
      },
    );

    testWidgets(
      'auto-healing: automatically dismisses error sheet and sets '
      'coordinates on app resume when location becomes available',
      (tester) async {
        configureTestView(tester);

        var isGpsTurnedOnInSettings = false;
        var locationCallCount = 0;

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
            locationProvider: () async {
              locationCallCount++;
              if (isGpsTurnedOnInSettings) {
                return LocationResult.success(dummyPosition());
              }
              return const LocationResult.serviceDisabled();
            },
          ),
        );
        await tester.pumpAndSettle();

        final locationPlaceholder = find.text('Belum ada titik lokasi');
        await tester.ensureVisible(locationPlaceholder);
        await tester.tap(locationPlaceholder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lokasi saat ini'));
        await tester.pumpAndSettle();

        expect(locationCallCount, equals(1));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);
        expect(cubit.state.hasLocation, isFalse);
        expect(cubit.state.latitude, isNull);
        expect(cubit.state.longitude, isNull);

        // Simulasi pengguna menyalakan GPS di OS Settings dan kembali ke app
        isGpsTurnedOnInSettings = true;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // Auto-healing berhasil: error sheet tertutup, koordinat tersimpan
        expect(locationCallCount, equals(2));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
        expect(cubit.state.hasLocation, isTrue);
        expect(cubit.state.latitude, equals(-6.2088));
        expect(cubit.state.longitude, equals(106.8456));
        expect(
          find.text('Titik lokasi GPS berhasil diperoleh.'),
          findsOneWidget,
        );

        await cubit.close();
      },
    );

    testWidgets(
      'auto-healing: leaves error sheet visible on resume if location is '
      'still unavailable',
      (tester) async {
        configureTestView(tester);

        var locationCallCount = 0;

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
            locationProvider: () async {
              locationCallCount++;
              return const LocationResult.serviceDisabled();
            },
          ),
        );
        await tester.pumpAndSettle();

        final locationPlaceholder = find.text('Belum ada titik lokasi');
        await tester.ensureVisible(locationPlaceholder);
        await tester.tap(locationPlaceholder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lokasi saat ini'));
        await tester.pumpAndSettle();

        expect(locationCallCount, equals(1));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // App di-resume tetapi pengguna belum menyalakan GPS
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        expect(locationCallCount, equals(2));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);
        expect(cubit.state.hasLocation, isFalse);
        expect(cubit.state.latitude, isNull);

        await cubit.close();
      },
    );

    testWidgets(
      'auto-healing: does not auto-fetch location on resume after '
      'manual error sheet dismissal',
      (tester) async {
        configureTestView(tester);

        var isGpsTurnedOnInSettings = false;
        var locationCallCount = 0;

        final cubit = InformationFormCubit(
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        await tester.pumpWidget(
          _buildFormTestApp(
            cubit: cubit,
            mediaPickerService: mockMediaPicker,
            locationProvider: () async {
              locationCallCount++;
              if (isGpsTurnedOnInSettings) {
                return LocationResult.success(dummyPosition());
              }
              return const LocationResult.serviceDisabled();
            },
          ),
        );
        await tester.pumpAndSettle();

        final locationPlaceholder = find.text('Belum ada titik lokasi');
        await tester.ensureVisible(locationPlaceholder);
        await tester.tap(locationPlaceholder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lokasi saat ini'));
        await tester.pumpAndSettle();

        expect(locationCallCount, equals(1));
        expect(find.text('Layanan lokasi belum diaktifkan'), findsOneWidget);

        // Pengguna memilih 'Pilih di peta' sehingga error sheet ditutup
        await tester.tap(find.text('Pilih di peta'));
        await tester.pumpAndSettle();

        // Verifikasi dialog peta terbuka dan error sheet tertutup
        expect(find.text('Layanan lokasi belum diaktifkan'), findsNothing);
        expect(find.byType(AppMapPickerDialog), findsOneWidget);

        // Simulasi app resume saat map picker terbuka
        isGpsTurnedOnInSettings = true;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // Form dialog tidak memicu fetch GPS karena error sheet sudah ditutup
        expect(locationCallCount, equals(1));
        expect(find.text('Titik lokasi GPS berhasil diperoleh.'), findsNothing);

        await cubit.close();
      },
    );
  });
}

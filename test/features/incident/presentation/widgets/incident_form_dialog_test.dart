import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_chip.dart';
import 'package:kawalo_mobile/core/widgets/app_confirmation_dialog.dart';
import 'package:kawalo_mobile/core/widgets/app_page_actions.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_category.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_form_dialog.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_photo_action_bottom_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentFormCubit extends Mock implements IncidentFormCubit {}

class MockUserSessionCubit extends Mock implements UserSessionCubit {}

void main() {
  late MockIncidentFormCubit mockFormCubit;
  late MockUserSessionCubit mockSessionCubit;

  setUpAll(() {
    registerFallbackValue(IncidentCategory.general);
  });

  setUp(() {
    mockFormCubit = MockIncidentFormCubit();
    mockSessionCubit = MockUserSessionCubit();
  });

  const tSession = AuthSessionEntity(
    userId: 'usr_1',
    role: 'ADMIN',
    email: 'admin@kawalo.id',
    name: 'Admin Kawalo',
    groupUid: 'grp_1',
    allowAdmin: true,
    allowPatrol: true,
    allowMonPatrol: true,
  );

  Widget createWidgetUnderTest({required IncidentFormState state}) {
    when(() => mockFormCubit.state).thenReturn(state);
    when(() => mockFormCubit.stream).thenAnswer((_) => Stream.value(state));
    when(() => mockFormCubit.updateCategory(any())).thenReturn(null);
    when(() => mockFormCubit.updateTitle(any())).thenReturn(null);
    when(() => mockFormCubit.updateDescription(any())).thenReturn(null);
    when(() => mockFormCubit.removePhoto(any())).thenReturn(null);
    when(() => mockFormCubit.clearPhotos()).thenReturn(null);
    when(() => mockFormCubit.resolveLocation()).thenAnswer((_) async {});
    when(() => mockFormCubit.clearLocation()).thenReturn(null);
    when(() => mockFormCubit.retryPhotoUpload(any())).thenAnswer((_) async {});
    when(() => mockFormCubit.reorderPhotos(any(), any())).thenReturn(null);
    when(
      () => mockFormCubit.submit(session: any(named: 'session')),
    ).thenAnswer((_) async {});
    when(() => mockFormCubit.close()).thenAnswer((_) async {});

    when(() => mockSessionCubit.state).thenReturn(tSession);
    when(
      () => mockSessionCubit.stream,
    ).thenAnswer((_) => Stream.value(tSession));
    when(() => mockSessionCubit.close()).thenAnswer((_) async {});

    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UserSessionCubit>.value(value: mockSessionCubit),
          BlocProvider<IncidentFormCubit>.value(value: mockFormCubit),
        ],
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    IncidentFormDialog.showCreate(
                      context,
                      formCubit: mockFormCubit,
                    );
                  },
                  child: const Text('Buka Dialog'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  group('IncidentFormDialog UI & Interaction Tests', () {
    testWidgets('renders form with non-redundant photo placeholder matching '
        'Information pattern', (tester) async {
      const state = IncidentFormState();

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Title dialog di AppBar
      expect(find.text('Laporkan insiden'), findsOneWidget);

      // Action button "Kirim"
      expect(find.text('Kirim'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppPageActions),
          matching: find.text('Kirim'),
        ),
        findsOneWidget,
      );

      // Section titles & subtitles
      expect(find.text('Kategori insiden'), findsOneWidget);
      expect(find.text('Detail laporan'), findsOneWidget);
      expect(find.text('Dokumentasi foto (0/4)'), findsOneWidget);

      // Category chips (Facility, Security, Hazard, General)
      expect(
        find.byType(AppChip),
        findsNWidgets(IncidentCategory.values.length),
      );
      expect(find.text('Fasilitas'), findsOneWidget);
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Bahaya'), findsOneWidget);
      expect(find.text('Umum'), findsOneWidget);

      // Text fields
      expect(find.byType(AppTextField), findsNWidgets(2));
      expect(find.textContaining('Judul laporan'), findsOneWidget);
      expect(find.text('Deskripsi kejadian'), findsOneWidget);

      // Memastikan tidak ada tombol redundan "Ambil foto" di header section
      expect(find.text('Ambil foto'), findsNothing);

      // Area placeholder foto standar serasi dengan modul Information
      expect(find.text('Belum ada foto terlampir'), findsOneWidget);
      expect(
        find.text('Ketuk untuk memilih foto dari kamera atau galeri'),
        findsOneWidget,
      );
    });

    testWidgets('renders photo thumbnails, Hapus semua button, and outlined '
        'Add Photo button when photos exist', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const state = IncidentFormState(
        photos: [
          IncidentMediaItem(
            id: 'photo_1',
            name: 'foto1.jpg',
            path: 'non_existent_dummy_path.jpg',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Placeholder kosong tidak muncul lagi saat foto ada
      expect(find.text('Belum ada foto terlampir'), findsNothing);

      // Header menampilkan jumlah foto (1/4) dan tombol Hapus semua
      expect(find.text('Dokumentasi foto (1/4)'), findsOneWidget);
      expect(find.text('Hapus semua'), findsOneWidget);

      // Tombol hapus foto dengan semantic label yang jelas
      expect(find.bySemanticsLabel('Hapus foto insiden ke-1'), findsOneWidget);

      // Tombol outlined untuk menambah foto
      expect(find.widgetWithText(AppButton, 'Tambah foto'), findsOneWidget);

      // Ketuk tombol hapus silang memicu removePhoto pada cubit
      await tester.tap(find.bySemanticsLabel('Hapus foto insiden ke-1'));
      await tester.pump();
      verify(() => mockFormCubit.removePhoto('photo_1')).called(1);
    });

    testWidgets(
      'tapping Hapus semua shows confirmation dialog and clears photos',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const state = IncidentFormState(
          photos: [
            IncidentMediaItem(
              id: 'photo_1',
              name: 'foto1.jpg',
              path: 'non_existent_dummy_path.jpg',
            ),
          ],
        );

        await tester.pumpWidget(createWidgetUnderTest(state: state));
        await tester.pump();

        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus semua'));
        await tester.pumpAndSettle();

        expect(find.byType(AppConfirmationDialog), findsOneWidget);
        expect(find.text('Hapus semua foto?'), findsOneWidget);

        final confirmBtn = find.descendant(
          of: find.byType(AppConfirmationDialog),
          matching: find.text('Hapus semua'),
        );
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        verify(() => mockFormCubit.clearPhotos()).called(1);
      },
    );

    testWidgets('tapping more options on photo opens action bottom sheet and '
        'deletes on request', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const state = IncidentFormState(
        photos: [
          IncidentMediaItem(
            id: 'photo_1',
            name: 'foto1.jpg',
            path: 'non_existent_dummy_path.jpg',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Opsi foto insiden ke-1'));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentPhotoActionBottomSheet), findsOneWidget);
      expect(find.text('foto1.jpg'), findsOneWidget);
      expect(find.text('Foto 1 dari 1'), findsOneWidget);
      expect(find.text('Buka foto'), findsOneWidget);
      expect(find.text('Hapus foto ini'), findsOneWidget);

      await tester.tap(find.text('Hapus foto ini'));
      await tester.pumpAndSettle();

      verify(() => mockFormCubit.removePhoto('photo_1')).called(1);
    });

    testWidgets(
      'tapping more options with multiple photos shows reorder options and '
      'calls reorder',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const state = IncidentFormState(
          photos: [
            IncidentMediaItem(id: 'photo_1', name: 'foto1.jpg'),
            IncidentMediaItem(id: 'photo_2', name: 'foto2.jpg'),
          ],
        );

        await tester.pumpWidget(createWidgetUnderTest(state: state));
        await tester.pump();

        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        // Tap more options on photo 2 (index 1)
        await tester.tap(find.bySemanticsLabel('Opsi foto insiden ke-2'));
        await tester.pumpAndSettle();

        expect(find.text('foto2.jpg'), findsOneWidget);
        expect(find.text('Foto 2 dari 2'), findsOneWidget);
        expect(find.text('Jadikan foto utama'), findsOneWidget);
        expect(find.text('Geser ke kiri'), findsOneWidget);

        await tester.tap(find.text('Jadikan foto utama'));
        await tester.pumpAndSettle();

        verify(() => mockFormCubit.reorderPhotos(1, 0)).called(1);
      },
    );

    testWidgets('calls updateCategory when category chip tapped', (
      tester,
    ) async {
      const state = IncidentFormState();

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keamanan'));
      await tester.pump();

      verify(
        () => mockFormCubit.updateCategory(IncidentCategory.security),
      ).called(1);
    });

    testWidgets('enables Kirim button and invokes submit when valid', (
      tester,
    ) async {
      const state = IncidentFormState(
        category: IncidentCategory.security,
        title: 'Gerbang utama rusak',
        description: 'Pintu gerbang macet tidak bisa ditutup',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(AppButton, 'Kirim');
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pump();

      verify(
        () => mockFormCubit.submit(session: any(named: 'session')),
      ).called(1);
    });

    testWidgets(
      'shows confirmation dialog when trying to discard non-empty form',
      (tester) async {
        const state = IncidentFormState(title: 'Ada genangan air');

        await tester.pumpWidget(createWidgetUnderTest(state: state));
        await tester.pump();

        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        // Tap close button di AppBar fullscreen dialog
        final closeButton = find.bySemanticsLabel('Tutup');
        expect(closeButton, findsOneWidget);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Konfirmasi dialog muncul
        expect(find.byType(AppConfirmationDialog), findsOneWidget);
        expect(find.text('Buang laporan?'), findsOneWidget);
        expect(find.text('Buang'), findsOneWidget);
        expect(find.text('Lanjut mengisi'), findsOneWidget);
      },
    );

    testWidgets(
      'displays title errorText when validationAttempt > 0 and error exists',
      (tester) async {
        const state = IncidentFormState(
          titleError: 'Judul laporan wajib diisi',
          validationAttempt: 1,
        );

        await tester.pumpWidget(createWidgetUnderTest(state: state));
        await tester.pump();

        await tester.tap(find.text('Buka Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Judul laporan wajib diisi'), findsOneWidget);
      },
    );

    testWidgets('displays AppSnackbar when failure status has error message', (
      tester,
    ) async {
      const state = IncidentFormState(
        status: IncidentFormStatus.failure,
        errorMessage: 'Tidak ada koneksi internet. Periksa koneksi Anda.',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak ada koneksi internet. Periksa koneksi Anda.'),
        findsOneWidget,
      );
    });

    testWidgets('renders without overflow under 200% dynamic text scaling', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () => tester.platformDispatcher.clearTextScaleFactorTestValue(),
      );

      const state = IncidentFormState(
        category: IncidentCategory.facility,
        title: 'Pipa air bocor di lantai dua',
        description: 'Air menggenang dan merembes ke lantai dasar.',
      );

      await tester.pumpWidget(createWidgetUnderTest(state: state));
      await tester.pump();

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('requests the GPS location when the form opens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidgetUnderTest(state: const IncidentFormState()),
      );
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      verify(() => mockFormCubit.resolveLocation()).called(1);
      expect(find.text('Lokasi kejadian'), findsOneWidget);
      expect(find.text('Tanpa lokasi'), findsOneWidget);
    });

    testWidgets('shows the Indonesian reason when location is unavailable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidgetUnderTest(
          state: const IncidentFormState(
            locationError: 'Izin akses lokasi belum diberikan.',
          ),
        ),
      );
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Lokasi tidak tersedia'), findsOneWidget);
      expect(
        find.textContaining('Izin akses lokasi belum diberikan.'),
        findsOneWidget,
      );
      expect(find.textContaining('Ketuk untuk mencoba lagi.'), findsOneWidget);
    });

    testWidgets('shows searching indicator while resolving location', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidgetUnderTest(
          state: const IncidentFormState(isResolvingLocation: true),
        ),
      );
      await tester.tap(find.text('Buka Dialog'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Mencari lokasi...'), findsOneWidget);
    });

    testWidgets('shows per-photo upload status and disables Kirim while '
        'uploading', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidgetUnderTest(
          state: const IncidentFormState(
            status: IncidentFormStatus.uploading,
            title: 'Pagar rusak',
            photos: [
              IncidentMediaItem(
                id: 'a',
                name: 'a.jpg',
                path: 'missing_a.jpg',
                uploadStatus: IncidentUploadStatus.uploading,
                uploadProgress: 0.4,
              ),
              IncidentMediaItem(id: 'b', name: 'b.jpg', path: 'missing_b.jpg'),
              IncidentMediaItem(
                id: 'c',
                name: 'c.jpg',
                path: 'missing_c.jpg',
                uploadStatus: IncidentUploadStatus.done,
                remoteUrl: 'https://cdn.kawalo.id/c.webp',
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Buka Dialog'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('40%'), findsOneWidget);
      expect(find.text('Menunggu...'), findsOneWidget);
      final kirim = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Kirim'),
      );
      expect(kirim.enabled, isFalse);
    });

    testWidgets('failed photo shows the error and retries on Coba lagi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidgetUnderTest(
          state: const IncidentFormState(
            title: 'Pagar rusak',
            photos: [
              IncidentMediaItem(
                id: 'a',
                name: 'a.jpg',
                path: 'missing_a.jpg',
                uploadStatus: IncidentUploadStatus.failed,
                uploadError: 'Koneksi terputus.',
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Koneksi terputus.'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Coba lagi'));
      await tester.pump();
      verify(() => mockFormCubit.retryPhotoUpload('a')).called(1);
    });
  });
}

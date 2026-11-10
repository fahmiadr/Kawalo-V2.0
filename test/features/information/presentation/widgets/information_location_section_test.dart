import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/services/reverse_geocode_service.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_static_map.dart';
import 'package:kawalo_mobile/core/widgets/app_text_field.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/create_information/create_information_usecase.dart';
import 'package:kawalo_mobile/features/information/domain/usecases/update_information/update_information_usecase.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_cubit.dart';
import 'package:kawalo_mobile/features/information/presentation/widgets/information_location_section.dart';
import 'package:mocktail/mocktail.dart';
import '../../upload_test_helpers.dart';

class MockCreateInformationUseCase extends Mock
    implements CreateInformationUseCase {}

class MockUpdateInformationUseCase extends Mock
    implements UpdateInformationUseCase {}

class MockReverseGeocodeService extends Mock implements ReverseGeocodeService {}

Widget _buildLocationSectionTestApp({
  required InformationFormCubit cubit,
  required TextEditingController controller,
  required FocusNode focusNode,
  required ValueChanged<String> onLocationNameChanged,
  required VoidCallback onPickLocation,
  required VoidCallback onClearLocation,
  bool isSubmitting = false,
  bool isResolvingLocation = false,
  ReverseGeocodeService? reverseGeocodeService,
}) {
  return MaterialApp(
    builder: (context, child) =>
        M3ETheme(data: AppTheme.m3eLight(), child: child!),
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider.value(
          value: cubit,
          child: InformationLocationSection(
            eventLocationController: controller,
            eventLocationFocusNode: focusNode,
            isSubmitting: isSubmitting,
            isResolvingLocation: isResolvingLocation,
            onLocationNameChanged: onLocationNameChanged,
            onPickLocation: onPickLocation,
            onClearLocation: onClearLocation,
            reverseGeocodeService: reverseGeocodeService,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockCreateInformationUseCase mockCreateUseCase;
  late MockUpdateInformationUseCase mockUpdateUseCase;
  late MockReverseGeocodeService mockReverseGeocodeService;
  late TextEditingController locationController;
  late FocusNode locationFocusNode;

  setUp(() {
    mockCreateUseCase = MockCreateInformationUseCase();
    mockUpdateUseCase = MockUpdateInformationUseCase();
    mockReverseGeocodeService = MockReverseGeocodeService();
    locationController = TextEditingController();
    locationFocusNode = FocusNode();

    when(
      () => mockReverseGeocodeService.reverseGeocode(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => const ReverseGeocodeResult.success(
        latitude: -6.2088,
        longitude: 106.8456,
        address: 'Jl. Kebon Jeruk No. 12, Jakarta',
      ),
    );
  });

  tearDown(() {
    locationController.dispose();
    locationFocusNode.dispose();
  });

  void configureTestView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('InformationLocationSection Decoupled Mutation Tests', () {
    testWidgets(
      'renders empty placeholder when hasLocation is false, triggers pick',
      (tester) async {
        configureTestView(tester);

        final cubit = InformationFormCubit(
          uploadRepository: FakeUploadRepository(),
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        );

        var pickCalled = false;

        await tester.pumpWidget(
          _buildLocationSectionTestApp(
            cubit: cubit,
            controller: locationController,
            focusNode: locationFocusNode,
            onLocationNameChanged: cubit.onEventLocationChanged,
            onPickLocation: () => pickCalled = true,
            onClearLocation: cubit.onClearLocationCoordinates,
            reverseGeocodeService: mockReverseGeocodeService,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppFormEmptyPlaceholder), findsOneWidget);
        expect(find.text('Belum ada titik lokasi'), findsOneWidget);
        expect(find.byType(AppStaticMap), findsNothing);

        await tester.tap(find.byType(AppFormEmptyPlaceholder));
        await tester.pumpAndSettle();

        expect(pickCalled, isTrue);

        await cubit.close();
      },
    );

    testWidgets('typing into AppTextField updates cubit and DOES NOT mutate '
        'AppStaticMap address', (tester) async {
      configureTestView(tester);

      final cubit = InformationFormCubit(
        uploadRepository: FakeUploadRepository(),
        createInformationUseCase: mockCreateUseCase,
        updateInformationUseCase: mockUpdateUseCase,
      )..onSetLocationCoordinates(lat: -6.2088, lng: 106.8456);

      await tester.pumpWidget(
        _buildLocationSectionTestApp(
          cubit: cubit,
          controller: locationController,
          focusNode: locationFocusNode,
          onLocationNameChanged: cubit.onEventLocationChanged,
          onPickLocation: () {},
          onClearLocation: cubit.onClearLocationCoordinates,
          reverseGeocodeService: mockReverseGeocodeService,
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi AppStaticMap ada dengan address == null (bukan dari input)
      final staticMapFinder = find.byType(AppStaticMap);
      expect(staticMapFinder, findsOneWidget);
      final staticMapWidgetBefore = tester.widget<AppStaticMap>(
        staticMapFinder,
      );
      expect(staticMapWidgetBefore.address, isNull);
      expect(staticMapWidgetBefore.latitude, -6.2088);
      expect(staticMapWidgetBefore.longitude, 106.8456);

      // Ketik nama lokasi di textfield
      await tester.enterText(find.byType(AppTextField), 'Aula Lantai 2');
      await tester.pumpAndSettle();

      expect(cubit.state.eventLocation, 'Aula Lantai 2');

      // Verifikasi AppStaticMap address TETAP null (tidak termutasi input teks)
      final staticMapWidgetAfter = tester.widget<AppStaticMap>(staticMapFinder);
      expect(staticMapWidgetAfter.address, isNull);

      await cubit.close();
    });

    testWidgets(
      'setting coordinates does NOT mutate eventLocation or controller',
      (tester) async {
        configureTestView(tester);

        locationController.text = 'Ruang Rapat Utama';

        final cubit = InformationFormCubit(
          uploadRepository: FakeUploadRepository(),
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        )..onEventLocationChanged('Ruang Rapat Utama');

        var clearCalled = false;

        await tester.pumpWidget(
          _buildLocationSectionTestApp(
            cubit: cubit,
            controller: locationController,
            focusNode: locationFocusNode,
            onLocationNameChanged: cubit.onEventLocationChanged,
            onPickLocation: () {},
            onClearLocation: () {
              clearCalled = true;
              cubit.onClearLocationCoordinates();
            },
            reverseGeocodeService: mockReverseGeocodeService,
          ),
        );
        await tester.pumpAndSettle();

        // Awalnya belum ada koordinat
        expect(find.byType(AppStaticMap), findsNothing);

        // Set koordinat
        cubit.onSetLocationCoordinates(lat: -6.9175, lng: 107.6191);
        await tester.pumpAndSettle();

        // AppStaticMap muncul, teks controller tetap 'Ruang Rapat Utama'
        expect(find.byType(AppStaticMap), findsOneWidget);
        expect(locationController.text, 'Ruang Rapat Utama');
        expect(cubit.state.eventLocation, 'Ruang Rapat Utama');

        // Tekan tombol Hapus titik
        final deleteBtn = find.widgetWithText(AppButton, 'Hapus titik');
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        expect(clearCalled, isTrue);
        expect(find.byType(AppStaticMap), findsNothing);
        expect(find.byType(AppFormEmptyPlaceholder), findsOneWidget);

        // Nama lokasi di controller dan cubit tetap utuh
        expect(locationController.text, 'Ruang Rapat Utama');
        expect(cubit.state.eventLocation, 'Ruang Rapat Utama');

        await cubit.close();
      },
    );

    testWidgets(
      'disables textfield and action buttons when isSubmitting is true',
      (tester) async {
        configureTestView(tester);

        final cubit = InformationFormCubit(
          uploadRepository: FakeUploadRepository(),
          createInformationUseCase: mockCreateUseCase,
          updateInformationUseCase: mockUpdateUseCase,
        )..onSetLocationCoordinates(lat: -6.2088, lng: 106.8456);

        await tester.pumpWidget(
          _buildLocationSectionTestApp(
            cubit: cubit,
            controller: locationController,
            focusNode: locationFocusNode,
            onLocationNameChanged: cubit.onEventLocationChanged,
            onPickLocation: () {},
            onClearLocation: cubit.onClearLocationCoordinates,
            isSubmitting: true,
            reverseGeocodeService: mockReverseGeocodeService,
          ),
        );
        await tester.pumpAndSettle();

        final textField = tester.widget<AppTextField>(
          find.byType(AppTextField),
        );
        expect(textField.enabled, isFalse);

        final editBtn = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Ubah lokasi'),
        );
        expect(editBtn.onPressed, isNull);

        final deleteBtn = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Hapus titik'),
        );
        expect(deleteBtn.onPressed, isNull);

        await cubit.close();
      },
    );
  });
}

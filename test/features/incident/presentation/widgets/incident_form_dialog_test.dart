import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/network/connectivity_cubit.dart';
import 'package:kawalo_mobile/core/services/media_picker_service.dart';
import 'package:kawalo_mobile/core/session/auth_session_entity.dart';
import 'package:kawalo_mobile/core/session/user_session_cubit.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/incident/domain/entities/incident_entity.dart';
import 'package:kawalo_mobile/features/incident/domain/value_objects/incident_status.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_form_state.dart';
import 'package:kawalo_mobile/features/incident/presentation/cubit/incident_list_cubit.dart';
import 'package:kawalo_mobile/features/incident/presentation/models/incident_media_item.dart';
import 'package:kawalo_mobile/features/incident/presentation/widgets/incident_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentFormCubit extends Mock implements IncidentFormCubit {}

class MockUserSessionCubit extends Mock implements UserSessionCubit {}

class MockConnectivityCubit extends Mock implements ConnectivityCubit {}

class MockIncidentListCubit extends Mock implements IncidentListCubit {}

class MockMediaPickerService extends Mock implements MediaPickerService {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  late MockIncidentFormCubit formCubit;
  late MockUserSessionCubit sessionCubit;
  late MockMediaPickerService picker;
  late StreamController<IncidentFormState> states;

  const tSession = AuthSessionEntity(
    userId: 'usr_1',
    role: 'GUARD',
    email: 'guard@kawalo.id',
    name: 'Budi',
    groupUid: 'grp_1',
    allowAdmin: false,
    allowPatrol: true,
    allowMonPatrol: false,
  );

  const photoFile = AppMediaFile(name: 'a.jpg', path: 'missing_a.jpg');

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(<IncidentMediaItem>[]);
  });

  setUp(() {
    formCubit = MockIncidentFormCubit();
    sessionCubit = MockUserSessionCubit();
    picker = MockMediaPickerService();
    states = StreamController<IncidentFormState>.broadcast();
    addTearDown(states.close);

    when(() => formCubit.stream).thenAnswer((_) => states.stream);
    when(() => formCubit.updateText(any())).thenReturn(null);
    when(() => formCubit.addPhotos(any())).thenReturn(null);
    when(() => formCubit.removePhoto(any())).thenReturn(null);
    when(() => formCubit.resolveLocation()).thenAnswer((_) async {});
    when(() => formCubit.clearLocation()).thenReturn(null);
    when(() => formCubit.retryPhotoUpload(any())).thenAnswer((_) async {});
    when(
      () => formCubit.submit(session: any(named: 'session')),
    ).thenAnswer((_) async {});

    when(() => sessionCubit.state).thenReturn(tSession);
    when(
      () => sessionCubit.stream,
    ).thenAnswer((_) => const Stream<AuthSessionEntity?>.empty());
    when(() => sessionCubit.close()).thenAnswer((_) async {});

    when(
      () => picker.captureMultiImagesFromCamera(
        any(),
        alreadyAttachedCount: any(named: 'alreadyAttachedCount'),
        allowSkip: true,
      ),
    ).thenAnswer((_) async => const []);
  });

  void setState(IncidentFormState state) =>
      when(() => formCubit.state).thenReturn(state);

  Future<void> open(
    WidgetTester tester, {
    IncidentFormState state = const IncidentFormState(),
    ConnectivityCubit? connectivity,
    IncidentListCubit? listCubit,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    setState(state);

    // Above MaterialApp like in the app: the form is a pushed route.
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<UserSessionCubit>.value(value: sessionCubit),
          if (connectivity != null)
            BlocProvider<ConnectivityCubit>.value(value: connectivity),
        ],
        child: MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => IncidentFormDialog.showCreate(
                    context,
                    formCubit: formCubit,
                    incidentListCubit: listCubit,
                    mediaPickerService: picker,
                  ),
                  child: const Text('Laporkan'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Laporkan'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  }

  AppTaskButton taskButton(WidgetTester tester, String label) =>
      tester.widget<AppTaskButton>(find.widgetWithText(AppTaskButton, label));

  testWidgets('opens the camera first, then the one-field form', (
    tester,
  ) async {
    when(
      () => picker.captureMultiImagesFromCamera(
        any(),
        alreadyAttachedCount: any(named: 'alreadyAttachedCount'),
        allowSkip: true,
      ),
    ).thenAnswer((_) async => const [photoFile]);

    await open(tester);

    final added =
        verify(() => formCubit.addPhotos(captureAny())).captured.single
            as List<IncidentMediaItem>;
    expect(added.single.path, 'missing_a.jpg');
    verify(() => formCubit.resolveLocation()).called(greaterThan(0));
    expect(find.text('Laporan Kejadian'), findsOneWidget);
    expect(find.text('Apa yang terjadi?*'), findsOneWidget);
    expect(find.text('Kalimat pertama menjadi judul laporan.'), findsOneWidget);
    expect(find.text('Kirim Laporan'), findsOneWidget);
  });

  testWidgets('closing the camera still opens the form without photos', (
    tester,
  ) async {
    await open(tester);

    final added =
        verify(() => formCubit.addPhotos(captureAny())).captured.single
            as List<IncidentMediaItem>;
    expect(added, isEmpty);
    expect(find.text('Laporan Kejadian'), findsOneWidget);
  });

  testWidgets('typing updates the text and Kirim Laporan submits', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(
      find.byType(EditableText),
      'Pagar rusak. Gembok hilang',
    );
    verify(() => formCubit.updateText('Pagar rusak. Gembok hilang')).called(1);

    await tester.tap(find.text('Kirim Laporan'));
    verify(() => formCubit.submit(session: tSession)).called(1);
  });

  testWidgets('shows the validation error', (tester) async {
    await open(
      tester,
      state: const IncidentFormState(
        textError: 'Tulis apa yang terjadi, minimal 5 karakter.',
        validationAttempt: 1,
      ),
    );

    expect(
      find.text('Tulis apa yang terjadi, minimal 5 karakter.'),
      findsOneWidget,
    );
  });

  testWidgets('uploading shows progress and locks the button', (tester) async {
    await open(
      tester,
      settle: false,
      state: const IncidentFormState(
        status: IncidentFormStatus.uploading,
        text: 'Pagar rusak',
        photos: [
          IncidentMediaItem(
            id: 'a',
            name: 'a.jpg',
            path: 'missing_a.jpg',
            uploadStatus: IncidentUploadStatus.done,
            remoteUrl: 'https://cdn.kawalo.id/a.webp',
          ),
          IncidentMediaItem(
            id: 'b',
            name: 'b.jpg',
            path: 'missing_b.jpg',
            uploadStatus: IncidentUploadStatus.uploading,
            uploadProgress: 0.4,
          ),
        ],
      ),
    );

    expect(find.text('Mengunggah foto 2 dari 2…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(taskButton(tester, 'Mengunggah foto 2 dari 2…').isLoading, isTrue);
  });

  testWidgets('failure shows the reason and Coba Kirim Lagi', (tester) async {
    await open(
      tester,
      state: const IncidentFormState(
        status: IncidentFormStatus.failure,
        text: 'Pagar rusak',
        errorMessage: 'Foto ke-1 gagal diunggah. Laporan belum terkirim.',
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
    );

    expect(
      find.text('Foto ke-1 gagal diunggah. Laporan belum terkirim.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Coba Kirim Lagi'));
    verify(() => formCubit.submit(session: tSession)).called(1);

    await tester.tap(find.widgetWithText(AppButton, 'Coba lagi'));
    verify(() => formCubit.retryPhotoUpload('a')).called(1);
  });

  testWidgets('offline disables sending and says why', (tester) async {
    final connectivity = MockConnectivityCubit();
    when(() => connectivity.state).thenReturn(ConnectivityStatus.offline);
    when(
      () => connectivity.stream,
    ).thenAnswer((_) => const Stream<ConnectivityStatus>.empty());
    when(connectivity.close).thenAnswer((_) async {});

    await open(
      tester,
      connectivity: connectivity,
      state: const IncidentFormState(text: 'Pagar rusak'),
    );

    expect(
      find.text('Anda offline. Laporan bisa dikirim saat tersambung.'),
      findsOneWidget,
    );
    expect(taskButton(tester, 'Kirim Laporan').onPressed, isNull);
  });

  testWidgets('location chip: coordinates, and retry when unavailable', (
    tester,
  ) async {
    await open(
      tester,
      state: const IncidentFormState(glat: -6.2088, glong: 106.8456),
    );
    expect(find.text('-6.20880, 106.84560'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus lokasi'));
    verify(() => formCubit.clearLocation()).called(1);
  });

  testWidgets('unavailable location can be retried', (tester) async {
    await open(
      tester,
      state: const IncidentFormState(
        locationError: 'Izin akses lokasi belum diberikan.',
      ),
    );
    clearInteractions(formCubit);

    await tester.tap(find.text('Lokasi tidak tersedia · Coba lagi'));
    verify(() => formCubit.resolveLocation()).called(1);
  });

  testWidgets('success pops, adds to the list and confirms', (tester) async {
    final listCubit = MockIncidentListCubit();
    final created = IncidentEntity(
      id: 'inc_1',
      groupId: 'grp_1',
      title: 'Pagar rusak',
      status: IncidentStatus.open,
      createdBy: 'guard@kawalo.id',
      createdAt: DateTime(2026, 11, 13, 9, 41),
    );
    when(() => listCubit.onIncidentCreated(created)).thenReturn(null);

    await open(tester, listCubit: listCubit);

    final success = IncidentFormState(
      status: IncidentFormStatus.success,
      createdIncident: created,
    );
    setState(success);
    states.add(success);
    await tester.pumpAndSettle();

    expect(find.text('Laporan Kejadian'), findsNothing);
    expect(find.text('Laporan terkirim ke grup.'), findsOneWidget);
    verify(() => listCubit.onIncidentCreated(created)).called(1);
  });
}

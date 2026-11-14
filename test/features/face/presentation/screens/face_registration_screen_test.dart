import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/face/domain/repositories/face_repository.dart';
import 'package:kawalo_mobile/features/face/presentation/camera/face_camera.dart';
import 'package:kawalo_mobile/features/face/presentation/screens/face_registration_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements FaceRepository {}

class _MockCamera extends Mock implements FaceCamera {}

class _FakeContext extends Fake implements BuildContext {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeContext()));

  testWidgets('consent must be ticked before continuing to the camera', (
    tester,
  ) async {
    final camera = _MockCamera();
    when(camera.start).thenAnswer((_) async {});
    when(() => camera.frames).thenAnswer((_) => const Stream.empty());
    when(camera.dispose).thenAnswer((_) async {});
    when(() => camera.buildPreview(any())).thenReturn(const SizedBox());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: FaceRegistrationScreen(
          repository: _MockRepository(),
          cameraFactory: () => camera,
        ),
      ),
    );

    expect(find.text('Izinkan Kawalo memakai wajah Anda?'), findsOneWidget);
    await tester.tap(find.text('Setuju dan Daftarkan'));
    await tester.pump();
    expect(find.text('Siapkan diri Anda'), findsNothing);

    await tester.scrollUntilVisible(find.byType(Checkbox), 200);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Setuju dan Daftarkan'));
    await tester.pumpAndSettle();
    expect(find.text('Siapkan diri Anda'), findsOneWidget);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Foto 1 dari 5'), findsOneWidget);
    expect(find.text('Lihat lurus ke kamera'), findsOneWidget);
    verify(camera.start).called(1);
  });
}

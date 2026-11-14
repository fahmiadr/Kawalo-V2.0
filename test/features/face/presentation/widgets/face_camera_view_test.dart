import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/face/presentation/widgets/face_camera_view.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? extraLabel,
    VoidCallback? onExtra,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: FaceCameraView(
        title: 'Verifikasi Wajah',
        hint: 'Wajah terdeteksi',
        hintOk: true,
        pill: 'Shift Pagi',
        caption: 'Foto tidak disimpan bila gagal',
        cancelLabel: 'Batal',
        onCancel: () {},
        extraActionLabel: extraLabel,
        onExtraAction: onExtra,
      ),
    ),
  );

  testWidgets('shows the extra action next to the close button and taps it', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, extraLabel: 'Lapor ke Admin', onExtra: () => taps++);
    expect(find.byTooltip('Batal'), findsOneWidget);
    await tester.tap(find.text('Lapor ke Admin'));
    expect(taps, 1);
  });

  testWidgets('hides the extra action by default', (tester) async {
    await pump(tester);
    expect(find.text('Lapor ke Admin'), findsNothing);
    expect(find.byTooltip('Batal'), findsOneWidget);
    expect(find.text('Shift Pagi'), findsOneWidget);
    expect(find.text('Foto tidak disimpan bila gagal'), findsOneWidget);
  });
}

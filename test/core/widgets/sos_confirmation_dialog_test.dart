import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';
import 'package:kawalo_mobile/core/widgets/sos_confirmation_dialog.dart';

void main() {
  Widget buildTestDialog({
    Duration holdDuration = const Duration(seconds: 3),
    int autoCancelTimeout = 20,
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: SosConfirmationDialog(
          holdDuration: holdDuration,
          autoCancelTimeout: autoCancelTimeout,
        ),
      ),
    );
  }

  Widget buildDialogLauncher({
    required ValueChanged<bool?> onResult,
    Duration holdDuration = const Duration(seconds: 3),
    int autoCancelTimeout = 20,
  }) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showGeneralDialog<bool>(
                context: context,
                pageBuilder: (ctx, anim1, anim2) => SosConfirmationDialog(
                  holdDuration: holdDuration,
                  autoCancelTimeout: autoCancelTimeout,
                ),
              );
              onResult(result);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('SosConfirmationDialog Fullscreen Tests', () {
    testWidgets(
      'renders header title, action list, hold button, and cancel slider',
      (tester) async {
        await tester.pumpWidget(buildTestDialog());
        await tester.pump();

        // 1. Memastikan judul di header
        expect(find.text('Darurat SOS'), findsOneWidget);

        // 2. Memastikan daftar aksi "Anda akan:"
        expect(find.text('Anda akan:'), findsOneWidget);
        expect(
          find.text('Menyiarkan sinyal bahaya ke seluruh tim'),
          findsOneWidget,
        );
        expect(
          find.text('Membagikan lokasi terkini Anda'),
          findsOneWidget,
        );

        // 2. Memastikan tombol dengan teks panduan di dalam
        expect(
          find.text('Sentuh lama 3 detik untuk memulai'),
          findsOneWidget,
        );

        // 3. Memastikan slider pembatalan dengan teks 'Batal' dan ikon cancel
        expect(find.text('Batal'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AppSvgIcon &&
                widget.assetPath == KawaloVectors.cancel01,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'holding button shows numeric countdown and triggers SOS after 3s',
      (tester) async {
        bool? dialogResult;

        await tester.pumpWidget(
          buildDialogLauncher(
            onResult: (result) => dialogResult = result,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Sentuh dan tahan tombol utama
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Sentuh lama 3 detik untuk memulai')),
        );
        await tester.pump();

        // Cek teks di dalam tombol berubah menjadi angka hitung mundur saja
        expect(find.text('3'), findsOneWidget);
        expect(find.text('Sentuh lama 3 detik untuk memulai'), findsNothing);

        // Maju 1.5 detik (setengah jalan)
        await tester.pump(const Duration(milliseconds: 1500));
        expect(dialogResult, isNull);

        // Maju sisa 1.6 detik hingga selesai penuh
        await tester.pump(const Duration(milliseconds: 1600));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(SosConfirmationDialog), findsNothing);
        expect(dialogResult, isTrue);
      },
    );

    testWidgets(
      'releasing hold button before 3 seconds restores label without trigger',
      (tester) async {
        bool? dialogResult;

        await tester.pumpWidget(
          buildDialogLauncher(
            onResult: (result) => dialogResult = result,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Sentuh tombol
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Sentuh lama 3 detik untuk memulai')),
        );
        await tester.pump(const Duration(milliseconds: 1000));

        // Lepas tombol sebelum 3 detik
        await gesture.up();
        await tester.pumpAndSettle();

        // Label dipulihkan kembali dan dialog tidak tertutup
        expect(
          find.text('Sentuh lama 3 detik untuk memulai'),
          findsOneWidget,
        );
        expect(find.byType(SosConfirmationDialog), findsOneWidget);
        expect(dialogResult, isNull);
      },
    );

    testWidgets(
      'dragging slider past 80% cancels SOS and closes dialog',
      (tester) async {
        bool? dialogResult;

        await tester.pumpWidget(
          buildDialogLauncher(
            onResult: (result) => dialogResult = result,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final cancelKnobFinder = find.byWidgetPredicate(
          (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.cancel01,
        );
        expect(cancelKnobFinder, findsOneWidget);

        // Geser knob melewati 80% dan lepas di ujung
        await tester.drag(cancelKnobFinder, const Offset(600, 0));
        await tester.pumpAndSettle();

        expect(find.byType(SosConfirmationDialog), findsNothing);
        expect(dialogResult, isFalse);
      },
    );

    testWidgets(
      'dragging slider less than 80% snaps back without cancelling',
      (tester) async {
        bool? dialogResult;

        await tester.pumpWidget(
          buildDialogLauncher(
            onResult: (result) => dialogResult = result,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final cancelKnobFinder = find.byWidgetPredicate(
          (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.cancel01,
        );

        // Geser sedikit saja (hanya 50px)
        await tester.drag(cancelKnobFinder, const Offset(50, 0));
        await tester.pumpAndSettle();

        // Dialog tetap terbuka dan aksi batal tidak terpanggil
        expect(find.byType(SosConfirmationDialog), findsOneWidget);
        expect(dialogResult, isNull);
      },
    );

    testWidgets(
      'dragging slider past 80% then moving back left before releasing does '
      'not cancel SOS',
      (tester) async {
        bool? dialogResult;

        await tester.pumpWidget(
          buildDialogLauncher(
            onResult: (result) => dialogResult = result,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        final cancelKnobFinder = find.byWidgetPredicate(
          (w) => w is AppSvgIcon && w.assetPath == KawaloVectors.cancel01,
        );

        // Geser ke kanan melewati 80% lalu tarik kembali ke kiri sebelum lepas
        final gesture = await tester.startGesture(
          tester.getCenter(cancelKnobFinder),
        );
        await gesture.moveBy(const Offset(300, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-260, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        // Dialog tetap terbuka dan aksi batal tidak terpanggil karena dilepas
        // saat < 80%
        expect(find.byType(SosConfirmationDialog), findsOneWidget);
        expect(dialogResult, isNull);
      },
    );

    testWidgets(
      '20s inactivity timer automatically cancels SOS dialog',
      (tester) async {
        bool? dialogResult;

        await tester.pumpWidget(
          buildDialogLauncher(
            onResult: (result) => dialogResult = result,
            autoCancelTimeout: 3,
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Tunggu 3 detik auto-cancel
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.byType(SosConfirmationDialog), findsNothing);
        expect(dialogResult, isFalse);
      },
    );
  });
}

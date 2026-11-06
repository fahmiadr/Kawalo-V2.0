import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_actionable_error.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_tappable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightThemeData(),
      home: Scaffold(body: child),
    );
  }

  group('AppActionableError Framework Tests', () {
    testWidgets('renders In-Place view with all 6 slots properly',
        (tester) async {
      var primaryPressed = false;
      var secondaryPressed = false;

      final data = AppActionableErrorData(
        icon: KawaloVectors.camera01,
        title: 'Izin kamera diperlukan',
        message: 'Aplikasi membutuhkan akses kamera untuk dokumentasi.',
        troubleshootingTips: const [
          'Buka pengaturan sistem.',
          'Pilih menu Izin aplikasi.',
          'Aktifkan perizinan kamera.',
        ],
        technicalDetails: 'CameraException(CameraAccessDenied, User denied)',
        isUnexpected: true,
        primaryActionLabel: 'Buka pengaturan',
        onPrimaryAction: () => primaryPressed = true,
        secondaryActionLabel: 'Kembali',
        onSecondaryAction: () => secondaryPressed = true,
      );

      await tester.pumpWidget(
        wrapWithTheme(
          AppActionableErrorView(data: data),
        ),
      );

      // Slot 2: Title with Semantics header
      expect(find.text('Izin kamera diperlukan'), findsOneWidget);

      // Slot 3: Message
      expect(
        find.text('Aplikasi membutuhkan akses kamera untuk dokumentasi.'),
        findsOneWidget,
      );

      // Slot 4: Troubleshooting box with plain language header
      expect(find.text('Cara mengatasi:'), findsOneWidget);
      expect(find.text('Buka pengaturan sistem.'), findsOneWidget);
      expect(find.text('Pilih menu Izin aplikasi.'), findsOneWidget);
      expect(find.text('Aktifkan perizinan kamera.'), findsOneWidget);

      // Slot 5: Technical detail expandable via AppTappable
      expect(find.byType(AppTappable), findsOneWidget);
      expect(find.text('Lihat detail teknis'), findsOneWidget);
      expect(
        find.text('CameraException(CameraAccessDenied, User denied)'),
        findsNothing,
      );

      // Tap to expand technical details
      await tester.tap(find.text('Lihat detail teknis'));
      await tester.pumpAndSettle();

      expect(find.text('Sembunyikan detail teknis'), findsOneWidget);
      expect(
        find.text('CameraException(CameraAccessDenied, User denied)'),
        findsOneWidget,
      );

      // Slot 6: Action buttons
      final primaryButton =
          find.widgetWithText(AppButton, 'Buka pengaturan');
      expect(primaryButton, findsOneWidget);
      await tester.tap(primaryButton);
      expect(primaryPressed, isTrue);

      final secondaryButton = find.widgetWithText(AppButton, 'Kembali');
      expect(secondaryButton, findsOneWidget);
      await tester.tap(secondaryButton);
      expect(secondaryPressed, isTrue);
    });

    testWidgets('presents and dismisses Bottom Sheet modality',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    AppActionableErrorBottomSheet.show<void>(
                      context,
                      data: const AppActionableErrorData(
                        title: 'Gagal Menyimpan Foto',
                        message: 'Ruang penyimpanan perangkat hampir penuh.',
                        primaryActionLabel: 'Mengerti',
                      ),
                    );
                  },
                  child: const Text('Buka Sheet'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal Menyimpan Foto'), findsOneWidget);
      expect(
        find.text('Ruang penyimpanan perangkat hampir penuh.'),
        findsOneWidget,
      );
      expect(find.byType(AppActionableErrorBottomSheet), findsOneWidget);
    });

    testWidgets('presents and interacts with Dialog modality',
        (tester) async {
      var retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    AppActionableErrorDialog.show<void>(
                      context,
                      data: AppActionableErrorData(
                        title: 'Koneksi Terputus',
                        message: 'Tidak dapat mengunggah foto saat ini.',
                        primaryActionLabel: 'Coba Lagi',
                        onPrimaryAction: () {
                          retryClicked = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Buka Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Koneksi Terputus'), findsOneWidget);
      expect(find.byType(AppActionableErrorDialog), findsOneWidget);

      final retryBtn = find.widgetWithText(AppButton, 'Coba Lagi');
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(retryClicked, isTrue);
      expect(find.byType(AppActionableErrorDialog), findsNothing);
    });

    testWidgets('honors isBlocking flag in FullScreen modality',
        (tester) async {
      const blockingData = AppActionableErrorData(
        title: 'Perangkat Diblokir',
        message: 'Akses dinonaktifkan demi keamanan.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const AppActionableErrorFullScreen(
            data: blockingData,
            isBlocking: true,
          ),
        ),
      );

      final popScopeFinder = find.byType(PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isFalse);
    });

    test('themeMode defaults to system and stores configured mode cleanly',
        () {
      const defaultData = AppActionableErrorData(
        title: 'Title',
        message: 'Message',
      );
      expect(defaultData.themeMode, AppActionableErrorThemeMode.system);

      const darkData = AppActionableErrorData(
        title: 'Title',
        message: 'Message',
        themeMode: AppActionableErrorThemeMode.dark,
      );
      expect(darkData.themeMode, AppActionableErrorThemeMode.dark);

      const lightData = AppActionableErrorData(
        title: 'Title',
        message: 'Message',
        themeMode: AppActionableErrorThemeMode.light,
      );
      expect(lightData.themeMode, AppActionableErrorThemeMode.light);
    });

    testWidgets('injects M3E dark theme when themeMode is dark in light app',
        (tester) async {
      const data = AppActionableErrorData(
        title: 'Error Gelap',
        message: 'Pesan dalam mode gelap.',
        themeMode: AppActionableErrorThemeMode.dark,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppActionableErrorView(data: data),
          ),
        ),
      );

      final titleElement = tester.element(find.text('Error Gelap'));
      final resolvedM3e = AppTheme.of(titleElement);
      final resolvedFlutter = Theme.of(titleElement);

      expect(resolvedM3e.colorScheme.brightness, Brightness.dark);
      expect(resolvedFlutter.brightness, Brightness.dark);
    });

    testWidgets('injects M3E light theme when themeMode is light in dark app',
        (tester) async {
      const data = AppActionableErrorData(
        title: 'Error Terang',
        message: 'Pesan dalam mode terang.',
        themeMode: AppActionableErrorThemeMode.light,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkThemeData(),
          home: const Scaffold(
            body: AppActionableErrorView(data: data),
          ),
        ),
      );

      final titleElement = tester.element(find.text('Error Terang'));
      final resolvedM3e = AppTheme.of(titleElement);
      final resolvedFlutter = Theme.of(titleElement);

      expect(resolvedM3e.colorScheme.brightness, Brightness.light);
      expect(resolvedFlutter.brightness, Brightness.light);
    });

    testWidgets('preserves ambient theme when themeMode is system',
        (tester) async {
      const data = AppActionableErrorData(
        title: 'Error Sistem',
        message: 'Pesan mengikuti sistem.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppActionableErrorView(data: data),
          ),
        ),
      );

      final titleElement = tester.element(find.text('Error Sistem'));
      final resolvedFlutter = Theme.of(titleElement);

      expect(resolvedFlutter.brightness, Brightness.light);
    });

    testWidgets('calibrates typography roles and font weights properly',
        (tester) async {
      const data = AppActionableErrorData(
        title: 'Judul Kesalahan',
        message: 'Deskripsi pesan.',
        troubleshootingTips: ['Langkah pertama.'],
        technicalDetails: 'Exception: test trace',
      );

      // 1. In-Place / Non-compact view
      await tester.pumpWidget(
        wrapWithTheme(const AppActionableErrorView(data: data)),
      );

      final inPlaceTitle = tester.widget<Text>(find.text('Judul Kesalahan'));
      // In-Place uses headlineSmall (fontSize 24)
      expect(inPlaceTitle.style?.fontSize, 24);

      final troubleshootingHeader =
          tester.widget<Text>(find.text('Cara mengatasi:'));
      // Slot 4 uses titleSmall (fontSize 14)
      expect(troubleshootingHeader.style?.fontSize, 14);

      final toggleTrigger =
          tester.widget<Text>(find.text('Lihat detail teknis'));
      // Slot 5 toggle uses labelMedium (fontSize 12, FontWeight.w500)
      expect(toggleTrigger.style?.fontSize, 12);
      expect(toggleTrigger.style?.fontWeight, FontWeight.w500);

      // Tap to expand technical details
      await tester.tap(find.text('Lihat detail teknis'));
      await tester.pumpAndSettle();

      final details =
          tester.widget<SelectableText>(find.byType(SelectableText));
      // BodySmall without hardcoded fontSize (fontSize 12)
      expect(details.style?.fontSize, 12);
      expect(details.style?.fontFamily, 'monospace');

      // 2. Compact view (Bottom Sheet)
      await tester.pumpWidget(
        wrapWithTheme(
          const AppActionableErrorBottomSheet(data: data),
        ),
      );

      final compactTitle = tester.widget<Text>(find.text('Judul Kesalahan'));
      // Compact uses titleLarge (fontSize 22)
      expect(compactTitle.style?.fontSize, 22);
    });

    group('GoF Design Patterns Tests', () {
      test('Prototype Pattern: copyWith immutably creates variation', () {
        const original = AppActionableErrorData(
          title: 'Akses Ditolak',
          message: 'Anda tidak memiliki izin.',
          troubleshootingTips: ['Hubungi admin'],
          primaryActionLabel: 'Kembali',
        );

        final clone = original.copyWith(
          title: 'Akses Dibatasi',
          isUnexpected: true,
          themeMode: AppActionableErrorThemeMode.dark,
        );

        // Cloned attributes overridden
        expect(clone.title, 'Akses Dibatasi');
        expect(clone.isUnexpected, isTrue);
        expect(clone.themeMode, AppActionableErrorThemeMode.dark);

        // Unmodified attributes preserved
        expect(clone.message, 'Anda tidak memiliki izin.');
        expect(clone.troubleshootingTips, const ['Hubungi admin']);
        expect(clone.primaryActionLabel, 'Kembali');

        // Original unchanged
        expect(original.title, 'Akses Ditolak');
        expect(original.isUnexpected, isFalse);
        expect(original.themeMode, AppActionableErrorThemeMode.system);
      });

      test(
        'Factory Method: actionable produces expected operational error',
        () {
          final data = AppActionableErrorData.actionable(
            title: 'Kamera Tidak Ditemukan',
            message: 'Perangkat tidak mendeteksi kamera.',
            troubleshootingTips: const ['Pasang modul kamera eksternal.'],
            primaryActionLabel: 'Muat ulang',
          );

          expect(data.title, 'Kamera Tidak Ditemukan');
          expect(data.message, 'Perangkat tidak mendeteksi kamera.');
          expect(data.isUnexpected, isFalse);
          expect(data.troubleshootingTips, hasLength(1));
          expect(data.primaryActionLabel, 'Muat ulang');
          expect(data.technicalDetails, isNull);
        },
      );

      test(
        'Factory Method: unexpected produces system error with default action',
        () {
          final data = AppActionableErrorData.unexpected(
            title: 'Terjadi Kesalahan Sistem',
            message: 'Terjadi kegagalan memuat modul.',
            technicalDetails: 'OutOfMemoryError',
          );

          expect(data.title, 'Terjadi Kesalahan Sistem');
          expect(data.message, 'Terjadi kegagalan memuat modul.');
          expect(data.isUnexpected, isTrue);
          expect(data.primaryActionLabel, 'Coba lagi'); // Default label
          expect(data.technicalDetails, 'OutOfMemoryError');
        },
      );

      testWidgets(
        'Facade Pattern: AppActionableError.view renders embedded view',
        (tester) async {
          final data = AppActionableErrorData.actionable(
            title: 'Penyimpanan Penuh',
            message: 'Sisa ruang penyimpanan tidak mencukupi.',
          );

          await tester.pumpWidget(
            wrapWithTheme(
              AppActionableError.view(data: data),
            ),
          );

          expect(find.byType(AppActionableErrorView), findsOneWidget);
          expect(find.text('Penyimpanan Penuh'), findsOneWidget);
          expect(
            find.text('Sisa ruang penyimpanan tidak mencukupi.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Facade & Strategy Pattern: AppActionableError.show delegates',
        (tester) async {
          // 1. Bottom Sheet Modality Strategy
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        AppActionableError.show<void>(
                          context,
                          data: AppActionableErrorData.actionable(
                            title: 'Sheet Error',
                            message: 'Pesan galat sheet.',
                            primaryActionLabel: 'Tutup Sheet',
                            onPrimaryAction: () => Navigator.of(context).pop(),
                          ),
                        );
                      },
                      child: const Text('Show Bottom Sheet'),
                    ),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Show Bottom Sheet'));
          await tester.pumpAndSettle();
          expect(find.byType(AppActionableErrorBottomSheet), findsOneWidget);
          expect(find.text('Sheet Error'), findsOneWidget);

          // Dismiss sheet
          await tester.tap(find.widgetWithText(AppButton, 'Tutup Sheet'));
          await tester.pumpAndSettle();
          expect(find.byType(AppActionableErrorBottomSheet), findsNothing);

          // 2. Dialog Modality Strategy
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        AppActionableError.show<void>(
                          context,
                          data: AppActionableErrorData.actionable(
                            title: 'Dialog Error',
                            message: 'Pesan galat dialog.',
                            primaryActionLabel: 'Tutup Dialog',
                            onPrimaryAction: () => Navigator.of(context).pop(),
                          ),
                          modality: AppActionableErrorModality.dialog,
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Show Dialog'));
          await tester.pumpAndSettle();
          expect(find.byType(AppActionableErrorDialog), findsOneWidget);
          expect(find.text('Dialog Error'), findsOneWidget);

          // Dismiss dialog
          await tester.tap(find.widgetWithText(AppButton, 'Tutup Dialog'));
          await tester.pumpAndSettle();
          expect(find.byType(AppActionableErrorDialog), findsNothing);

          // 3. FullScreen Modality Strategy
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        AppActionableError.show<void>(
                          context,
                          data: AppActionableErrorData.actionable(
                            title: 'FullScreen Error',
                            message: 'Pesan galat full screen.',
                          ),
                          modality: AppActionableErrorModality.fullScreen,
                        );
                      },
                      child: const Text('Show FullScreen'),
                    ),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Show FullScreen'));
          await tester.pumpAndSettle();
          expect(find.byType(AppActionableErrorFullScreen), findsOneWidget);
          expect(find.text('FullScreen Error'), findsOneWidget);
        },
      );

      testWidgets(
        'Facade Pattern: Convenience showBottomSheet and showDialog work',
        (tester) async {
          final data = AppActionableErrorData.actionable(
            title: 'Direct Error',
            message: 'Direct message.',
          );

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightThemeData(),
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        AppActionableError.showBottomSheet<void>(
                          context,
                          data: data,
                        );
                      },
                      child: const Text('Direct Sheet'),
                    ),
                  );
                },
              ),
            ),
          );

          await tester.tap(find.text('Direct Sheet'));
          await tester.pumpAndSettle();
          expect(find.byType(AppActionableErrorBottomSheet), findsOneWidget);
        },
      );
    });

    group('Immutability, Value Equality & Targeted Rebuilds Tests', () {
      test(
        'Equatable value equality evaluates matching instances as equal',
        () {
          const data1 = AppActionableErrorData(
            title: 'Kesalahan Validasi',
            message: 'Data tidak lengkap.',
            troubleshootingTips: ['Isi form'],
            primaryActionLabel: 'Lengkapi',
          );

          const data2 = AppActionableErrorData(
            title: 'Kesalahan Validasi',
            message: 'Data tidak lengkap.',
            troubleshootingTips: ['Isi form'],
            primaryActionLabel: 'Lengkapi',
          );

          expect(data1, equals(data2));
          expect(data1.hashCode, equals(data2.hashCode));

          final modified = data1.copyWith(title: 'Kesalahan Berkas');
          expect(modified, isNot(equals(data1)));
        },
      );

      test(
        'Deep collection equality and defensive immutability on tips',
        () {
          final rawTips = <String>['Langkah 1', 'Langkah 2'];
          final data1 = AppActionableErrorData.actionable(
            title: 'Izin Ditolak',
            message: 'Aktifkan izin di pengaturan.',
            troubleshootingTips: rawTips,
          );

          final data2 = AppActionableErrorData.actionable(
            title: 'Izin Ditolak',
            message: 'Aktifkan izin di pengaturan.',
            troubleshootingTips: const ['Langkah 1', 'Langkah 2'],
          );

          expect(data1, equals(data2));
          expect(data1.hashCode, equals(data2.hashCode));

          // Verifikasi defensive unmodifiable list
          expect(
            () => data1.troubleshootingTips.add('Langkah 3'),
            throwsUnsupportedError,
          );
        },
      );

      test(
        'copyWith enforces defensive unmodifiable list for troubleshootingTips',
        () {
          final original = AppActionableErrorData.actionable(
            title: 'Izin Ditolak',
            message: 'Aktifkan izin di pengaturan.',
            troubleshootingTips: const ['Langkah 1'],
          );

          final mutableList = <String>['Langkah Baru 1', 'Langkah Baru 2'];
          final updated = original.copyWith(
            troubleshootingTips: mutableList,
          );

          // Verifikasi bahwa updated.troubleshootingTips tidak dapat dimutasi
          expect(
            () => updated.troubleshootingTips.add('Langkah Baru 3'),
            throwsUnsupportedError,
          );

          // Mutasi pada mutableList asli tidak mencemari updated
          mutableList.add('Langkah Tambahan Eksternal');
          expect(updated.troubleshootingTips.length, equals(2));
          expect(
            updated.troubleshootingTips,
            equals(['Langkah Baru 1', 'Langkah Baru 2']),
          );

          // Verifikasi optimasi const list ketika empty list diberikan
          final emptyUpdated = original.copyWith(
            troubleshootingTips: <String>[],
          );
          expect(emptyUpdated.troubleshootingTips, isEmpty);
          expect(
            identical(emptyUpdated.troubleshootingTips, const <String>[]),
            isTrue,
          );
        },
      );

      test(
        'Action callback presence matches equality without closure identity',
        () {
          final dataWithAction1 = AppActionableErrorData.actionable(
            title: 'Galat Jaringan',
            message: 'Periksa koneksi internet.',
            primaryActionLabel: 'Coba lagi',
            onPrimaryAction: () {},
          );

          final dataWithAction2 = AppActionableErrorData.actionable(
            title: 'Galat Jaringan',
            message: 'Periksa koneksi internet.',
            primaryActionLabel: 'Coba lagi',
            onPrimaryAction: () {},
          );

          final dataWithoutAction = AppActionableErrorData.actionable(
            title: 'Galat Jaringan',
            message: 'Periksa koneksi internet.',
            primaryActionLabel: 'Coba lagi',
          );

          // Callbacks closure references differ, but props evaluate equal
          expect(dataWithAction1, equals(dataWithAction2));
          expect(dataWithAction1.hashCode, equals(dataWithAction2.hashCode));

          // Presence vs absence evaluates not equal
          expect(dataWithAction1, isNot(equals(dataWithoutAction)));
        },
      );

      testWidgets(
        'Targeted Rebuilds: Toggling accordion scopes state in Slot 5',
        (tester) async {
          final data = AppActionableErrorData.unexpected(
            title: 'Sistem Terhenti',
            message: 'Terjadi pengecualian runtime.',
            technicalDetails: 'StateError: Invalid element',
          );

          await tester.pumpWidget(
            wrapWithTheme(AppActionableErrorView(data: data)),
          );

          expect(find.text('Lihat detail teknis'), findsOneWidget);
          expect(find.text('StateError: Invalid element'), findsNothing);

          // Tap to expand
          await tester.tap(find.text('Lihat detail teknis'));
          await tester.pumpAndSettle();

          expect(find.text('Sembunyikan detail teknis'), findsOneWidget);
          expect(find.text('StateError: Invalid element'), findsOneWidget);

          // Tap to collapse
          await tester.tap(find.text('Sembunyikan detail teknis'));
          await tester.pumpAndSettle();

          expect(find.text('Lihat detail teknis'), findsOneWidget);
          expect(find.text('StateError: Invalid element'), findsNothing);
        },
      );
    });
  });
}

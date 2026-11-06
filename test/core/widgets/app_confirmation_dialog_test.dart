import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_button.dart';
import 'package:kawalo_mobile/core/widgets/app_dialog.dart';

void main() {
  group('AppConfirmationDialog Tests', () {
    testWidgets('renders title, message, cancel, and confirm buttons correctly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppConfirmationDialog(
              title: 'Hapus Manajemen',
              message: 'Manajemen bisa ditambahkan kembali nanti.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hapus Manajemen'), findsOneWidget);
      expect(
        find.text('Manajemen bisa ditambahkan kembali nanti.'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    });

    testWidgets('tapping cancel triggers onCancel callback', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Scaffold(
            body: AppConfirmationDialog(
              title: 'Hapus Manajemen',
              message: 'Konfirmasi pembatalan',
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('tapping confirm triggers onConfirm callback', (tester) async {
      var confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Scaffold(
            body: AppConfirmationDialog(
              title: 'Hapus Manajemen',
              message: 'Konfirmasi penghapusan',
              onConfirm: () => confirmCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(confirmCalled, isTrue);
    });

    testWidgets('showAppConfirmationDialog pops false when cancel is tapped',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAppConfirmationDialog(
                    context: context,
                    title: 'Hapus Manajemen',
                    message: 'Manajemen bisa ditambahkan kembali nanti.',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Manajemen'), findsOneWidget);

      // Ketuk Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('Hapus Manajemen'), findsNothing);
    });

    testWidgets('showAppConfirmationDialog pops true when confirm is tapped',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAppConfirmationDialog(
                    context: context,
                    title: 'Hapus Manajemen',
                    message: 'Manajemen bisa ditambahkan kembali nanti.',
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Manajemen'), findsOneWidget);

      // Ketuk Hapus
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Hapus Manajemen'), findsNothing);
    });

    testWidgets('renders optional icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppConfirmationDialog(
              title: 'Hapus Manajemen',
              message: 'Deskripsi',
              icon: Icon(Icons.delete_outline, key: Key('dialog_icon')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dialog_icon')), findsOneWidget);
    });

    testWidgets(
        'confirm button decorator uses error foreground '
        'when isDestructive is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppConfirmationDialog(
              title: 'Hapus',
              message: 'Pesan',
              confirmText: 'Hapus Akun',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(AppConfirmationDialog));
      final expectedColor = AppTheme.of(element).colorScheme.error;
      final confirmButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Hapus Akun'),
      );
      final decoration = confirmButton.decoration;
      expect(decoration, isNotNull);
      expect(decoration?.foregroundColor?.resolve({}), expectedColor);
    });

    testWidgets(
        'confirm button decorator is null when isDestructive is false and '
        'confirmTextColor is omitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppConfirmationDialog(
              title: 'Simpan',
              message: 'Pesan',
              confirmText: 'Lanjutkan',
              isDestructive: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Lanjutkan'),
      );
      expect(confirmButton.decoration, isNull);
    });

    testWidgets(
        'cancel and confirm decorators apply custom colors when specified',
        (tester) async {
      const customCancelBg = Color(0xFFEEEEEE);
      const customCancelText = Color(0xFF333333);
      const customConfirmText = Color(0xFF990000);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: AppConfirmationDialog(
              title: 'Ubah Data',
              message: 'Pesan',
              cancelText: 'Kembali',
              confirmText: 'Kirim',
              cancelButtonColor: customCancelBg,
              cancelTextColor: customCancelText,
              confirmTextColor: customConfirmText,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cancelButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Kembali'),
      );
      final confirmButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Kirim'),
      );

      expect(
        cancelButton.decoration?.backgroundColor?.resolve({}),
        customCancelBg,
      );
      expect(
        cancelButton.decoration?.foregroundColor?.resolve({}),
        customCancelText,
      );
      expect(
        confirmButton.decoration?.foregroundColor?.resolve({}),
        customConfirmText,
      );
    });
  });
}

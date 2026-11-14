import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:kawalo_mobile/features/home/presentation/widgets/home_layout_sheet.dart';

void main() {
  setUp(AppSnackbar.hideCurrent);

  /// Opens the sheet; the record holds the sheet's pending result.
  Future<({Future<HomeLayout?> result})> pump(
    WidgetTester tester, {
    HomeLayout layout = HomeLayout.fallback,
    bool showPtt = true,
  }) async {
    late Future<HomeLayout?> result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => result = HomeLayoutSheet.show(
                context,
                layout: layout,
                showPtt: showPtt,
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    return (result: result);
  }

  Finder switchOf(String label) => find.descendant(
    of: find.bySemanticsLabel('Tampilkan $label'),
    matching: find.byType(Switch),
  );

  testWidgets('a fifth visible card is refused', (tester) async {
    await pump(tester);
    expect(find.textContaining('4 dari 4 kartu tugas tampil'), findsOneWidget);

    await tester.tap(switchOf('Buku Tamu'));
    await tester.pump();
    expect(
      find.text('Maksimal 4 kartu tugas. Sembunyikan kartu lain dulu.'),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(switchOf('Buku Tamu')).value, isFalse);
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });

  testWidgets('SOS cannot be hidden', (tester) async {
    await pump(tester);
    expect(tester.widget<Switch>(switchOf('SOS')).onChanged, isNull);
  });

  testWidgets('swap and reorder, then Simpan returns the layout', (
    tester,
  ) async {
    final (:result) = await pump(tester);

    await tester.tap(switchOf('Patroli'));
    await tester.pump();
    await tester.tap(switchOf('Buku Tamu'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Naikkan SOS'));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final layout = await result;
    expect(layout!.visible, [
      HomeCard.sos,
      HomeCard.ptt,
      HomeCard.inc,
      HomeCard.gst,
    ]);
    expect(layout.isValid, isTrue);
  });

  testWidgets('without PTT the row is not listed and PTT is saved hidden', (
    tester,
  ) async {
    final (:result) = await pump(tester, showPtt: false);
    expect(switchOf('PTT'), findsNothing);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect((await result)!.hidden, contains(HomeCard.ptt));
  });
}

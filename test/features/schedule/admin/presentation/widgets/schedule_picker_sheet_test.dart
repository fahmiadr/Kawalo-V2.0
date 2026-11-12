import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/features/schedule/admin/presentation/widgets/schedule_picker_sheet.dart';

void main() {
  final options = [
    for (var i = 0; i < 12; i++)
      PickerOption<int>(
        value: i,
        title: 'Personil $i',
        subtitle: 'p$i@mail.id',
      ),
  ];

  Widget host({required bool searchable}) => M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: SchedulePickerSheet<int>(
            title: 'Pilih personil',
            options: options,
            selected: null,
            searchable: searchable,
          ),
        ),
      ),
    ),
  );

  testWidgets('the first row sits right under the title', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(searchable: false));

    final title = tester.getBottomLeft(find.text('Pilih personil'));
    final first = tester.getTopLeft(find.text('Personil 0'));
    expect(first.dy - title.dy, lessThan(40));
  });

  testWidgets('a searchable sheet keeps its height while filtering and stays '
      'above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(searchable: true));
    await tester.pumpAndSettle();

    final before = tester.getSize(find.byType(SchedulePickerSheet<int>));
    final field = tester.getBottomLeft(find.byType(EditableText));
    expect(field.dy, lessThanOrEqualTo(800 - 300));

    await tester.enterText(find.byType(EditableText), 'Personil 11');
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Personil 11'),
      ),
      findsOneWidget,
    );
    expect(find.text('Personil 3'), findsNothing);
    expect(tester.getSize(find.byType(SchedulePickerSheet<int>)), before);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_button_group.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

void main() {
  group('AppButtonGroup / M3EButtonGroup Tests', () {
    testWidgets('renders actions and handles selection changes',
        (WidgetTester tester) async {
      int? selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return M3EButtonGroup(
                  selectedIndex: selectedIndex,
                  onSelectedIndexChanged: (i) {
                    setState(() => selectedIndex = i);
                  },
                  actions: const [
                    M3EButtonGroupAction(label: Text('Day')),
                    M3EButtonGroupAction(label: Text('Week')),
                    M3EButtonGroupAction(label: Text('Month')),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Day'), findsWidgets);
      expect(find.text('Week'), findsWidgets);
      expect(find.text('Month'), findsWidgets);

      await tester.tap(find.text('Week').first);
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(1));
    });

    testWidgets('renders connected variant properly',
        (WidgetTester tester) async {
      var selectedIndices = {0};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return M3EButtonGroup(
                  type: M3EButtonGroupType.connected,
                  selectedIndices: selectedIndices,
                  onSelectedIndicesChanged: (indices) {
                    setState(() => selectedIndices = indices);
                  },
                  actions: const [
                    M3EButtonGroupAction(icon: Icon(Icons.format_align_left)),
                    M3EButtonGroupAction(
                      icon: Icon(Icons.format_align_center),
                    ),
                    M3EButtonGroupAction(icon: Icon(Icons.format_align_right)),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.format_align_left), findsWidgets);
      expect(find.byIcon(Icons.format_align_center), findsWidgets);
      expect(find.byIcon(Icons.format_align_right), findsWidgets);
    });
  });
}

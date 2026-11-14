import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_round_action_button.dart';

void main() {
  Widget host(Widget button, {PageController? controller}) => MaterialApp(
    theme: AppTheme.lightThemeData(),
    home: Scaffold(
      body: PageView(
        controller: controller,
        children: [
          Center(child: button),
          const Center(child: Text('halaman 2')),
        ],
      ),
    ),
  );

  testWidgets('hold mode: start on press, end on release; a drag on it does '
      'not swipe the page', (tester) async {
    final calls = <String>[];
    final controller = PageController();
    await tester.pumpWidget(
      host(
        AppRoundActionButton(
          icon: Icons.mic,
          label: 'Tahan untuk bicara',
          tone: KawaloTones.light.ptt,
          onHoldStart: () => calls.add('start'),
          onHoldEnd: () => calls.add('end'),
        ),
        controller: controller,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppRoundActionButton)),
    );
    await gesture.moveBy(const Offset(-300, 0));
    await tester.pump();
    expect(calls, ['start']);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(calls, ['start', 'end']);
    expect(controller.page, 0);
  });

  testWidgets('a hold is released when the button is removed mid-hold', (
    tester,
  ) async {
    var ended = 0;
    final button = AppRoundActionButton(
      icon: Icons.mic,
      label: 'Tahan',
      tone: KawaloTones.light.ptt,
      onHoldStart: () {},
      onHoldEnd: () => ended++,
    );
    await tester.pumpWidget(host(button));
    await tester.startGesture(tester.getCenter(find.byType(Center).first));
    await tester.pumpWidget(host(const SizedBox()));

    expect(ended, 1);
  });

  testWidgets('timed hold completes only after the duration', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      host(
        AppRoundActionButton(
          icon: Icons.warning,
          label: 'Tahan 3 detik',
          tone: KawaloTones.light.sos,
          holdDuration: const Duration(seconds: 3),
          onHoldComplete: () => done++,
        ),
      ),
    );

    var gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppRoundActionButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump(const Duration(seconds: 2));
    expect(done, 0);

    gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppRoundActionButton)),
    );
    await tester.pump(); // starts the ticker
    await tester.pump(const Duration(milliseconds: 2900));
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    expect(done, 1);
  });
}

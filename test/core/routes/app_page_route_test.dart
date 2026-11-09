import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/routes/app_page_route.dart';

void main() {
  Future<void> pumpAndPush(
    WidgetTester tester,
    Route<void> Function() routeFactory, {
    bool disableAnimations = false,
  }) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: const SizedBox(),
      ),
    );
    navKey.currentState!.push(routeFactory());
    await tester.pumpAndSettle();
  }

  const settings = RouteSettings(name: '/target');
  Widget builder(BuildContext _) => const Text('child');

  final factories = <String, Route<void> Function()>{
    'fade': () => AppPageRoute.fade<void>(builder: builder, settings: settings),
    'forwardBackward': () => AppPageRoute.forwardBackward<void>(
      builder: builder,
      settings: settings,
    ),
    'slideFade': () =>
        AppPageRoute.slideFade<void>(builder: builder, settings: settings),
  };

  for (final entry in factories.entries) {
    group(entry.key, () {
      test('carries the given RouteSettings name', () {
        expect(entry.value().settings.name, '/target');
      });

      testWidgets('renders the child', (tester) async {
        await pumpAndPush(tester, entry.value);

        expect(find.text('child'), findsOneWidget);
      });

      testWidgets('still renders the child with reduced motion', (
        tester,
      ) async {
        await pumpAndPush(tester, entry.value, disableAnimations: true);

        expect(find.text('child'), findsOneWidget);
        expect(find.byType(SlideTransition), findsNothing);
      });
    });
  }

  test('settings are optional', () {
    expect(AppPageRoute.fade<void>(builder: builder).settings.name, isNull);
  });
}

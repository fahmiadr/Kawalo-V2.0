import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/routes/app_route_observer.dart';

void main() {
  late AppRouteObserver observer;
  late GlobalKey<NavigatorState> navKey;

  Route<void> page(String? name) => MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => Text(name ?? 'unnamed'),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        navigatorObservers: [observer],
        home: const SizedBox(),
      ),
    );
  }

  setUp(() {
    observer = AppRouteObserver();
    navKey = GlobalKey<NavigatorState>();
  });

  testWidgets('tracks the MaterialApp home route as root', (tester) async {
    await pumpApp(tester);

    expect(observer.currentRouteName, '/');
    expect(observer.isOpen('/'), isTrue);
    expect(observer.isOpen('/x'), isFalse);
  });

  testWidgets('tracks push and pop', (tester) async {
    await pumpApp(tester);

    navKey.currentState!.push(page('/a'));
    await tester.pumpAndSettle();
    navKey.currentState!.push(page('/b'));
    await tester.pumpAndSettle();

    expect(observer.currentRouteName, '/b');
    expect(observer.isOpen('/a'), isTrue);
    expect(observer.isOpen('/b'), isTrue);

    navKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(observer.currentRouteName, '/a');
    expect(observer.isOpen('/b'), isFalse);
  });

  testWidgets('pushReplacement swaps the old route for the new one', (
    tester,
  ) async {
    await pumpApp(tester);
    navKey.currentState!.push(page('/a'));
    await tester.pumpAndSettle();

    navKey.currentState!.pushReplacement(page('/b'));
    await tester.pumpAndSettle();

    expect(observer.currentRouteName, '/b');
    expect(observer.isOpen('/a'), isFalse);
    expect(observer.isOpen('/'), isTrue);
  });

  testWidgets('pushAndRemoveUntil clears removed routes', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(page('/a'));
    await tester.pumpAndSettle();
    navKey.currentState!.push(page('/b'));
    await tester.pumpAndSettle();

    navKey.currentState!.pushAndRemoveUntil(page('/c'), (_) => false);
    await tester.pumpAndSettle();

    expect(observer.currentRouteName, '/c');
    expect(observer.isOpen('/'), isFalse);
    expect(observer.isOpen('/a'), isFalse);
    expect(observer.isOpen('/b'), isFalse);
  });

  testWidgets('removeRoute drops a route from the middle of the stack', (
    tester,
  ) async {
    await pumpApp(tester);
    final a = page('/a');
    navKey.currentState!.push(a);
    await tester.pumpAndSettle();
    navKey.currentState!.push(page('/b'));
    await tester.pumpAndSettle();

    navKey.currentState!.removeRoute(a);
    await tester.pumpAndSettle();

    expect(observer.isOpen('/a'), isFalse);
    expect(observer.currentRouteName, '/b');
  });

  testWidgets('unnamed routes such as dialogs are skipped', (tester) async {
    await pumpApp(tester);
    navKey.currentState!.push(page('/a'));
    await tester.pumpAndSettle();

    unawaited(
      showDialog<void>(
        context: navKey.currentContext!,
        builder: (_) => const AlertDialog(title: Text('dialog')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('dialog'), findsOneWidget);
    expect(observer.currentRouteName, '/a');

    navKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('dialog'), findsNothing);
    expect(observer.currentRouteName, '/a');
  });

  testWidgets('currentRouteName is null when no route is named', (
    tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        navigatorObservers: [observer],
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: const RouteSettings(),
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: const SizedBox(),
      ),
    );

    expect(observer.currentRouteName, isNull);
  });
}

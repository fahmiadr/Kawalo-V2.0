import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_user_avatar.dart';

void main() {
  Widget host(Widget child) => M3EMaterialApp(
    data: AppTheme.m3eLight(),
    home: Scaffold(body: child),
  );

  test('initialsOf takes the first letters of the first words', () {
    expect(AppUserAvatar.initialsOf('budi santoso'), 'B');
    expect(AppUserAvatar.initialsOf('budi santoso', max: 2), 'BS');
    expect(AppUserAvatar.initialsOf('  '), '?');
    expect(AppUserAvatar.initialsOf('Siti', max: 2), 'S');
  });

  testWidgets('shows the initial when there is no photo', (tester) async {
    await tester.pumpWidget(host(const AppUserAvatar(name: 'Budi Santoso')));
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('ignores a non-http photo value', (tester) async {
    await tester.pumpWidget(
      host(const AppUserAvatar(name: 'Siti', imageUrl: 'N/A')),
    );
    expect(find.text('S'), findsOneWidget);
  });
}

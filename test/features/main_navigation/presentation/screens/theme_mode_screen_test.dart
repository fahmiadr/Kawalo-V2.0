import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/cubit/theme_mode_cubit.dart';
import 'package:kawalo_mobile/features/main_navigation/presentation/screens/theme_mode_screen.dart';

void main() {
  testWidgets('tapping an option applies it immediately', (tester) async {
    final cubit = ThemeModeCubit(null);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: ThemeModeScreen()),
      ),
    );

    expect(find.text('Otomatis'), findsOneWidget);
    expect(find.text('Terang'), findsOneWidget);
    expect(find.text('Gelap'), findsOneWidget);

    await tester.tap(find.text('Gelap'));
    await tester.pump();
    expect(cubit.state, ThemeMode.dark);

    await tester.tap(find.text('Otomatis'));
    await tester.pump();
    expect(cubit.state, ThemeMode.system);
  });
}

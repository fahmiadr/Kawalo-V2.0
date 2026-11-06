import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_spacing.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/widgets/app_section_header.dart';

void main() {
  Widget buildFrame({
    required String title,
    String? subtitle,
    Widget? trailing,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.space50),
  }) {
    return M3ETheme(
      data: AppTheme.m3eLight(),
      child: MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: AppSectionHeader(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            padding: padding,
          ),
        ),
      ),
    );
  }

  group('AppSectionHeader Tests', () {
    testWidgets('renders title and subtitle correctly', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          title: 'Informasi Publikasi',
          subtitle: 'Pengaturan target audiens dan penyiaran.',
        ),
      );

      expect(find.text('Informasi Publikasi'), findsOneWidget);
      expect(
        find.text('Pengaturan target audiens dan penyiaran.'),
        findsOneWidget,
      );
    });

    testWidgets('renders without subtitle when omitted', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          title: 'Judul Tunggal',
        ),
      );

      expect(find.text('Judul Tunggal'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          title: 'Dengan Trailing',
          trailing: const Icon(Icons.arrow_forward),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });
}

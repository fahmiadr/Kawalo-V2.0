import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_svg_icon.dart';

void main() {
  group('AppSvgIcon Tests', () {
    testWidgets('renders SvgPicture with specified asset path', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSvgIcon(
              KawaloVectors.home01,
              size: 32,
              color: Colors.blue,
              semanticLabel: 'Home icon',
            ),
          ),
        ),
      );

      expect(find.byType(AppSvgIcon), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);

      final svgWidget = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgWidget.width, 32);
      expect(svgWidget.height, 32);
      expect(svgWidget.semanticsLabel, 'Home icon');
    });

    testWidgets('inherits size and color from IconTheme when not specified',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightThemeData(),
          home: const Scaffold(
            body: IconTheme(
              data: IconThemeData(
                size: 28,
                color: Colors.green,
              ),
              child: AppSvgIcon(KawaloVectors.kanban),
            ),
          ),
        ),
      );

      final svgWidget = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgWidget.width, 28);
      expect(svgWidget.height, 28);
      expect(
        svgWidget.colorFilter,
        const ColorFilter.mode(Colors.green, BlendMode.srcIn),
      );
    });
  });
}

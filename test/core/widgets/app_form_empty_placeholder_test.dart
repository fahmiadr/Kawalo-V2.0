import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/theme/app_theme.dart';
import 'package:kawalo_mobile/core/theme/kawalo_vectors.dart';
import 'package:kawalo_mobile/core/widgets/app_form_empty_placeholder.dart';
import 'package:kawalo_mobile/core/widgets/app_loading_indicator.dart';

void main() {
  Widget buildFrame({
    required String title,
    required String subtitle,
    String? vectorIcon = KawaloVectors.camera01,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return M3ETheme(
      data: AppTheme.m3eLight(),
      child: MaterialApp(
        theme: AppTheme.lightThemeData(),
        home: Scaffold(
          body: AppFormEmptyPlaceholder(
            title: title,
            subtitle: subtitle,
            vectorIcon: vectorIcon,
            isLoading: isLoading,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('AppFormEmptyPlaceholder Tests', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          title: 'Lampirkan Foto Tamu',
          subtitle: 'Ketuk untuk mengambil foto kamera atau galeri',
        ),
      );

      expect(find.text('Lampirkan Foto Tamu'), findsOneWidget);
      expect(
        find.text('Ketuk untuk mengambil foto kamera atau galeri'),
        findsOneWidget,
      );
    });

    testWidgets('invokes onTap callback when pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildFrame(
          title: 'Lampirkan Foto Tamu',
          subtitle: 'Ketuk untuk mengambil foto kamera atau galeri',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Lampirkan Foto Tamu'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildFrame(
          title: 'Memproses...',
          subtitle: 'Mohon tunggu',
          isLoading: true,
        ),
      );

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/widgets/app_emoji_text.dart';

void main() {
  group('AppEmojiText Widget Tests', () {
    testWidgets('renders plain text and RichText correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmojiText('Halo 🥇 Kawalo'),
          ),
        ),
      );

      expect(find.byType(AppEmojiText), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/core/utils/emoji_parser.dart';

void main() {
  group('EmojiParser Tests', () {
    test('emojiToHex correctly converts single and skin tone emojis', () {
      expect(EmojiParser.emojiToHex('🥇'), equals('1f947'));
      expect(EmojiParser.emojiToHex('👋'), equals('1f44b'));
      expect(EmojiParser.emojiToHex('👋🏻'), equals('1f44b-1f3fb'));
    });

    test('parseSegments correctly splits text and emojis', () {
      const input = 'Halo 🥇 Selamat Datang 🚀';
      final segments = EmojiParser.parseSegments(input);

      expect(segments.length, equals(4));

      expect(segments[0].text, equals('Halo '));
      expect(segments[0].isEmoji, isFalse);

      expect(segments[1].text, equals('🥇'));
      expect(segments[1].isEmoji, isTrue);
      expect(segments[1].hexCode, equals('1f947'));

      expect(segments[2].text, equals(' Selamat Datang '));
      expect(segments[2].isEmoji, isFalse);

      expect(segments[3].text, equals('🚀'));
      expect(segments[3].isEmoji, isTrue);
      expect(segments[3].hexCode, equals('1f680'));
    });
  });
}

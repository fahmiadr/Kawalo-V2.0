import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Segment resulting from parsing text into plain text chunks and emoji chunks
class EmojiSegment {
  const EmojiSegment({
    required this.text,
    this.isEmoji = false,
    this.hexCode,
  });

  final String text;
  final bool isEmoji;
  final String? hexCode;
}

/// Helper utility for parsing Unicode emojis and mapping them to local
/// Fluent Emoji Color SVG asset paths.
abstract class EmojiParser {
  /// Check if a grapheme cluster contains Unicode emoji codepoints
  static bool isEmoji(String char) {
    for (final rune in char.runes) {
      if (rune >= 0x1F300 && rune <= 0x1FAFF) return true;
      if (rune >= 0x2600 && rune <= 0x27BF) return true;
      if (rune >= 0x2300 && rune <= 0x23FF) return true;
      if (rune >= 0x1F1E6 && rune <= 0x1F1FF) return true;
      if (rune == 0x2B50 || rune == 0x203C || rune == 0x2049) return true;
    }
    return false;
  }

  /// Convert an emoji string to dash-separated hex representation
  /// (e.g., '🥇' -> '1f947', '👋🏻' -> '1f44b-1f3fb').
  static String emojiToHex(String emoji) {
    final runes = emoji.runes.where((r) => r != 0xfe0f).toList();
    if (runes.isEmpty) {
      runes.addAll(emoji.runes);
    }
    return runes.map((r) => r.toRadixString(16).toLowerCase()).join('-');
  }

  /// Parse a raw string into structured [EmojiSegment] items
  static List<EmojiSegment> parseSegments(String text) {
    if (text.isEmpty) return const [];

    final segments = <EmojiSegment>[];
    final currentText = StringBuffer();

    for (final char in text.characters) {
      if (isEmoji(char)) {
        if (currentText.isNotEmpty) {
          segments.add(EmojiSegment(text: currentText.toString()));
          currentText.clear();
        }
        final hex = emojiToHex(char);
        segments.add(
          EmojiSegment(
            text: char,
            isEmoji: true,
            hexCode: hex,
          ),
        );
      } else {
        currentText.write(char);
      }
    }

    if (currentText.isNotEmpty) {
      segments.add(EmojiSegment(text: currentText.toString()));
    }

    return segments;
  }

  /// Build a list of [InlineSpan] objects for [RichText] rendering.
  /// Text chunks use [parentStyle], while emoji chunks render as
  /// [WidgetSpan] containing [SvgPicture.asset] for Fluent Emoji (Color).
  static List<InlineSpan> buildSpans(
    String text, {
    required TextStyle parentStyle,
    double? emojiSize,
  }) {
    final fontSize = parentStyle.fontSize ?? 14.0;
    final effectiveEmojiSize = emojiSize ?? (fontSize * 1.25);
    final segments = parseSegments(text);

    final spans = <InlineSpan>[];

    for (final seg in segments) {
      if (!seg.isEmoji || seg.hexCode == null) {
        spans.add(TextSpan(text: seg.text, style: parentStyle));
      } else {
        final assetPath = 'assets/emojis/color/${seg.hexCode}.svg';

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: SvgPicture.asset(
                assetPath,
                width: effectiveEmojiSize,
                height: effectiveEmojiSize,
                placeholderBuilder: (context) {
                  return Text(seg.text, style: parentStyle);
                },
              ),
            ),
          ),
        );
      }
    }

    return spans;
  }
}

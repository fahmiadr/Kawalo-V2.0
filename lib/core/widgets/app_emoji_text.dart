import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/utils/emoji_parser.dart';

/// Clean & Modern Text Widget for Kawalo Mobile that renders plain text
/// using the primary font (Hanken Grotesk) and automatically converts
/// any contained Unicode emojis to 100% offline
/// **Microsoft Fluent Emoji (Color)**.
class AppEmojiText extends StatelessWidget {
  const AppEmojiText(
    this.text, {
    super.key,
    this.style,
    this.emojiSize,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  final String text;
  final TextStyle? style;
  final double? emojiSize;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  final Locale? locale;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle =
        style != null ? defaultStyle.merge(style) : defaultStyle;

    final spans = EmojiParser.buildSpans(
      text,
      parentStyle: effectiveStyle,
      emojiSize: emojiSize,
    );

    return Text.rich(
      TextSpan(
        children: spans,
        style: effectiveStyle,
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}

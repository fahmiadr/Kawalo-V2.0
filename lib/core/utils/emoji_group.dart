/// Standard Emoji Category Groups matching Fluent UI Emoji metadata.json
enum EmojiGroup {
  smileysAndEmotion('Smileys & Emotion'),
  peopleAndBody('People & Body'),
  animalsAndNature('Animals & Nature'),
  foodAndDrink('Food & Drink'),
  travelAndPlaces('Travel & Places'),
  activities('Activities'),
  objects('Objects'),
  symbols('Symbols'),
  flags('Flags'),
  other('Other');

  const EmojiGroup(this.label);

  final String label;

  static EmojiGroup fromLabel(String? label) {
    if (label == null) return EmojiGroup.other;
    return EmojiGroup.values.firstWhere(
      (e) => e.label.toLowerCase() == label.trim().toLowerCase(),
      orElse: () => EmojiGroup.other,
    );
  }
}

/// Exact metadata model matching the original Fluent Emoji metadata.json schema
class EmojiMetadata {
  const EmojiMetadata({
    required this.cldr,
    required this.glyph,
    required this.group,
    required this.keywords,
    required this.unicode,
    this.fromVersion,
    this.tts,
    this.glyphAsUtfInEmoticons,
    this.mappedToEmoticons,
    this.unicodeSkintones,
  });

  factory EmojiMetadata.fromJson(Map<String, dynamic> json) {
    return EmojiMetadata(
      cldr: json['cldr'] as String? ?? '',
      fromVersion: json['fromVersion'] as String?,
      glyph: json['glyph'] as String? ?? '',
      group: EmojiGroup.fromLabel(json['group'] as String?),
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      unicode: json['unicode'] as String? ?? '',
      tts: json['tts'] as String?,
      glyphAsUtfInEmoticons: (json['glyphAsUtfInEmoticons'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      mappedToEmoticons: (json['mappedToEmoticons'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      unicodeSkintones: (json['unicodeSkintones'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  final String cldr;
  final String? fromVersion;
  final String glyph;
  final EmojiGroup group;
  final List<String> keywords;
  final String unicode;
  final String? tts;
  final List<String>? glyphAsUtfInEmoticons;
  final List<String>? mappedToEmoticons;
  final List<String>? unicodeSkintones;

  Map<String, dynamic> toJson() {
    return {
      'cldr': cldr,
      if (fromVersion != null) 'fromVersion': fromVersion,
      'glyph': glyph,
      'group': group.label,
      'keywords': keywords,
      if (glyphAsUtfInEmoticons != null)
        'glyphAsUtfInEmoticons': glyphAsUtfInEmoticons,
      if (mappedToEmoticons != null) 'mappedToEmoticons': mappedToEmoticons,
      if (tts != null) 'tts': tts,
      'unicode': unicode,
      if (unicodeSkintones != null) 'unicodeSkintones': unicodeSkintones,
    };
  }

  /// Convert space-separated unicode string to clean dash-separated hex
  String get primaryHex {
    final parts = unicode.trim().split(' ');
    final clean = parts.where((p) => p.toLowerCase() != 'fe0f').toList();
    if (clean.isEmpty) return parts.first.toLowerCase();
    return clean.join('-').toLowerCase();
  }
}

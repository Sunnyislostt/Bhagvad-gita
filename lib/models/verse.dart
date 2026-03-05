class Verse {
  final String id;
  final int chapter;
  final int verseNumber;
  final String originalScript;
  final String transliteration;
  final String translationEnglish;
  final String deepDiveText;
  final String backgroundHexColor;
  final String wordMeanings;

  Verse({
    required this.id,
    required this.chapter,
    required this.verseNumber,
    required this.originalScript,
    required this.transliteration,
    required this.translationEnglish,
    required this.deepDiveText,
    required this.backgroundHexColor,
    this.wordMeanings = '',
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    final chapter = _asInt(
      json['chapter'] ?? json['chapter_number'] ?? json['chapter_id'],
    );
    final verseNumber = _asInt(
      json['verse_number'] ?? json['verse_id'] ?? json['verse'],
    );
    final fallbackId = canonicalId(chapter, verseNumber);

    final originalScript = _asString(json['original_script'] ?? json['text']);
    final transliteration = _asString(json['transliteration']);
    final wordMeanings = _asString(json['word_meanings']);
    final translationEnglish = _asString(
      json['translation_english'] ?? json['translation'],
    );
    final deepDiveText = _asString(json['deep_dive_text']);

    return Verse(
      id: _normalizeId(json['id'], fallbackId),
      chapter: chapter,
      verseNumber: verseNumber,
      originalScript: originalScript,
      transliteration: transliteration,
      translationEnglish: translationEnglish.isNotEmpty
          ? translationEnglish
          : _fallbackTranslation(wordMeanings),
      deepDiveText: deepDiveText.isNotEmpty
          ? deepDiveText
          : _fallbackDeepDive(wordMeanings),
      backgroundHexColor: _normalizeBackgroundColor(
        json['background_hex_color'],
        chapter,
      ),
      wordMeanings: wordMeanings,
    );
  }

  Verse copyWith({
    String? id,
    int? chapter,
    int? verseNumber,
    String? originalScript,
    String? transliteration,
    String? translationEnglish,
    String? deepDiveText,
    String? backgroundHexColor,
    String? wordMeanings,
  }) {
    return Verse(
      id: id ?? this.id,
      chapter: chapter ?? this.chapter,
      verseNumber: verseNumber ?? this.verseNumber,
      originalScript: originalScript ?? this.originalScript,
      transliteration: transliteration ?? this.transliteration,
      translationEnglish: translationEnglish ?? this.translationEnglish,
      deepDiveText: deepDiveText ?? this.deepDiveText,
      backgroundHexColor: backgroundHexColor ?? this.backgroundHexColor,
      wordMeanings: wordMeanings ?? this.wordMeanings,
    );
  }

  static String canonicalId(int chapter, int verseNumber) {
    final safeChapter = chapter <= 0 ? 1 : chapter;
    final safeVerse = verseNumber <= 0 ? 1 : verseNumber;
    final chapterPart = safeChapter.toString().padLeft(2, '0');
    final versePart = safeVerse.toString().padLeft(2, '0');
    return 'BG_${chapterPart}_$versePart';
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final trimmed = value.trim();
      final exact = int.tryParse(trimmed);
      if (exact != null) {
        return exact;
      }

      // Supports source formats like "5-6" by taking the first numeric part.
      final firstNumericPart = RegExp(r'-?\d+').firstMatch(trimmed)?.group(0);
      if (firstNumericPart != null) {
        return int.tryParse(firstNumericPart) ?? 0;
      }
      return 0;
    }
    return 0;
  }

  static String _asString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static String _normalizeId(dynamic rawId, String fallbackId) {
    final parsed = _asString(rawId);
    if (parsed.isEmpty) {
      return fallbackId;
    }

    final upper = parsed.toUpperCase();
    if (upper.startsWith('BG_')) {
      return upper;
    }

    if (int.tryParse(parsed) != null) {
      return fallbackId;
    }

    return parsed;
  }

  static String _normalizeBackgroundColor(dynamic value, int chapter) {
    final normalized = _asString(value).toUpperCase();
    final hexPattern = RegExp(r'^#([0-9A-F]{6}|[0-9A-F]{8})$');
    if (hexPattern.hasMatch(normalized)) {
      return normalized;
    }

    const palette = <String>[
      '#FFECD2',
      '#D4FC79',
      '#84FAB0',
      '#FFD194',
      '#FF9A9E',
      '#FEE140',
      '#FA709A',
      '#A1C4FD',
      '#FBC2EB',
      '#C2E9FB',
      '#FCCB90',
      '#C2FFD8',
      '#F6D365',
      '#96E6A1',
      '#B5FFFC',
      '#FFD3A5',
      '#FAD0C4',
      '#B8E0D2',
    ];
    final index = (chapter <= 0 ? 1 : chapter) - 1;
    return palette[index % palette.length];
  }

  static String _fallbackTranslation(String wordMeanings) {
    if (wordMeanings.isNotEmpty) {
      return wordMeanings;
    }
    return 'Translation is currently unavailable for this verse.';
  }

  static String _fallbackDeepDive(String wordMeanings) {
    if (wordMeanings.isNotEmpty) {
      return 'Word-by-word insight:\n$wordMeanings';
    }
    return 'Deep dive commentary is currently unavailable for this verse.';
  }
}

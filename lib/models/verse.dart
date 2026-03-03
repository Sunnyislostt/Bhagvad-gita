class Verse {
  final String id;
  final int chapter;
  final int verseNumber;
  final String originalScript;
  final String transliteration;
  final String translationEnglish;
  final String deepDiveText;
  final String backgroundHexColor;

  Verse({
    required this.id,
    required this.chapter,
    required this.verseNumber,
    required this.originalScript,
    required this.transliteration,
    required this.translationEnglish,
    required this.deepDiveText,
    required this.backgroundHexColor,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as String,
      chapter: json['chapter'] as int,
      verseNumber: json['verse_number'] as int,
      originalScript: json['original_script'] as String,
      transliteration: json['transliteration'] as String,
      translationEnglish: json['translation_english'] as String,
      deepDiveText: json['deep_dive_text'] as String,
      backgroundHexColor: json['background_hex_color'] as String,
    );
  }
}

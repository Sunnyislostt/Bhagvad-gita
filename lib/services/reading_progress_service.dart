import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';

class ReadingProgressService {
  static const String _chapterProgressKey = 'chapter_progress';

  Future<Map<int, int>> loadChapterProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chapterProgressKey);
    if (raw == null || raw.isEmpty) {
      return <int, int>{};
    }

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return <int, int>{
        for (final entry in decoded.entries)
          int.tryParse(entry.key) ?? 0: (entry.value as num).toInt(),
      }..remove(0);
    } catch (_) {
      return <int, int>{};
    }
  }

  Future<void> recordVerse(Verse verse) async {
    final current = await loadChapterProgress();
    final previous = current[verse.chapter] ?? 0;
    if (verse.verseNumber <= previous) {
      return;
    }

    current[verse.chapter] = verse.verseNumber;
    final encoded = <String, int>{
      for (final entry in current.entries) entry.key.toString(): entry.value,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chapterProgressKey, json.encode(encoded));
  }
}

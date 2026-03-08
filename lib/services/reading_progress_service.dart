import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';

class ReadingProgressService {
  static const String _chapterProgressKey = 'chapter_progress';

  Future<Map<int, int>> loadChapterProgress() async {
    final chapterReadIds = await loadChapterReadIds();
    return <int, int>{
      for (final entry in chapterReadIds.entries) entry.key: entry.value.length,
    };
  }

  Future<Map<int, Set<String>>> loadChapterReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chapterProgressKey);
    if (raw == null || raw.isEmpty) {
      return <int, Set<String>>{};
    }

    try {
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <int, Set<String>>{};
      }

      final result = <int, Set<String>>{};
      for (final entry in decoded.entries) {
        final chapter = int.tryParse(entry.key);
        if (chapter == null || chapter <= 0) {
          continue;
        }

        final value = entry.value;
        if (value is List<dynamic>) {
          final ids = value
              .map((item) => item.toString().trim())
              .where((id) => id.isNotEmpty)
              .toSet();
          if (ids.isNotEmpty) {
            result[chapter] = ids;
          }
          continue;
        }

        // Backward compatibility for old saved format:
        // chapter -> max verse number reached.
        if (value is num) {
          final maxVerse = value.toInt();
          if (maxVerse <= 0) {
            continue;
          }
          result[chapter] = <String>{
            for (var verseNumber = 1; verseNumber <= maxVerse; verseNumber++)
              Verse.canonicalId(chapter, verseNumber),
          };
        }
      }
      return result;
    } catch (_) {
      return <int, Set<String>>{};
    }
  }

  Future<void> recordVerse(Verse verse) async {
    final verseId = verse.id.trim();
    if (verse.chapter <= 0 || verseId.isEmpty || !verse.countsTowardProgress) {
      return;
    }

    final current = await loadChapterReadIds();
    final chapterReadIds = current.putIfAbsent(verse.chapter, () => <String>{});
    final added = chapterReadIds.add(verseId);
    if (!added) {
      return;
    }

    final encoded = <String, List<String>>{
      for (final entry in current.entries)
        entry.key.toString(): (entry.value.toList()..sort()),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chapterProgressKey, json.encode(encoded));
  }
}

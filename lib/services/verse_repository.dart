import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/verse.dart';

class VerseRepository {
  const VerseRepository();

  static const String _primaryDatasetPath = 'assets/data/verses.json';

  Future<List<Verse>> loadVerses() async {
    final verses = await _loadVerseListFromAsset(_primaryDatasetPath);
    if (verses.isEmpty) {
      return <Verse>[];
    }
    verses.sort(Verse.compareByReadingOrder);
    debugPrint('VerseRepository: loaded dataset count=${verses.length}');
    return verses;
  }

  Future<List<Verse>> _loadVerseListFromAsset(String assetPath) async {
    try {
      // Prevent stale cached bytes when dataset is updated during development.
      rootBundle.evict(assetPath);
      final rawData = await rootBundle.load(assetPath);
      final bytes = rawData.buffer.asUint8List(
        rawData.offsetInBytes,
        rawData.lengthInBytes,
      );
      final decoded = _decodeJson(bytes);
      final list = _extractJsonList(decoded);
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(Verse.fromJson)
          .toList();
    } catch (error) {
      debugPrint('VerseRepository: failed to parse $assetPath -> $error');
      return <Verse>[];
    }
  }

  dynamic _decodeJson(List<int> bytes) {
    try {
      final text = _stripBom(utf8.decode(bytes, allowMalformed: true));
      return json.decode(text);
    } catch (_) {
      final text = _stripBom(latin1.decode(bytes, allowInvalid: true));
      return json.decode(text);
    }
  }

  String _stripBom(String value) {
    if (value.isNotEmpty && value.codeUnitAt(0) == 0xFEFF) {
      return value.substring(1);
    }
    return value;
  }

  List<dynamic> _extractJsonList(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final verses = decoded['verses'];
      if (verses is List<dynamic>) {
        return verses;
      }
    }

    return const <dynamic>[];
  }
}

import 'package:flutter/services.dart';
import '../models/verse.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel(
    'bhagvad_gita_app/widget',
  );

  Future<bool> pinVerse(Verse verse, {required String language}) async {
    try {
      final updated = await _channel
          .invokeMethod<bool>('setVerseForWidget', <String, dynamic>{
            'originalScript': verse.originalScript,
            'translationEnglish': verse.translationEnglish,
            'chapter': verse.chapter,
            'verseNumber': verse.verseNumber,
            'displayLanguage': language,
          });
      return updated ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> setLanguage(String language) async {
    try {
      final updated = await _channel.invokeMethod<bool>(
        'setWidgetLanguage',
        <String, dynamic>{'displayLanguage': language},
      );
      return updated ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

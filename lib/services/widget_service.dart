import 'package:flutter/services.dart';
import '../models/verse.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel(
    'bhagvad_gita_app/widget',
  );
  static const String actionPickVerse = 'pick_verse';

  Future<bool> pinVerse(Verse verse, {required String language}) async {
    try {
      final updated = await _channel
          .invokeMethod<bool>('setVerseForWidget', <String, dynamic>{
            'originalScript': verse.originalScript,
            'translationEnglish': verse.translationEnglish,
            'chapter': verse.chapter,
            'verseNumber': verse.verseNumber,
            'verseLabel': verse.verseLabel,
            'displayLanguage': language,
          });
      return updated ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> setMode(String mode) async {
    final normalizedMode = _normalizeMode(mode);
    try {
      final updated = await _channel.invokeMethod<bool>(
        'setWidgetMode',
        <String, dynamic>{'mode': normalizedMode},
      );
      return updated ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String?> consumeLaunchAction() async {
    try {
      return await _channel.invokeMethod<String>('consumeWidgetLaunchAction');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  void setLaunchActionHandler(Future<void> Function(String action) onAction) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onWidgetLaunchAction') {
        return;
      }
      final args = call.arguments;
      if (args is! Map) {
        return;
      }
      final action = args['action']?.toString();
      if (action == null || action.isEmpty) {
        return;
      }
      await onAction(action);
    });
  }

  void clearLaunchActionHandler() {
    _channel.setMethodCallHandler(null);
  }

  String _normalizeMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    if (normalized == 'random') {
      return 'random';
    }
    return 'fixed';
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

  Future<bool> setTheme(String themeMode) async {
    try {
      final updated = await _channel.invokeMethod<bool>(
        'setWidgetTheme',
        <String, dynamic>{'themeMode': themeMode},
      );
      return updated ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

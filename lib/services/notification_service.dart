import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/verse.dart';
import 'verse_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final VerseRepository _verseRepository = const VerseRepository();

  static const String _prefKey = 'notifications_enabled';
  static const int _daysToSchedule = 30;
  static const int _dailyBaseNotificationId = 1000;
  static const int _dailyVerseHour = 8;

  bool _timeZonesInitialized = false;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    if (await areNotificationsEnabled()) {
      final hasPermission = await _ensureNotificationPermission();
      if (!hasPermission) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKey, false);
        await _plugin.cancelAll();
        return;
      }
      await _scheduleDailyNotifications();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final hasPermission = await _ensureNotificationPermission();
      if (!hasPermission) {
        await prefs.setBool(_prefKey, false);
        await _plugin.cancelAll();
        return;
      }
      await prefs.setBool(_prefKey, true);
      await _scheduleDailyNotifications();
    } else {
      await prefs.setBool(_prefKey, false);
      await _plugin.cancelAll();
    }
  }

  Future<bool> _ensureNotificationPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return true;
    }

    final currentlyEnabled = await androidPlugin.areNotificationsEnabled();
    if (currentlyEnabled ?? true) {
      return true;
    }

    final requested = await androidPlugin.requestNotificationsPermission();
    if (requested == true) {
      return true;
    }

    final afterRequest = await androidPlugin.areNotificationsEnabled();
    return afterRequest ?? false;
  }

  void _initializeTimeZones() {
    if (_timeZonesInitialized) {
      return;
    }
    tzdata.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  Future<void> _scheduleDailyNotifications() async {
    final verses = await _loadVerses();
    if (verses.isEmpty) {
      return;
    }

    _initializeTimeZones();

    const androidDetails = AndroidNotificationDetails(
      'daily_verse',
      'Daily Verse',
      channelDescription: 'Daily Bhagavad Gita verse reminder',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.cancelAll();

    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final dailyVerse = _getTodaysVerse(verses, date);
      final dailyVerseTime = DateTime(
        date.year,
        date.month,
        date.day,
        _dailyVerseHour,
      );

      if (dailyVerseTime.isAfter(now)) {
        await _scheduleNotification(
          id: _dailyBaseNotificationId + dayOffset,
          title: "Daily Verse - Ch.${dailyVerse.chapter}, V.${dailyVerse.verseNumber}",
          verse: dailyVerse,
          scheduledAt: dailyVerseTime,
          notificationDetails: notificationDetails,
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required Verse verse,
    required DateTime scheduledAt,
    required NotificationDetails notificationDetails,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: verse.translationEnglish,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      scheduledDate: tz.TZDateTime.from(scheduledAt.toUtc(), tz.UTC),
    );
  }

  Verse _getTodaysVerse(List<Verse> verses, DateTime date) {
    final index = _daySeed(date) % verses.length;
    return verses[index];
  }

  int _daySeed(DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    return normalizedDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  Future<List<Verse>> _loadVerses() async {
    return _verseRepository.loadVerses();
  }
}

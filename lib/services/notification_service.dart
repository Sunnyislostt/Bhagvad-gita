import 'dart:math';
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
  static const int _todayBaseNotificationId = 1000;
  static const int _randomBaseNotificationId = 2000;
  static const int _todaysVerseHour = 8;
  static const int _randomVerseHour = 20;

  bool _timeZonesInitialized = false;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    if (await areNotificationsEnabled()) {
      await _scheduleDailyNotifications();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (enabled) {
      await _scheduleDailyNotifications();
    } else {
      await _plugin.cancelAll();
    }
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
      final todaysVerse = _getTodaysVerse(verses, date);
      final randomVerse = _getRandomVerseForDate(verses, date, excludeId: todaysVerse.id);

      final todaysVerseTime = DateTime(
        date.year,
        date.month,
        date.day,
        _todaysVerseHour,
      );
      final randomVerseTime = DateTime(
        date.year,
        date.month,
        date.day,
        _randomVerseHour,
      );

      if (todaysVerseTime.isAfter(now)) {
        await _scheduleNotification(
          id: _todayBaseNotificationId + dayOffset,
          title: "Today's Verse - Ch.${todaysVerse.chapter}, V.${todaysVerse.verseNumber}",
          verse: todaysVerse,
          scheduledAt: todaysVerseTime,
          notificationDetails: notificationDetails,
        );
      }

      if (randomVerseTime.isAfter(now)) {
        await _scheduleNotification(
          id: _randomBaseNotificationId + dayOffset,
          title: "Random Verse - Ch.${randomVerse.chapter}, V.${randomVerse.verseNumber}",
          verse: randomVerse,
          scheduledAt: randomVerseTime,
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

  Verse _getRandomVerseForDate(
    List<Verse> verses,
    DateTime date, {
    String? excludeId,
  }) {
    if (verses.length == 1) {
      return verses.first;
    }

    final random = Random((_daySeed(date) * 31) + 7);
    var index = random.nextInt(verses.length);
    if (excludeId != null && verses[index].id == excludeId) {
      index = (index + 1) % verses.length;
    }
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

import 'dart:convert';

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
  static const int _dailySlotCount = 2;
  static const int _morningVerseHour = 8;
  static const int _eveningVerseHour = 18;

  bool _timeZonesInitialized = false;
  Future<void> Function(String verseId)? _onVerseOpenRequested;
  String? _pendingVerseId;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    final launchVerseId = _extractVerseId(launchPayload);
    if (launchVerseId != null) {
      _pendingVerseId = launchVerseId;
    }

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

  Future<void> setVerseOpenHandler(
    Future<void> Function(String verseId) onVerseOpen,
  ) async {
    _onVerseOpenRequested = onVerseOpen;
    final pendingVerseId = _pendingVerseId;
    if (pendingVerseId == null || pendingVerseId.isEmpty) {
      return;
    }

    _pendingVerseId = null;
    await onVerseOpen(pendingVerseId);
  }

  void clearVerseOpenHandler() {
    _onVerseOpenRequested = null;
  }

  Future<void> _scheduleDailyNotifications() async {
    final verses = await _loadVerses();
    if (verses.isEmpty) {
      return;
    }

    _initializeTimeZones();

    const androidDetails = AndroidNotificationDetails(
      'daily_verse',
      'Verse Reminders',
      channelDescription: 'Morning and evening Bhagavad Gita verse reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.cancelAll();

    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final dailySlots = <_NotificationSlot>[
        _NotificationSlot(
          idOffset: 0,
          label: 'Morning Verse',
          scheduledAt: DateTime(date.year, date.month, date.day, _morningVerseHour),
          verse: _verseForDateAndSlot(verses, date, 0),
        ),
        _NotificationSlot(
          idOffset: 1,
          label: 'Evening Verse',
          scheduledAt: DateTime(date.year, date.month, date.day, _eveningVerseHour),
          verse: _verseForDateAndSlot(verses, date, 1),
        ),
      ];

      for (final slot in dailySlots) {
        if (!slot.scheduledAt.isAfter(now)) {
          continue;
        }
        await _scheduleNotification(
          id: _dailyBaseNotificationId + (dayOffset * _dailySlotCount) + slot.idOffset,
          title: '${slot.label} - ${slot.verse.referenceLabel}',
          verse: slot.verse,
          scheduledAt: slot.scheduledAt,
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
      payload: jsonEncode(<String, String>{'verseId': verse.id}),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      scheduledDate: tz.TZDateTime.from(scheduledAt.toUtc(), tz.UTC),
    );
  }

  Verse _verseForDateAndSlot(List<Verse> verses, DateTime date, int slotIndex) {
    final index = (_daySeed(date) + (slotIndex * 97)) % verses.length;
    return verses[index];
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    final verseId = _extractVerseId(response.payload);
    if (verseId == null || verseId.isEmpty) {
      return;
    }

    final handler = _onVerseOpenRequested;
    if (handler != null) {
      await handler(verseId);
      return;
    }

    _pendingVerseId = verseId;
  }

  String? _extractVerseId(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final verseId = decoded['verseId']?.toString().trim();
        if (verseId != null && verseId.isNotEmpty) {
          return verseId;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  int _daySeed(DateTime date) {
    final normalizedDate = DateTime.utc(date.year, date.month, date.day);
    return normalizedDate.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  Future<List<Verse>> _loadVerses() async {
    return _verseRepository.loadVerses();
  }
}

class _NotificationSlot {
  const _NotificationSlot({
    required this.idOffset,
    required this.label,
    required this.scheduledAt,
    required this.verse,
  });

  final int idOffset;
  final String label;
  final DateTime scheduledAt;
  final Verse verse;
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';

/// Manages all local notifications: prayer times, reminders, content alerts.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Channel IDs
  static const _channelPrayer = 'ehsan_prayer_times';
  static const _channelReminder = 'ehsan_reminders';
  static const _channelContent = 'ehsan_content';
  static const _channelHigh = 'ehsan_pathways_high';

  // Notification ID ranges (to avoid clashes)
  static const _prayerBaseId = 100;   // 100–199
  static const _reminderBaseId = 200; // 200–299
  static const _contentBaseId = 300;  // 300+

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Init timezones
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapBackground,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _createChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelPrayer,
        'Prayer Times',
        description: 'Adhan prayer time reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF16A34A),
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelReminder,
        'Learning Reminders',
        description: 'Daily learning and content reminders',
        importance: Importance.defaultImportance,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelContent,
        'New Content',
        description: 'New videos, articles, and podcasts',
        importance: Importance.defaultImportance,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelHigh,
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.high,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Permission request
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    } else if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Prayer time notifications
  // ─────────────────────────────────────────────────────────────────────────

  /// Schedule all prayer notifications for the next 7 days based on location.
  Future<void> schedulePrayerNotifications({
    required double latitude,
    required double longitude,
    required PrayerCalculationMethod method,
    required Map<Prayer, bool> enabledPrayers,
  }) async {
    // Cancel existing prayer notifications first
    await cancelPrayerNotifications();

    final now = DateTime.now();
    int notificationId = _prayerBaseId;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final coords = Coordinates(latitude, longitude);
      final dateComps = DateComponents.from(date);
      final times = PrayerTimes(coords, dateComps, method.params);

      final prayers = <Prayer, DateTime?>{
        Prayer.fajr: times.fajr,
        Prayer.dhuhr: times.dhuhr,
        Prayer.asr: times.asr,
        Prayer.maghrib: times.maghrib,
        Prayer.isha: times.isha,
      };

      for (final entry in prayers.entries) {
        final prayer = entry.key;
        final prayerTime = entry.value;

        if (prayerTime == null) continue;
        if (!(enabledPrayers[prayer] ?? false)) continue;
        if (prayerTime.isBefore(DateTime.now())) continue;

        await _schedulePrayerAt(
          id: notificationId++,
          prayer: prayer,
          scheduledTime: prayerTime,
        );
      }
    }
  }

  Future<void> _schedulePrayerAt({
    required int id,
    required Prayer prayer,
    required DateTime scheduledTime,
  }) async {
    final name = _prayerDisplayName(prayer);
    final arabic = _prayerArabicName(prayer);
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      '$arabic — Time for $name Prayer',
      'It is now time for $name (${PrayerTimesService.formatTime(scheduledTime)}). '
          'May Allah accept your prayers.',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelPrayer,
          'Prayer Times',
          channelDescription: 'Prayer time reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF16A34A),
          ticker: '$name prayer time',
          styleInformation: BigTextStyleInformation(
            'It is now time for $name ($arabic). '
            '${PrayerTimesService.formatTime(scheduledTime)}. '
            'May Allah accept your prayers. Allahu Akbar.',
            summaryText: 'Prayer Reminder',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelPrayerNotifications() async {
    for (int i = _prayerBaseId; i < _reminderBaseId; i++) {
      await _plugin.cancel(i);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Daily learning reminder
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> scheduleDailyLearningReminder({
    required TimeOfDay time,
    required bool enabled,
  }) async {
    await _plugin.cancel(_reminderBaseId);
    if (!enabled) return;

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _reminderBaseId,
      'Daily Learning Reminder 📖',
      'Continue your Islamic knowledge journey — new content is waiting for you.',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminder,
          'Learning Reminders',
          channelDescription: 'Daily learning reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF16A34A),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Jumah (Friday) reminder
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> scheduleJumahReminder({required bool enabled}) async {
    await _plugin.cancel(_reminderBaseId + 1);
    if (!enabled) return;

    // Schedule every Friday at 11:30 AM
    final now = DateTime.now();
    int daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    if (daysUntilFriday == 0 && now.hour >= 12) daysUntilFriday = 7;

    final nextFriday = DateTime(
      now.year, now.month, now.day + daysUntilFriday, 11, 30,
    );

    await _plugin.zonedSchedule(
      _reminderBaseId + 1,
      'Jumu\'ah Mubarak 🕌',
      'It\'s Friday! Time for the blessed Jumu\'ah prayer. May Allah accept your worship.',
      tz.TZDateTime.from(nextFriday, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelPrayer,
          'Prayer Times',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFF59E0B),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Show immediate notification (for FCM foreground messages)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> showImmediate({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await _plugin.show(
      _contentBaseId + id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelContent,
          'New Content',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF16A34A),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true),
      ),
      payload: payload,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cancel all
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> cancelAll() => _plugin.cancelAll();

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _prayerDisplayName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'Fajr';
      case Prayer.sunrise: return 'Sunrise';
      case Prayer.dhuhr: return 'Dhuhr';
      case Prayer.asr: return 'Asr';
      case Prayer.maghrib: return 'Maghrib';
      case Prayer.isha: return 'Isha';
      default: return 'Prayer';
    }
  }

  String _prayerArabicName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.sunrise: return 'الشروق';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      default: return '';
    }
  }
}

@pragma('vm:entry-point')
void _onNotificationTapBackground(NotificationResponse response) {
  // Handle background notification tap — can navigate via global key
}

void _onNotificationTap(NotificationResponse response) {
  // Handle foreground notification tap
}

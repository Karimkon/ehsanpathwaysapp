import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';
import 'package:ehsan_pathways/config/theme.dart';

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

    // Init timezones. getLocation() throws LocationNotFoundException for any
    // identifier not in the bundled tz database, so fall back to UTC rather
    // than letting it crash app startup.
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

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
        ledColor: AppColors.emerald700,
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

  /// On Android 12+ (API 31+), SCHEDULE_EXACT_ALARM requires user consent.
  /// Returns true if exact alarms are permitted (or on platforms where
  /// this check is not needed).
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    return await androidPlugin.canScheduleExactNotifications() ?? false;
  }

  /// Opens the system "Alarms & Reminders" special-access settings page
  /// so the user can grant SCHEDULE_EXACT_ALARM permission.
  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    const channel = MethodChannel('com.ehsanpathways/permissions');
    try {
      await channel.invokeMethod('openAlarmPermissionSettings');
    } catch (_) {
      // Fallback: the plugin may handle it via requestExactAlarmsPermission
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestExactAlarmsPermission();
    }
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

    // Use exact alarms if SCHEDULE_EXACT_ALARM is granted; otherwise fall back
    // to inexact (still reliable within a few minutes on modern Android).
    final useExact = await canScheduleExactAlarms();
    final scheduleMode = useExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

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
          color: AppColors.emerald700,
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
      androidScheduleMode: scheduleMode,
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
          color: AppColors.emerald700,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: await canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Daily deed reminder, after a prayer the user chooses
  // ─────────────────────────────────────────────────────────────────────────

  static const _dailyDeedBaseId = 250; // 250–263: the next 14 days

  /// Remind the user of the daily deed [minutesAfter] the chosen prayer, on
  /// the user's own prayer times, for the next 14 days. A cue tied to an act
  /// already done (the prayer) is what makes a habit stick. Pass `after: null`
  /// to switch it off. Called again on every app start to roll the window on.
  Future<void> scheduleDailyDeedReminders({
    required Prayer? after,
    required double? latitude,
    required double? longitude,
    required PrayerCalculationMethod method,
    String madhab = 'shafi',
    int minutesAfter = 20,
  }) async {
    for (var i = 0; i < 14; i++) {
      await _plugin.cancel(_dailyDeedBaseId + i);
    }
    if (after == null || latitude == null || longitude == null) return;

    final params = method.params;
    if (madhab == 'hanafi') params.madhab = Madhab.hanafi;
    final coords = Coordinates(latitude, longitude);
    final now = DateTime.now();
    final mode = await canScheduleExactAlarms()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (var day = 0; day < 14; day++) {
      final times = PrayerTimes(coords, DateComponents.from(now.add(Duration(days: day))), params);
      final prayerTime = times.timeForPrayer(after);
      if (prayerTime == null) continue;
      final at = prayerTime.toLocal().add(Duration(minutes: minutesAfter));
      if (at.isBefore(now)) continue;

      await _plugin.zonedSchedule(
        _dailyDeedBaseId + day,
        "Today's two minutes 🌱",
        "One verse, one dhikr, one du'a. The most beloved deeds are the consistent ones.",
        tz.TZDateTime.from(at, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelReminder,
            'Learning Reminders',
            channelDescription: 'Daily learning reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            color: AppColors.emerald700,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: false),
        ),
        payload: '/daily',
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
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
          color: AppColors.gold,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true),
      ),
      androidScheduleMode: await canScheduleExactAlarms()
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
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
          color: AppColors.emerald700,
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

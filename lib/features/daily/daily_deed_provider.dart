import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/core/json_read.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/core/services/notification_service.dart';
import 'package:ehsan_pathways/core/services/prayer_times_service.dart';

/// A verse or a Qur'anic du'a: text comes from the stored Qur'an.
class DeedVerse {
  const DeedVerse({required this.key, required this.surah, required this.ayah, required this.reference, this.arabic, this.translation});

  factory DeedVerse.fromJson(Map<String, dynamic> j) => DeedVerse(
        key: jStr(j['key']) ?? '',
        surah: jInt(j['surah']) ?? 1,
        ayah: jInt(j['ayah']) ?? 1,
        reference: jStr(j['reference']) ?? '',
        arabic: jStr(j['arabic']),
        translation: jStr(j['translation']),
      );

  final String key;
  final int surah;
  final int ayah;
  final String reference;
  final String? arabic;
  final String? translation;
}

class DeedDhikr {
  const DeedDhikr({required this.arabic, required this.transliteration, required this.translation, required this.count, required this.virtue, required this.source});

  factory DeedDhikr.fromJson(Map<String, dynamic> j) => DeedDhikr(
        arabic: jStr(j['arabic']) ?? '',
        transliteration: jStr(j['transliteration']) ?? '',
        translation: jStr(j['translation']) ?? '',
        count: jInt(j['count']) ?? 1,
        virtue: jStr(j['virtue']) ?? '',
        source: jStr(j['source']) ?? '',
      );

  final String arabic;
  final String transliteration;
  final String translation;
  final int count;
  final String virtue;
  final String source;
}

class DeedMonth {
  const DeedMonth({required this.label, required this.daysSoFar, required this.activeDays, required this.completeDays, required this.partsByDate});

  factory DeedMonth.fromJson(Map<String, dynamic> j) => DeedMonth(
        label: jStr(j['label']) ?? '',
        daysSoFar: jInt(j['days_so_far']) ?? 0,
        activeDays: jInt(j['active_days']) ?? 0,
        completeDays: jInt(j['complete_days']) ?? 0,
        partsByDate: {
          for (final d in (j['days'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>())
            jStr(d['date']) ?? '': jInt(d['parts']) ?? 0,
        },
      );

  final String label;
  final int daysSoFar;
  final int activeDays;
  final int completeDays;
  final Map<String, int> partsByDate;
}

class DailyDeed {
  const DailyDeed({required this.date, required this.verse, required this.dhikr, required this.dua, required this.done, this.month});

  factory DailyDeed.fromJson(Map<String, dynamic> j) => DailyDeed(
        date: jStr(j['date']) ?? '',
        verse: DeedVerse.fromJson(j['verse'] as Map<String, dynamic>? ?? const {}),
        dhikr: DeedDhikr.fromJson(j['dhikr'] as Map<String, dynamic>? ?? const {}),
        dua: DeedVerse.fromJson(j['dua'] as Map<String, dynamic>? ?? const {}),
        done: {
          for (final p in const ['verse', 'dhikr', 'dua'])
            p: jBool((j['done'] as Map<String, dynamic>? ?? const {})[p]) ?? false,
        },
        month: j['month'] is Map<String, dynamic> ? DeedMonth.fromJson(j['month'] as Map<String, dynamic>) : null,
      );

  final String date;
  final DeedVerse verse;
  final DeedDhikr dhikr;
  final DeedVerse dua;
  final Map<String, bool> done;
  final DeedMonth? month;

  int get doneCount => done.values.where((v) => v).length;
}

/// The phone's own date, so "today" matches the user's day, not the server's.
String localDate([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final dailyDeedProvider = FutureProvider.autoDispose<DailyDeed>((ref) async {
  final res = await ref.read(apiProvider).get<Map<String, dynamic>>('/daily-deed', queryParameters: {'date': localDate()});
  return DailyDeed.fromJson((res.data?['data'] as Map<String, dynamic>?) ?? const {});
});

Future<void> markDeedPart(Ref ref, String part) async {
  await ref.read(apiProvider).post('/daily-deed/$part', data: {'date': localDate()});
  ref.invalidate(dailyDeedProvider);
}

final dailyDeedActionsProvider = Provider<Future<void> Function(String)>((ref) => (part) => markDeedPart(ref, part));

// ---------------------------------------------------------------------------
// Reminder after a chosen prayer (kept on the device)
// ---------------------------------------------------------------------------

const _reminderKey = 'daily_deed_after_prayer';

const deedReminderChoices = <String, Prayer?>{
  'Off': null,
  'After Fajr': Prayer.fajr,
  'After Dhuhr': Prayer.dhuhr,
  'After Asr': Prayer.asr,
  'After Maghrib': Prayer.maghrib,
  'After Isha': Prayer.isha,
};

class DeedReminder {
  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_reminderKey);
    return deedReminderChoices.containsKey(saved) ? saved! : 'Off';
  }

  /// Save the choice and schedule it. Returns false when the app has no
  /// location yet, so prayer times cannot be worked out.
  static Future<bool> save(String choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderKey, choice);
    return reschedule();
  }

  /// Called on start-up too, so the 14-day window keeps rolling forward.
  static Future<bool> reschedule() async {
    final prefs = await SharedPreferences.getInstance();
    final prayer = deedReminderChoices[prefs.getString(_reminderKey) ?? 'Off'];
    final s = await PrayerTimesService.loadSettings();
    final lat = s['lat'] as double?;
    final lng = s['lng'] as double?;
    final method = PrayerCalculationMethod.values.firstWhere(
      (m) => m.name == s['method'],
      orElse: () => PrayerCalculationMethod.muslimWorldLeague,
    );

    await NotificationService.instance.scheduleDailyDeedReminders(
      after: prayer,
      latitude: lat,
      longitude: lng,
      method: method,
      madhab: s['madhab'] as String? ?? 'shafi',
    );
    return prayer == null || (lat != null && lng != null);
  }
}

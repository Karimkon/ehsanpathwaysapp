import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';

/// Immutable snapshot of a day's prayer schedule for a resolved location.
///
/// Produced by [prayerScheduleProvider] and consumed by both the full
/// prayer-times screen and the Home "Next Prayer" card.
class PrayerScheduleData {
  final List<PrayerEntry> entries;
  final PrayerTimes times;
  final PrayerCalculationMethod method;
  final String locationLabel;
  final double latitude;
  final double longitude;

  const PrayerScheduleData({
    required this.entries,
    required this.times,
    required this.method,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
  });

  /// Entries that represent actual prayers (excludes Sunrise, which is
  /// informational only).
  List<PrayerEntry> get prayerEntries =>
      entries.where((e) => e.prayer != Prayer.sunrise).toList();

  /// The [Prayer] currently in progress (or [Prayer.isha] late at night).
  Prayer get currentPrayer {
    final p = times.currentPrayer();
    return p == Prayer.none ? Prayer.isha : p;
  }

  /// The upcoming [Prayer]. Wraps to tomorrow's Fajr after Isha.
  Prayer get nextPrayer {
    final p = times.nextPrayer();
    return p == Prayer.none ? Prayer.fajr : p;
  }

  /// The [PrayerEntry] for the next upcoming prayer.
  PrayerEntry get nextEntry {
    final next = nextPrayer;
    return entries.firstWhere(
      (e) => e.prayer == next,
      orElse: () => entries.first,
    );
  }

  /// DateTime of the next prayer. If the next prayer is tomorrow's Fajr
  /// (i.e. we are past Isha), returns tomorrow's Fajr time.
  DateTime get nextPrayerTime {
    final next = nextPrayer;
    final t = times.timeForPrayer(next);
    if (t == null) {
      // Past Isha — next is tomorrow's Fajr.
      final fajr = times.fajr;
      return fajr.add(const Duration(days: 1));
    }
    // If the computed time is already in the past (past Isha → Fajr wrap),
    // roll it forward a day so the countdown stays positive.
    if (t.isBefore(DateTime.now())) {
      return t.add(const Duration(days: 1));
    }
    return t;
  }
}

/// Resolves the location + settings and computes today's prayer schedule.
///
/// Uses only the *saved* location — it never triggers a GPS permission prompt
/// on its own, so placing this on Home won't surprise a first-time user with a
/// location dialog. When no location is saved it throws
/// [PrayerLocationException]; the UI then offers an explicit "Enable" action
/// that calls [resolvePrayerLocation].
final prayerScheduleProvider =
    FutureProvider.autoDispose<PrayerScheduleData>((ref) async {
  final settings = await PrayerTimesService.loadSettings();

  final method = PrayerCalculationMethod.values.firstWhere(
    (m) => m.name == settings['method'],
    orElse: () => PrayerCalculationMethod.muslimWorldLeague,
  );

  final double? lat = settings['lat'] as double?;
  final double? lng = settings['lng'] as double?;
  final String city = settings['city'] as String? ?? '';

  // No saved location — prompt the user via the UI rather than silently
  // requesting GPS here.
  if (lat == null || lng == null) {
    throw const PrayerLocationException();
  }

  final times = PrayerTimesService.calculateForToday(
    latitude: lat,
    longitude: lng,
    method: method,
  );
  if (times == null) {
    throw const PrayerCalculationException();
  }

  final entries = PrayerTimesService.buildEntries(times, settings);
  final label = city.isNotEmpty
      ? city
      : PrayerTimesService.coordinatesLabel(lat, lng);

  return PrayerScheduleData(
    entries: entries,
    times: times,
    method: method,
    locationLabel: label,
    latitude: lat,
    longitude: lng,
  );
});

/// Explicitly requests GPS (prompting for permission if needed) and persists
/// the resolved location so [prayerScheduleProvider] can compute times.
///
/// Returns `true` on success. Call this only in response to a direct user
/// action (e.g. tapping "Enable" on the prayer screen), then invalidate
/// [prayerScheduleProvider] to refresh.
Future<bool> resolvePrayerLocation() async {
  final position = await PrayerTimesService.getCurrentPosition();
  if (position == null) return false;

  final settings = await PrayerTimesService.loadSettings();
  final method = PrayerCalculationMethod.values.firstWhere(
    (m) => m.name == settings['method'],
    orElse: () => PrayerCalculationMethod.muslimWorldLeague,
  );

  await PrayerTimesService.saveSettings(
    enabled: settings['enabled'] as bool? ?? false,
    method: method,
    prayerToggles: {
      Prayer.fajr: settings['notify_fajr'] as bool? ?? true,
      Prayer.dhuhr: settings['notify_dhuhr'] as bool? ?? true,
      Prayer.asr: settings['notify_asr'] as bool? ?? true,
      Prayer.maghrib: settings['notify_maghrib'] as bool? ?? true,
      Prayer.isha: settings['notify_isha'] as bool? ?? true,
    },
    lat: position.latitude,
    lng: position.longitude,
    city: PrayerTimesService.coordinatesLabel(
        position.latitude, position.longitude),
  );
  return true;
}

/// Thrown when the device location cannot be determined (permission denied
/// or location services off).
class PrayerLocationException implements Exception {
  const PrayerLocationException();
  @override
  String toString() => 'Location unavailable';
}

/// Thrown when prayer times cannot be computed for the resolved location.
class PrayerCalculationException implements Exception {
  const PrayerCalculationException();
  @override
  String toString() => 'Could not calculate prayer times';
}

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';
import 'package:ehsan_pathways/core/json_read.dart';

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

  /// Asr by the Hanafi school.
  final bool hanafi;

  const PrayerScheduleData({
    this.hanafi = false,
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
final prayerScheduleProvider = FutureProvider.autoDispose<PrayerScheduleData>((
  ref,
) async {
  final settings = await PrayerTimesService.loadSettings();

  final method = PrayerCalculationMethod.values.firstWhere(
    (m) => m.name == settings['method'],
    orElse: () => PrayerCalculationMethod.muslimWorldLeague,
  );

  final double? lat = jDouble(settings['lat']);
  final double? lng = jDouble(settings['lng']);
  final String city = jStr(settings['city']) ?? '';

  // No saved location — prompt the user via the UI rather than silently
  // requesting GPS here.
  if (lat == null || lng == null) {
    throw const PrayerLocationException();
  }

  final times = PrayerTimesService.calculateForToday(
    latitude: lat,
    longitude: lng,
    method: method,
    hanafi: settings['madhab'] == 'hanafi',
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
    hanafi: settings['madhab'] == 'hanafi',
  );
});

/// Outcome of asking for the device location.
enum LocationResult { ok, servicesOff, denied, deniedForever, failed }

/// Explicitly requests GPS (prompting for permission if needed) and persists
/// the resolved location so [prayerScheduleProvider] can compute times.
///
/// Call this only in response to a direct user action (e.g. tapping "Use my
/// location"), then invalidate [prayerScheduleProvider]. Never throws and
/// never waits more than 20 seconds.
Future<LocationResult> resolvePrayerLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationResult.servicesOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationResult.deniedForever;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return LocationResult.denied;
    }

    final position = await PrayerTimesService.getCurrentPosition().timeout(
      const Duration(seconds: 20),
    );
    if (position == null) return LocationResult.failed;

    await PrayerTimesService.saveLocation(
      lat: position.latitude,
      lng: position.longitude,
      city: PrayerTimesService.coordinatesLabel(
        position.latitude,
        position.longitude,
      ),
    );
    return LocationResult.ok;
  } catch (e) {
    debugPrint('Location lookup failed: $e');
    return LocationResult.failed;
  }
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

import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Calculation methods available to users.
enum PrayerCalculationMethod {
  muslimWorldLeague('Muslim World League', 'Global'),
  northAmerica('ISNA - North America', 'North America'),
  egyptian('Egyptian Authority', 'Egypt & Africa'),
  ummAlQura('Umm Al-Qura', 'Saudi Arabia / Makkah'),
  karachi('University of Karachi', 'Pakistan & South Asia'),
  kuwait('Kuwait', 'Kuwait'),
  qatar('Qatar', 'Qatar'),
  singapore('Singapore', 'Singapore'),
  turkey('Turkey', 'Turkey'),
  tehran('Tehran', 'Iran');

  final String displayName;
  final String region;
  const PrayerCalculationMethod(this.displayName, this.region);
}

extension PrayerCalculationMethodExt on PrayerCalculationMethod {
  CalculationParameters get params {
    switch (this) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return CalculationMethod.muslim_world_league.getParameters();
      case PrayerCalculationMethod.northAmerica:
        return CalculationMethod.north_america.getParameters();
      case PrayerCalculationMethod.egyptian:
        return CalculationMethod.egyptian.getParameters();
      case PrayerCalculationMethod.ummAlQura:
        return CalculationMethod.umm_al_qura.getParameters();
      case PrayerCalculationMethod.karachi:
        return CalculationMethod.karachi.getParameters();
      case PrayerCalculationMethod.kuwait:
        return CalculationMethod.kuwait.getParameters();
      case PrayerCalculationMethod.qatar:
        return CalculationMethod.qatar.getParameters();
      case PrayerCalculationMethod.singapore:
        return CalculationMethod.singapore.getParameters();
      case PrayerCalculationMethod.turkey:
        return CalculationMethod.turkey.getParameters();
      case PrayerCalculationMethod.tehran:
        return CalculationMethod.tehran.getParameters();
    }
  }
}

/// Represents a single prayer with its name, time, and notification toggle.
class PrayerEntry {
  final Prayer prayer;
  final String name;
  final String arabicName;
  final DateTime? time;
  final bool notifyEnabled;

  const PrayerEntry({
    required this.prayer,
    required this.name,
    required this.arabicName,
    required this.time,
    required this.notifyEnabled,
  });

  PrayerEntry copyWith({DateTime? time, bool? notifyEnabled}) {
    return PrayerEntry(
      prayer: prayer,
      name: name,
      arabicName: arabicName,
      time: time ?? this.time,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    );
  }
}

/// Service that calculates Islamic prayer times based on GPS location.
/// Uses the [adhan] package — the standard Islamic prayer time library.
class PrayerTimesService {
  static const _keyMethod = 'prayer_method';
  static const _keyLat = 'prayer_lat';
  static const _keyLng = 'prayer_lng';
  static const _keyCity = 'prayer_city';
  static const _keyFajr = 'notify_fajr';
  static const _keyDhuhr = 'notify_dhuhr';
  static const _keyAsr = 'notify_asr';
  static const _keyMaghrib = 'notify_maghrib';
  static const _keyIsha = 'notify_isha';
  static const _keyJumah = 'notify_jumah';
  static const _keyEnabled = 'prayer_notify_enabled';

  /// Load saved settings
  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'method': prefs.getString(_keyMethod) ?? PrayerCalculationMethod.muslimWorldLeague.name,
      'lat': prefs.getDouble(_keyLat),
      'lng': prefs.getDouble(_keyLng),
      'city': prefs.getString(_keyCity) ?? '',
      'enabled': prefs.getBool(_keyEnabled) ?? false,
      'notify_fajr': prefs.getBool(_keyFajr) ?? true,
      'notify_dhuhr': prefs.getBool(_keyDhuhr) ?? true,
      'notify_asr': prefs.getBool(_keyAsr) ?? true,
      'notify_maghrib': prefs.getBool(_keyMaghrib) ?? true,
      'notify_isha': prefs.getBool(_keyIsha) ?? true,
      'notify_jumah': prefs.getBool(_keyJumah) ?? true,
    };
  }

  /// Save settings
  static Future<void> saveSettings({
    required bool enabled,
    required PrayerCalculationMethod method,
    required Map<Prayer, bool> prayerToggles,
    double? lat,
    double? lng,
    String? city,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setString(_keyMethod, method.name);
    if (lat != null) await prefs.setDouble(_keyLat, lat);
    if (lng != null) await prefs.setDouble(_keyLng, lng);
    if (city != null) await prefs.setString(_keyCity, city);
    await prefs.setBool(_keyFajr, prayerToggles[Prayer.fajr] ?? true);
    await prefs.setBool(_keyDhuhr, prayerToggles[Prayer.dhuhr] ?? true);
    await prefs.setBool(_keyAsr, prayerToggles[Prayer.asr] ?? true);
    await prefs.setBool(_keyMaghrib, prayerToggles[Prayer.maghrib] ?? true);
    await prefs.setBool(_keyIsha, prayerToggles[Prayer.isha] ?? true);
    await prefs.setBool(_keyJumah, prayerToggles[Prayer.dhuhr] ?? true);
  }

  /// Request location permission and get current GPS position.
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  /// Calculate today's prayer times for given coordinates.
  static PrayerTimes? calculateForToday({
    required double latitude,
    required double longitude,
    required PrayerCalculationMethod method,
  }) {
    try {
      final coordinates = Coordinates(latitude, longitude);
      final dateComponents = DateComponents.from(DateTime.now());
      return PrayerTimes(coordinates, dateComponents, method.params);
    } catch (_) {
      return null;
    }
  }

  /// Build a list of [PrayerEntry] from prayer times + saved toggles.
  static List<PrayerEntry> buildEntries(
    PrayerTimes times,
    Map<String, dynamic> settings,
  ) {
    return [
      PrayerEntry(
        prayer: Prayer.fajr,
        name: 'Fajr',
        arabicName: 'الفجر',
        time: times.fajr,
        notifyEnabled: settings['notify_fajr'] as bool? ?? true,
      ),
      PrayerEntry(
        prayer: Prayer.sunrise,
        name: 'Sunrise',
        arabicName: 'الشروق',
        time: times.sunrise,
        notifyEnabled: false, // sunrise is optional / info only
      ),
      PrayerEntry(
        prayer: Prayer.dhuhr,
        name: 'Dhuhr',
        arabicName: 'الظهر',
        time: times.dhuhr,
        notifyEnabled: settings['notify_dhuhr'] as bool? ?? true,
      ),
      PrayerEntry(
        prayer: Prayer.asr,
        name: 'Asr',
        arabicName: 'العصر',
        time: times.asr,
        notifyEnabled: settings['notify_asr'] as bool? ?? true,
      ),
      PrayerEntry(
        prayer: Prayer.maghrib,
        name: 'Maghrib',
        arabicName: 'المغرب',
        time: times.maghrib,
        notifyEnabled: settings['notify_maghrib'] as bool? ?? true,
      ),
      PrayerEntry(
        prayer: Prayer.isha,
        name: 'Isha',
        arabicName: 'العشاء',
        time: times.isha,
        notifyEnabled: settings['notify_isha'] as bool? ?? true,
      ),
    ];
  }

  /// Return a friendly time string (e.g. "5:23 AM")
  static String formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Returns the [Prayer] that is currently active (or the next upcoming one).
  static Prayer currentOrNextPrayer(PrayerTimes times) {
    return times.currentPrayer();
  }

  /// Approximate city name from coordinates using reverse geocoding logic.
  /// (Offline approximation — city name is saved from GPS result.)
  static String coordinatesLabel(double lat, double lng) {
    return '${lat.toStringAsFixed(2)}°${lat >= 0 ? "N" : "S"}, '
        '${lng.toStringAsFixed(2)}°${lng >= 0 ? "E" : "W"}';
  }
}

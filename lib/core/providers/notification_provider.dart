import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/core/services/notification_service.dart';
import 'package:ehsan_pathways/core/services/prayer_times_service.dart';

enum NotificationLoadStatus { initial, loading, loaded, error }

class NotificationSettings {
  final bool prayerTimesEnabled;
  final bool learningReminderEnabled;
  final TimeOfDay learningReminderTime;
  final bool jumahReminderEnabled;
  final bool newContentEnabled;
  final PrayerCalculationMethod calculationMethod;
  final Map<Prayer, bool> prayerToggles;
  final double? latitude;
  final double? longitude;
  final String locationLabel;
  final NotificationLoadStatus status;
  final String? error;
  final List<PrayerEntry> todayPrayers;

  const NotificationSettings({
    this.prayerTimesEnabled = false,
    this.learningReminderEnabled = false,
    this.learningReminderTime = const TimeOfDay(hour: 19, minute: 0),
    this.jumahReminderEnabled = true,
    this.newContentEnabled = true,
    this.calculationMethod = PrayerCalculationMethod.muslimWorldLeague,
    this.prayerToggles = const {
      Prayer.fajr: true,
      Prayer.dhuhr: true,
      Prayer.asr: true,
      Prayer.maghrib: true,
      Prayer.isha: true,
    },
    this.latitude,
    this.longitude,
    this.locationLabel = '',
    this.status = NotificationLoadStatus.initial,
    this.error,
    this.todayPrayers = const [],
  });

  bool get hasLocation => latitude != null && longitude != null;

  NotificationSettings copyWith({
    bool? prayerTimesEnabled,
    bool? learningReminderEnabled,
    TimeOfDay? learningReminderTime,
    bool? jumahReminderEnabled,
    bool? newContentEnabled,
    PrayerCalculationMethod? calculationMethod,
    Map<Prayer, bool>? prayerToggles,
    double? latitude,
    double? longitude,
    String? locationLabel,
    NotificationLoadStatus? status,
    String? error,
    List<PrayerEntry>? todayPrayers,
  }) {
    return NotificationSettings(
      prayerTimesEnabled: prayerTimesEnabled ?? this.prayerTimesEnabled,
      learningReminderEnabled:
          learningReminderEnabled ?? this.learningReminderEnabled,
      learningReminderTime: learningReminderTime ?? this.learningReminderTime,
      jumahReminderEnabled: jumahReminderEnabled ?? this.jumahReminderEnabled,
      newContentEnabled: newContentEnabled ?? this.newContentEnabled,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      prayerToggles: prayerToggles ?? this.prayerToggles,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      status: status ?? this.status,
      error: error,
      todayPrayers: todayPrayers ?? this.todayPrayers,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    _loadFromPrefs();
    return const NotificationSettings();
  }

  static const _keyLearningEnabled = 'learning_reminder_enabled';
  static const _keyLearningHour = 'learning_reminder_hour';
  static const _keyLearningMin = 'learning_reminder_min';
  static const _keyJumahEnabled = 'jumah_reminder_enabled';
  static const _keyContentEnabled = 'new_content_enabled';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final prayerSettings = await PrayerTimesService.loadSettings();

    final methodName = prayerSettings['method'] as String;
    final method = PrayerCalculationMethod.values.firstWhere(
      (m) => m.name == methodName,
      orElse: () => PrayerCalculationMethod.muslimWorldLeague,
    );

    final lat = prayerSettings['lat'] as double?;
    final lng = prayerSettings['lng'] as double?;
    final city = prayerSettings['city'] as String? ?? '';
    final prayerEnabled = prayerSettings['enabled'] as bool? ?? false;

    final prayerToggles = {
      Prayer.fajr: prayerSettings['notify_fajr'] as bool? ?? true,
      Prayer.dhuhr: prayerSettings['notify_dhuhr'] as bool? ?? true,
      Prayer.asr: prayerSettings['notify_asr'] as bool? ?? true,
      Prayer.maghrib: prayerSettings['notify_maghrib'] as bool? ?? true,
      Prayer.isha: prayerSettings['notify_isha'] as bool? ?? true,
    };

    final learningEnabled = prefs.getBool(_keyLearningEnabled) ?? false;
    final hour = prefs.getInt(_keyLearningHour) ?? 19;
    final min = prefs.getInt(_keyLearningMin) ?? 0;

    List<PrayerEntry> prayers = [];
    if (lat != null && lng != null) {
      final times = PrayerTimesService.calculateForToday(
        latitude: lat,
        longitude: lng,
        method: method,
      );
      if (times != null) {
        prayers = PrayerTimesService.buildEntries(times, prayerSettings);
      }
    }

    state = NotificationSettings(
      prayerTimesEnabled: prayerEnabled,
      learningReminderEnabled: learningEnabled,
      learningReminderTime: TimeOfDay(hour: hour, minute: min),
      jumahReminderEnabled: prefs.getBool(_keyJumahEnabled) ?? true,
      newContentEnabled: prefs.getBool(_keyContentEnabled) ?? true,
      calculationMethod: method,
      prayerToggles: prayerToggles,
      latitude: lat,
      longitude: lng,
      locationLabel: city.isNotEmpty
          ? city
          : (lat != null && lng != null
              ? PrayerTimesService.coordinatesLabel(lat, lng)
              : ''),
      status: NotificationLoadStatus.loaded,
      todayPrayers: prayers,
    );
  }

  /// Request location and refresh prayer times.
  Future<void> detectLocation() async {
    state = state.copyWith(status: NotificationLoadStatus.loading, error: null);
    try {
      final position = await PrayerTimesService.getCurrentPosition();
      if (position == null) {
        state = state.copyWith(
          status: NotificationLoadStatus.error,
          error: 'Location permission denied. Please enable location access in settings.',
        );
        return;
      }

      final label =
          PrayerTimesService.coordinatesLabel(position.latitude, position.longitude);

      // Calculate today's prayers
      final times = PrayerTimesService.calculateForToday(
        latitude: position.latitude,
        longitude: position.longitude,
        method: state.calculationMethod,
      );

      final prayerSettings = await PrayerTimesService.loadSettings();
      final prayers = times != null
          ? PrayerTimesService.buildEntries(times, {
              ...prayerSettings,
              'notify_fajr': state.prayerToggles[Prayer.fajr] ?? true,
              'notify_dhuhr': state.prayerToggles[Prayer.dhuhr] ?? true,
              'notify_asr': state.prayerToggles[Prayer.asr] ?? true,
              'notify_maghrib': state.prayerToggles[Prayer.maghrib] ?? true,
              'notify_isha': state.prayerToggles[Prayer.isha] ?? true,
            })
          : <PrayerEntry>[];

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        locationLabel: label,
        status: NotificationLoadStatus.loaded,
        todayPrayers: prayers,
      );

      await _saveAndReschedule();
    } catch (e) {
      state = state.copyWith(
        status: NotificationLoadStatus.error,
        error: 'Could not get location: $e',
      );
    }
  }

  Future<void> togglePrayerTimes(bool enabled) async {
    state = state.copyWith(prayerTimesEnabled: enabled);
    if (enabled && !state.hasLocation) {
      await detectLocation();
    } else {
      await _saveAndReschedule();
    }
  }

  Future<void> togglePrayer(Prayer prayer, bool enabled) async {
    final updated = Map<Prayer, bool>.from(state.prayerToggles);
    updated[prayer] = enabled;
    state = state.copyWith(prayerToggles: updated);
    await _saveAndReschedule();
  }

  Future<void> setCalculationMethod(PrayerCalculationMethod method) async {
    state = state.copyWith(calculationMethod: method);
    await _saveAndReschedule();
  }

  Future<void> toggleLearningReminder(bool enabled) async {
    state = state.copyWith(learningReminderEnabled: enabled);
    await _saveLearningPrefs();
    await NotificationService.instance.scheduleDailyLearningReminder(
      time: state.learningReminderTime,
      enabled: enabled,
    );
  }

  Future<void> setLearningReminderTime(TimeOfDay time) async {
    state = state.copyWith(learningReminderTime: time);
    await _saveLearningPrefs();
    if (state.learningReminderEnabled) {
      await NotificationService.instance.scheduleDailyLearningReminder(
        time: time,
        enabled: true,
      );
    }
  }

  Future<void> toggleJumahReminder(bool enabled) async {
    state = state.copyWith(jumahReminderEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyJumahEnabled, enabled);
    await NotificationService.instance.scheduleJumahReminder(enabled: enabled);
  }

  Future<void> toggleNewContent(bool enabled) async {
    state = state.copyWith(newContentEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyContentEnabled, enabled);
  }

  Future<void> _saveAndReschedule() async {
    await PrayerTimesService.saveSettings(
      enabled: state.prayerTimesEnabled,
      method: state.calculationMethod,
      prayerToggles: state.prayerToggles,
      lat: state.latitude,
      lng: state.longitude,
      city: state.locationLabel,
    );

    if (state.prayerTimesEnabled && state.hasLocation) {
      await NotificationService.instance.schedulePrayerNotifications(
        latitude: state.latitude!,
        longitude: state.longitude!,
        method: state.calculationMethod,
        enabledPrayers: state.prayerToggles,
      );
    } else {
      await NotificationService.instance.cancelPrayerNotifications();
    }
  }

  Future<void> _saveLearningPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLearningEnabled, state.learningReminderEnabled);
    await prefs.setInt(_keyLearningHour, state.learningReminderTime.hour);
    await prefs.setInt(_keyLearningMin, state.learningReminderTime.minute);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationSettings>(
  NotificationNotifier.new,
);

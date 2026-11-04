import 'package:flutter_test/flutter_test.dart';

import 'package:ehsan_pathways/core/services/prayer_times_service.dart';
import 'package:ehsan_pathways/features/prayer/prayer_cities.dart';

void main() {
  test('Hanafi Asr is later than the standard Asr', () {
    final date = DateTime(2026, 11, 4);
    for (final city in [kPrayerCities.first, kPrayerCities.last]) {
      final standard = PrayerTimesService.calculateForToday(
        latitude: city.lat,
        longitude: city.lng,
        method: city.method,
        date: date,
      )!;
      final hanafi = PrayerTimesService.calculateForToday(
        latitude: city.lat,
        longitude: city.lng,
        method: city.method,
        hanafi: true,
        date: date,
      )!;
      expect(hanafi.asr.isAfter(standard.asr), isTrue, reason: city.label);
      expect(hanafi.dhuhr, standard.dhuhr, reason: 'only Asr changes');
    }
  });

  test('every city has valid, unique coordinates and computes all prayers', () {
    final labels = <String>{};
    for (final c in kPrayerCities) {
      expect(c.lat, inInclusiveRange(-90, 90), reason: c.label);
      expect(c.lng, inInclusiveRange(-180, 180), reason: c.label);
      expect(labels.add(c.label), isTrue, reason: 'duplicate ${c.label}');

      final t = PrayerTimesService.calculateForToday(
        latitude: c.lat,
        longitude: c.lng,
        method: c.method,
        date: DateTime(2026, 6, 21), // longest day: hardest for high latitudes
      );
      expect(t, isNotNull, reason: c.label);
      expect(t!.fajr.isBefore(t.sunrise), isTrue, reason: c.label);
      expect(t.dhuhr.isBefore(t.asr), isTrue, reason: c.label);
      expect(t.maghrib.isBefore(t.isha), isTrue, reason: c.label);
    }
  });
}

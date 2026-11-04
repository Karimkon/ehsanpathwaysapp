import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:ehsan_pathways/features/islamic_tools/calendar/hijri_calendar_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/names/asma_ul_husna_data.dart';

void main() {
  test("Asma'ul Husna has 99 distinct, ordered names", () {
    expect(kAsmaUlHusna, hasLength(99));
    expect([for (final n in kAsmaUlHusna) n.number], List.generate(99, (i) => i + 1));
    expect({for (final n in kAsmaUlHusna) n.arabic}, hasLength(99));
    expect(kAsmaUlHusna.first.transliteration, 'Ar-Rahman');
    expect(kAsmaUlHusna.last.transliteration, 'As-Sabur');
  });

  group('Hijri observances', () {
    test('marks the agreed sacred days', () {
      expect(hijriObservance(12, 9), contains('Arafah'));
      expect(hijriObservance(12, 10), 'Eid al-Adha');
      expect(hijriObservance(10, 1), 'Eid al-Fitr');
      expect(hijriObservance(1, 10), contains('Ashura'));
      expect(hijriObservance(9, 27), contains('last ten nights'));
    });

    test('white days, except the 13th of Dhul-Hijjah (Tashreeq)', () {
      expect(hijriObservance(3, 13), contains('White Days'));
      expect(hijriObservance(3, 15), contains('White Days'));
      expect(hijriObservance(12, 13), 'Days of Tashreeq');
      expect(hijriObservance(12, 14), contains('White Days'));
    });

    test('ordinary days are unmarked', () {
      expect(hijriObservance(3, 5), isNull);
      expect(hijriObservance(7, 27), isNull);
    });
  });

  test('Umm al-Qura conversion: 1 Ramadan 1447 is 18 February 2026', () {
    final g = HijriCalendar().hijriToGregorian(1447, 9, 1);
    expect([g.year, g.month, g.day], [2026, 2, 18]);
  });
}

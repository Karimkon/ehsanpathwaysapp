import 'package:flutter_test/flutter_test.dart';

import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_data.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_text.dart';

void main() {
  // Verse 2:1 as alquran.cloud serves it in the Uthmani and simple editions.
  const baqarah1Uthmani = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الٓمٓ';
  const baqarah1Simple = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الم';
  const fatiha1 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
  const tawbah1 = 'بَرَآءَةٌ مِّنَ ٱللَّهِ وَرَسُولِهِۦٓ';

  group('basmalah header', () {
    test('every surah except Al-Fatihah and At-Tawbah gets one', () {
      expect(showsBasmalahHeader(1), isFalse);
      expect(showsBasmalahHeader(9), isFalse);
      for (final n in [2, 8, 10, 27, 114]) {
        expect(showsBasmalahHeader(n), isTrue, reason: 'surah $n');
      }
    });
  });

  group('stripLeadingBasmalah', () {
    test('removes it from verse 1 in Uthmani script', () {
      expect(stripLeadingBasmalah(baqarah1Uthmani, 2), 'الٓمٓ');
    });

    test('removes it from verse 1 in simple script', () {
      expect(stripLeadingBasmalah(baqarah1Simple, 2), 'الم');
    });

    test('tolerates a leading byte-order mark', () {
      expect(stripLeadingBasmalah('﻿$baqarah1Uthmani', 2), 'الٓمٓ');
    });

    test('keeps Al-Fatihah verse 1, which is the basmalah', () {
      expect(stripLeadingBasmalah(fatiha1, 1), fatiha1);
    });

    test('leaves At-Tawbah untouched', () {
      expect(stripLeadingBasmalah(tawbah1, 9), tawbah1);
    });

    test('leaves verses that do not start with it untouched', () {
      expect(stripLeadingBasmalah('الٓمٓ', 2), 'الٓمٓ');
    });

    test('keeps the basmalah inside An-Naml 27:30', () {
      const naml30 =
          'إِنَّهُۥ مِن سُلَيْمَٰنَ وَإِنَّهُۥ بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
      expect(stripLeadingBasmalah(naml30, 27), naml30);
    });
  });

  test('toArabicDigits', () {
    expect(toArabicDigits(7), '٧');
    expect(toArabicDigits(286), '٢٨٦');
  });

  group('bundled surah index', () {
    test('has all 114 surahs and 6,236 verses', () {
      expect(kSurahs, hasLength(114));
      expect(kSurahs.fold<int>(0, (a, s) => a + s.verses), 6236);
      expect([for (final s in kSurahs) s.no], List.generate(114, (i) => i + 1));
    });
  });

  group('parseQuranEditions', () {
    Map<String, dynamic> response(List<String> arabic, List<String> english,
            {int firstGlobal = 8}) =>
        {
          'data': [
            {
              'ayahs': [
                for (var i = 0; i < arabic.length; i++)
                  {'number': firstGlobal + i, 'numberInSurah': i + 1, 'text': arabic[i]},
              ],
            },
            {
              'ayahs': [
                for (var i = 0; i < english.length; i++)
                  {'number': firstGlobal + i, 'numberInSurah': i + 1, 'text': english[i]},
              ],
            },
          ],
        };

    test('pairs Arabic with translation and strips the basmalah', () {
      final verses = parseQuranEditions(
        response([baqarah1Uthmani, 'ذَٰلِكَ ٱلْكِتَٰبُ'], ['Alif, Lam, Meem.', 'This is the Book']),
        2,
      );
      expect(verses, hasLength(2));
      expect(verses[0].arabic, 'الٓمٓ');
      expect(verses[0].translation, 'Alif, Lam, Meem.');
      expect(verses[0].globalNumber, 8);
      expect(verses[1].number, 2);
      expect(verses[1].globalNumber, 9);
    });

    test('rejects mismatched editions', () {
      expect(
        () => parseQuranEditions(response(['a', 'b'], ['x']), 2),
        throwsFormatException,
      );
    });

    test('verses round-trip through the offline cache format', () {
      const v = QuranVerse(number: 3, globalNumber: 10, arabic: 'ع', translation: 'e');
      final back = QuranVerse.fromJson(v.toJson());
      expect(back.number, 3);
      expect(back.globalNumber, 10);
      expect(back.arabic, 'ع');
      expect(back.translation, 'e');
    });
  });
}

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

  // The app used to fetch two editions from alquran.cloud and stitch them
  // together by index. It now makes one request to OUR backend, which joins
  // the translation server-side.
  group('parseQuranChapter', () {
    Map<String, dynamic> response(
      List<List<String>> rows, {
      int firstGlobal = 8,
      int surahNo = 2,
    }) => {
      'data': {
        'chapter': {'id': surahNo},
        'verses': [
          for (var i = 0; i < rows.length; i++)
            {
              'id': firstGlobal + i,
              'verse_key': '$surahNo:${i + 1}',
              'verse_number': i + 1,
              'text_uthmani': rows[i][0],
              'translation': rows[i][1],
            },
        ],
      },
    };

    test('reads the Arabic, the translation and the verse key', () {
      final verses = parseQuranChapter(
        response([
          [baqarah1Uthmani, 'Alif, Lam, Meem.'],
          ['ذَٰلِكَ ٱلْكِتَٰبُ', 'This is the Book'],
        ]),
        2,
      );

      expect(verses, hasLength(2));
      expect(verses[0].arabic, 'الٓمٓ');
      expect(verses[0].translation, 'Alif, Lam, Meem.');
      expect(verses[0].verseKey, '2:1');
      // Our ids ARE the mushaf numbers, which the recitation CDN needs.
      expect(verses[0].globalNumber, 8);
      expect(verses[1].number, 2);
      expect(verses[1].verseKey, '2:2');
      expect(verses[1].globalNumber, 9);
    });

    // Quran Foundation does not prefix verse 1 with the basmalah, but the
    // strip stays in place to guard against an edition that does. It must be
    // a no-op on text that does not start with one.
    test('leaves verse 1 alone when it carries no basmalah', () {
      final verses = parseQuranChapter(
        response([
          ['الٓمٓ', 'Alif, Lam, Meem.'],
        ]),
        2,
      );

      expect(verses[0].arabic, 'الٓمٓ');
    });

    // Al-Fatihah's verse 1 IS the basmalah and must survive intact.
    test('keeps the basmalah as verse 1 of Al-Fatihah', () {
      final verses = parseQuranChapter(
        response([
          [kBasmalah, 'In the name of Allah'],
        ], surahNo: 1),
        1,
      );

      expect(verses[0].arabic, kBasmalah);
    });

    test('a missing translation is empty rather than fatal', () {
      final body = {
        'data': {
          'verses': [
            {
              'id': 1,
              'verse_key': '1:1',
              'verse_number': 1,
              'text_uthmani': 'ع',
              'translation': null,
            },
          ],
        },
      };

      final verses = parseQuranChapter(body, 1);

      expect(verses, hasLength(1));
      expect(verses[0].translation, '');
    });

    test('verses round-trip through the offline cache format', () {
      const v = QuranVerse(
        number: 3,
        globalNumber: 10,
        arabic: 'ع',
        translation: 'e',
        verseKey: '1:3',
      );

      final back = QuranVerse.fromJson(v.toJson());

      expect(back.number, 3);
      expect(back.globalNumber, 10);
      expect(back.arabic, 'ع');
      expect(back.translation, 'e');
      // Without this the tafsir sheet has nothing to ask for.
      expect(back.verseKey, '1:3');
    });
  });

  group('VerseTafsir', () {
    test('reads the edition name and the range it covers', () {
      final tafsir = VerseTafsir.fromJson({
        'verse_key': '2:1',
        'resource': {'name': 'Tafsir Ibn Kathir', 'author': 'Ibn Kathir'},
        'text': '<p>These opening verses...</p>',
        'range': 'Verses 1-5',
      });

      expect(tafsir.verseKey, '2:1');
      expect(tafsir.resourceName, 'Tafsir Ibn Kathir');
      expect(tafsir.authorName, 'Ibn Kathir');
      expect(tafsir.range, 'Verses 1-5');
    });

    test('a single-verse passage has no range to show', () {
      final tafsir = VerseTafsir.fromJson({
        'verse_key': '1:1',
        'resource': {'name': 'Tafsir Ibn Kathir'},
        'text': 'The opening of the Book',
      });

      expect(tafsir.range, isNull);
      expect(tafsir.authorName, isNull);
    });

    test('round-trips through the offline cache format', () {
      const t = VerseTafsir(
        verseKey: '2:255',
        resourceName: 'Tafsir Ibn Kathir',
        authorName: 'Ibn Kathir',
        text: 'Ayat al-Kursi',
        range: 'Verses 255-257',
      );

      final back = VerseTafsir.fromJson(t.toJson());

      expect(back.verseKey, '2:255');
      expect(back.resourceName, 'Tafsir Ibn Kathir');
      expect(back.authorName, 'Ibn Kathir');
      expect(back.text, 'Ayat al-Kursi');
      expect(back.range, 'Verses 255-257');
    });
  });
}

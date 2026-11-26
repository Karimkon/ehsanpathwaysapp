import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ehsan_pathways/features/islamic_tools/quran/quran_data.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_offline_text.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_text.dart';

/// Guards the bundled Qur'an asset.
///
/// The whole point of the asset is that a user with no connection can read
/// every surah. A truncated or mis-generated file would fail silently at
/// runtime - the reader would just fall back to the network and the offline
/// promise would quietly stop being true - so it is asserted here instead.
void main() {
  late List<List<dynamic>> surahs;
  late String source;

  setUpAll(() {
    final file = File('assets/quran/quran.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'assets/quran/quran.json is missing. '
          'Regenerate it with: python tool/build_quran_asset.py',
    );
    source = file.readAsStringSync();
    surahs = parseBundledQuran(source);
  });

  test('contains all 114 surahs and 6,236 verses', () {
    expect(surahs.length, 114);
    final total = surahs.fold<int>(0, (sum, s) => sum + s.length);
    expect(total, 6236);
  });

  test('every surah has the verse count the bundled index claims', () {
    // kSurahs is generated from the backend and drives the surah list screen.
    // If the two ever disagree, the reader shows a different number of verses
    // than the index promised.
    for (final surah in kSurahs) {
      expect(
        surahs[surah.no - 1].length,
        surah.verses,
        reason: 'surah ${surah.no} (${surah.name}): index says '
            '${surah.verses} verses, asset has ${surahs[surah.no - 1].length}',
      );
    }
  });

  test('global verse numbers run 1..6236 without a gap', () {
    var expected = 0;
    for (final surah in surahs) {
      for (final verse in surah) {
        expected++;
        expect(verse.globalNumber, expected);
      }
    }
    expect(expected, 6236);
  });

  test('verse numbers restart at 1 in every surah', () {
    for (var i = 0; i < surahs.length; i++) {
      expect(surahs[i].first.number, 1, reason: 'surah ${i + 1}');
      expect(surahs[i].last.number, surahs[i].length, reason: 'surah ${i + 1}');
    }
  });

  test('the basmalah is stripped from verse 1 where it is a header', () {
    // Al-Baqarah: the edition prefixes verse 1, and the reader draws the
    // basmalah itself, so the text must not start with it or it appears twice.
    final baqarahFirst = surahs[1].first.arabic;
    expect(
      normalizeArabic(baqarahFirst).startsWith(normalizeArabic(kBasmalah)),
      isFalse,
      reason: 'Al-Baqarah 1 still carries the basmalah: $baqarahFirst',
    );
    expect(normalizeArabic(baqarahFirst).startsWith('الم'), isTrue);
  });

  test('Al-Fatihah keeps the basmalah, because there it IS verse 1', () {
    expect(showsBasmalahHeader(1), isFalse);
    expect(
      normalizeArabic(surahs[0].first.arabic),
      normalizeArabic(kBasmalah),
    );
  });

  test('At-Tawbah is untouched, having no basmalah at all', () {
    expect(showsBasmalahHeader(9), isFalse);
    expect(surahs[8].first.arabic.trim(), isNotEmpty);
    expect(
      normalizeArabic(surahs[8].first.arabic)
          .startsWith(normalizeArabic(kBasmalah)),
      isFalse,
    );
  });

  test('no verse is empty and no translation is missing', () {
    for (var s = 0; s < surahs.length; s++) {
      for (final verse in surahs[s]) {
        expect(
          verse.arabic.trim(),
          isNotEmpty,
          reason: 'surah ${s + 1} verse ${verse.number} has no Arabic',
        );
        expect(
          verse.translation.trim(),
          isNotEmpty,
          reason: 'surah ${s + 1} verse ${verse.number} has no translation',
        );
      }
    }
  });

  test('rejects a malformed asset rather than serving a partial Qur\'an', () {
    expect(
      () => parseBundledQuran('{"v":1,"s":[]}'),
      throwsA(isA<FormatException>()),
    );
    // A file that is the right shape but short a surah must also fail.
    expect(
      () => parseBundledQuran('{"v":1,"s":[[["a","b"]]]}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('the asset is declared in pubspec.yaml', () {
    // Bundling the file is not enough; Flutter only ships assets listed here.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec.contains('assets/quran/quran.json'),
      isTrue,
      reason: 'assets/quran/quran.json is not listed under flutter: assets:, '
          'so it will not be packaged and offline reading will break',
    );
  });
}

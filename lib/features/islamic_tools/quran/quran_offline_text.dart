/// The complete Qur'an, bundled with the app.
///
/// Before this existed, a surah was readable offline only if the user had
/// already opened it once with a connection (see `OfflineCache` in
/// islamic_tools_provider.dart). Someone who installed the app on a handset
/// with no data could not read anything at all, while the reader told them to
/// "connect to the internet once".
///
/// The text is fixed and small - 6,236 verses, 2.16 MB of JSON, deflated to
/// roughly 0.6 MB inside the APK - so it ships with the app instead. The
/// network path is kept only as a fallback for the impossible case of the
/// asset being missing.
///
/// Regenerate the asset with `python tool/build_quran_asset.py`.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_text.dart';

const String kQuranAssetPath = 'assets/quran/quran.json';

/// Parses the bundled asset into per-surah verse lists.
///
/// Top-level and pure so it can run through [compute] on a background
/// isolate: 2.16 MB of JSON would otherwise drop frames on a cheap handset.
List<List<QuranVerse>> parseBundledQuran(String source) {
  final doc = json.decode(source) as Map<String, dynamic>;
  final surahs = doc['s'] as List;
  if (surahs.length != 114) {
    throw FormatException('expected 114 surahs, got ${surahs.length}');
  }

  final out = <List<QuranVerse>>[];
  var global = 0;
  for (var s = 0; s < surahs.length; s++) {
    final surahNo = s + 1;
    final ayahs = surahs[s] as List;
    final verses = <QuranVerse>[];
    for (var v = 0; v < ayahs.length; v++) {
      final pair = ayahs[v] as List;
      final number = v + 1;
      global++;
      final arabic = pair[0] as String;
      verses.add(
        QuranVerse(
          number: number,
          globalNumber: global,
          // Verse 1 carries the basmalah in this edition; the reader draws it
          // as a header, so strip it exactly as the network path does.
          arabic: number == 1 ? stripLeadingBasmalah(arabic, surahNo) : arabic,
          translation: pair[1] as String,
        ),
      );
    }
    out.add(verses);
  }

  if (global != 6236) {
    throw FormatException('expected 6236 verses, got $global');
  }
  return out;
}

class QuranOfflineText {
  QuranOfflineText._();

  static final QuranOfflineText instance = QuranOfflineText._();

  Future<List<List<QuranVerse>>>? _pending;

  /// Loads and parses the asset once, then serves every later call from
  /// memory. Concurrent callers share the one future rather than each
  /// decoding their own copy.
  Future<List<List<QuranVerse>>> _all() {
    return _pending ??= () async {
      try {
        final source = await rootBundle.loadString(kQuranAssetPath);
        return await compute(parseBundledQuran, source);
      } catch (e) {
        // Do not cache a failure: a later call should be able to retry.
        _pending = null;
        rethrow;
      }
    }();
  }

  /// Verses of [surahNo] (1-114). Throws if the asset is missing or corrupt,
  /// which lets the provider fall back to the network path.
  Future<List<QuranVerse>> versesFor(int surahNo) async {
    if (surahNo < 1 || surahNo > 114) {
      throw RangeError.range(surahNo, 1, 114, 'surahNo');
    }
    final all = await _all();
    return all[surahNo - 1];
  }

  /// Warms the cache so the first surah a user opens is instant. Safe to call
  /// and ignore; failures are swallowed because this is only an optimisation.
  Future<void> preload() async {
    try {
      await _all();
    } catch (_) {
      // The provider will surface a real error if the text is actually needed.
    }
  }

  @visibleForTesting
  void resetForTest() => _pending = null;
}

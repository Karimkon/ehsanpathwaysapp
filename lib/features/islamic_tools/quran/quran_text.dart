/// Text rules for the mushaf.
///
/// alquran.cloud prefixes verse 1 of every surah with the basmalah, except
/// Al-Fatihah (where the basmalah *is* verse 1) and At-Tawbah (which has
/// none). The reader shows the basmalah once, as a header, so it has to be
/// removed from verse 1 or it appears twice.
library;

/// The basmalah as it is displayed above a surah (Uthmani script).
const String kBasmalah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

/// Whether a surah opens with the basmalah as a separate header. Al-Fatihah
/// does not (it is verse 1) and At-Tawbah has none.
bool showsBasmalahHeader(int surahNo) => surahNo != 1 && surahNo != 9;

/// Strips diacritics, Qur'anic annotation marks and tatweel, and folds alef
/// variants, so two spellings of the same words compare equal.
String normalizeArabic(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final isMark =
        (rune >= 0x0610 && rune <= 0x061A) ||
        (rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 || // superscript alef
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        rune == 0x0640 || // tatweel
        rune == 0xFEFF; // BOM, present on some API responses
    if (isMark) continue;
    switch (rune) {
      case 0x0671: // alef wasla
      case 0x0622: // alef madda
      case 0x0623: // alef hamza above
      case 0x0625: // alef hamza below
        out.writeCharCode(0x0627);
      default:
        out.writeCharCode(rune);
    }
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

final String _basmalahNormalized = normalizeArabic(kBasmalah);

/// Removes a leading basmalah from verse 1 of [surahNo] when the reader shows
/// it as a header instead. Text that does not start with it is returned as
/// is, so this is safe whichever edition the API serves.
String stripLeadingBasmalah(String verseText, int surahNo) {
  if (!showsBasmalahHeader(surahNo)) return verseText;

  final words = verseText.trim().split(RegExp(r'\s+'));
  if (words.length < 4) return verseText;
  final firstFour = normalizeArabic(words.take(4).join(' '));
  if (firstFour != _basmalahNormalized) return verseText;

  return words.skip(4).join(' ').trim();
}

/// Arabic-Indic digits for verse markers: 12 → ١٢.
String toArabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();

import 'dart:async';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/core/services/auth_service.dart';

// ===========================================================================
// Reciters
// ===========================================================================

class Reciter {
  const Reciter(this.id, this.name, this.arabicName, this.bitrate);

  /// alquran.cloud audio edition identifier.
  final String id;
  final String name;
  final String arabicName;
  final int bitrate;

  /// Verse-by-verse recitation, addressed by the verse's mushaf-wide number.
  String urlFor(int globalVerse) =>
      'https://cdn.islamic.network/quran/audio/$bitrate/$id/$globalVerse.mp3';
}

const kReciters = <Reciter>[
  Reciter('ar.alafasy', 'Mishary Rashid Alafasy', 'مشاري العفاسي', 128),
  Reciter(
    'ar.abdurrahmaansudais',
    'Abdur-Rahman As-Sudais',
    'عبد الرحمن السديس',
    192,
  ),
  Reciter('ar.husary', 'Mahmoud Khalil Al-Husary', 'محمود خليل الحصري', 128),
  Reciter(
    'ar.minshawi',
    'Mohamed Siddiq Al-Minshawi',
    'محمد صديق المنشاوي',
    128,
  ),
  Reciter('ar.mahermuaiqly', 'Maher Al-Muaiqly', 'ماهر المعيقلي', 128),
];

Reciter reciterById(String? id) =>
    kReciters.firstWhere((r) => r.id == id, orElse: () => kReciters.first);

// ===========================================================================
// Reading preferences, bookmarks and position (all on device)
// ===========================================================================

class VerseRef {
  const VerseRef(this.surah, this.verse);
  final int surah;
  final int verse;

  String get key => '$surah:$verse';

  static VerseRef? parse(String? key) {
    final parts = key?.split(':');
    if (parts == null || parts.length != 2) return null;
    final s = int.tryParse(parts[0]), v = int.tryParse(parts[1]);
    return s == null || v == null ? null : VerseRef(s, v);
  }

  @override
  bool operator ==(Object other) =>
      other is VerseRef && other.surah == surah && other.verse == verse;

  @override
  int get hashCode => Object.hash(surah, verse);
}

@immutable
class QuranReadingState {
  const QuranReadingState({
    this.reciterId = 'ar.alafasy',
    this.arabicSize = 30,
    this.showTranslation = true,
    this.bookmarks = const <String>[],
    this.lastRead,
  });

  final String reciterId;
  final double arabicSize;
  final bool showTranslation;

  /// "surah:verse" keys, most recent first.
  final List<String> bookmarks;
  final VerseRef? lastRead;

  Reciter get reciter => reciterById(reciterId);
  bool isBookmarked(int surah, int verse) =>
      bookmarks.contains(VerseRef(surah, verse).key);

  QuranReadingState copyWith({
    String? reciterId,
    double? arabicSize,
    bool? showTranslation,
    List<String>? bookmarks,
    VerseRef? lastRead,
  }) => QuranReadingState(
    reciterId: reciterId ?? this.reciterId,
    arabicSize: arabicSize ?? this.arabicSize,
    showTranslation: showTranslation ?? this.showTranslation,
    bookmarks: bookmarks ?? this.bookmarks,
    lastRead: lastRead ?? this.lastRead,
  );

  Map<String, Object?> toJson() => {
    'reciter': reciterId,
    'size': arabicSize,
    'translation': showTranslation,
    'bookmarks': bookmarks,
    'last': lastRead?.key,
  };

  factory QuranReadingState.fromJson(Map<String, dynamic> j) =>
      QuranReadingState(
        reciterId: j['reciter'] as String? ?? 'ar.alafasy',
        arabicSize: ((j['size'] as num?) ?? 30).toDouble().clamp(20, 48),
        showTranslation: j['translation'] as bool? ?? true,
        bookmarks: (j['bookmarks'] as List?)?.cast<String>() ?? const [],
        lastRead: VerseRef.parse(j['last'] as String?),
      );
}

/// Reading preferences, bookmarks and reading position.
///
/// The device is authoritative for the UI: everything works signed out, on a
/// plane, with no account. When a reader IS signed in the same changes are
/// mirrored to our backend so their bookmarks and their place in the book
/// follow them to the web reader and survive a reinstall.
///
/// Sync is deliberately one-way-per-event and never blocking. A failed push
/// is swallowed: losing a bookmark sync is a nuisance, but an exception
/// thrown while someone is reading is worse, and the next toggle or the next
/// launch reconciles it.
class QuranReadingNotifier extends Notifier<QuranReadingState> {
  static const _key = 'quran_reading_v1';

  /// The reader scrolls constantly. Without this, every verse that passes
  /// mid-screen would be its own request.
  Timer? _positionDebounce;

  @override
  QuranReadingState build() {
    ref.onDispose(() => _positionDebounce?.cancel());
    Future.microtask(_load);
    return const QuranReadingState();
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) {
        state = QuranReadingState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Quran reading state could not be loaded: $e');
    }

    // Then reconcile with the server, if there is an account.
    await _pull();
  }

  // ── server sync ────────────────────────────────────────────────────

  Future<bool> _signedIn() async {
    try {
      return (await AuthService().getToken()) != null;
    } catch (_) {
      return false;
    }
  }

  /// Merge the server's record into the device's.
  ///
  /// Bookmarks are UNIONED rather than replaced. Either side may hold ones
  /// the other has not seen — saved on the web, or saved on the phone while
  /// offline — and replacing would silently discard them. An explicit
  /// removal still propagates, because that is sent the moment it happens.
  Future<void> _pull() async {
    if (!await _signedIn()) return;

    try {
      final dio = ref.read(apiProvider);

      final results = await Future.wait([
        dio.get('/quran/bookmarks'),
        dio.get('/quran/position'),
      ]);

      final remoteKeys = <String>[];
      final bookmarkBody = results[0].data;
      if (bookmarkBody is Map && bookmarkBody['data'] is List) {
        for (final row in bookmarkBody['data'] as List) {
          if (row is Map && row['verse_key'] is String) {
            remoteKeys.add(row['verse_key'] as String);
          }
        }
      }

      final merged = <String>[
        ...remoteKeys.where((k) => !state.bookmarks.contains(k)),
        ...state.bookmarks,
      ];

      // The server's position wins only if the device has none: a reader who
      // just carried on reading offline is further along than the server.
      VerseRef? position = state.lastRead;
      if (position == null) {
        final positionBody = results[1].data;
        if (positionBody is Map && positionBody['data'] is Map) {
          position = VerseRef.parse(
            (positionBody['data'] as Map)['verse_key'] as String?,
          );
        }
      }

      state = state.copyWith(bookmarks: merged, lastRead: position);
      await _save();

      // Push anything the device had that the server did not.
      for (final key in state.bookmarks) {
        if (!remoteKeys.contains(key)) {
          _pushBookmark(key, added: true);
        }
      }
    } catch (e) {
      debugPrint('Quran reading state could not be synced: $e');
    }
  }

  Future<void> _pushBookmark(String verseKey, {required bool added}) async {
    if (!await _signedIn()) return;

    try {
      final dio = ref.read(apiProvider);

      if (added) {
        await dio.post('/quran/bookmarks', data: {'verse_key': verseKey});
      } else {
        await dio.delete('/quran/bookmarks/$verseKey');
      }
    } catch (e) {
      // Both endpoints are idempotent, so the next pull reconciles.
      debugPrint('Bookmark $verseKey could not be synced: $e');
    }
  }

  Future<void> _pushPosition(String verseKey) async {
    if (!await _signedIn()) return;

    try {
      await ref
          .read(apiProvider)
          .put('/quran/position', data: {'verse_key': verseKey});
    } catch (e) {
      debugPrint('Reading position could not be synced: $e');
    }
  }

  Future<void> _save() async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode(state.toJson()),
      );
    } catch (e) {
      debugPrint('Quran reading state could not be saved: $e');
    }
  }

  void setReciter(String id) {
    state = state.copyWith(reciterId: id);
    _save();
  }

  void setArabicSize(double size) {
    state = state.copyWith(arabicSize: size.clamp(20, 48).toDouble());
    _save();
  }

  void toggleTranslation() {
    state = state.copyWith(showTranslation: !state.showTranslation);
    _save();
  }

  void toggleBookmark(int surah, int verse) {
    final key = VerseRef(surah, verse).key;
    final list = [...state.bookmarks];
    final added = !list.remove(key);
    if (added) list.insert(0, key);
    HapticFeedback.selectionClick();
    state = state.copyWith(bookmarks: list);
    _save();

    // Not awaited: the bookmark is already saved on the device and the UI
    // has already moved. The network is a mirror, not the gate.
    _pushBookmark(key, added: added);
  }

  void markRead(int surah, int verse) {
    if (state.lastRead == VerseRef(surah, verse)) return;

    final verseRef = VerseRef(surah, verse);
    state = state.copyWith(lastRead: verseRef);
    _save();

    // Debounced: a reader scrolling through Al-Baqarah passes hundreds of
    // verses, and only where they stop is worth a request.
    _positionDebounce?.cancel();
    _positionDebounce = Timer(
      const Duration(seconds: 3),
      () => _pushPosition(verseRef.key),
    );
  }
}

final quranReadingProvider =
    NotifierProvider<QuranReadingNotifier, QuranReadingState>(
      QuranReadingNotifier.new,
    );

// ===========================================================================
// Recitation player
// ===========================================================================

@immutable
class RecitationState {
  const RecitationState({
    this.surah,
    this.verse,
    this.isPlaying = false,
    this.isLoading = false,
    this.repeatVerse = false,
    this.error,
  });

  final int? surah;

  /// Verse number within [surah] currently loaded in the player.
  final int? verse;
  final bool isPlaying;
  final bool isLoading;
  final bool repeatVerse;
  final String? error;

  bool get isActive => surah != null;

  RecitationState copyWith({
    int? surah,
    int? verse,
    bool? isPlaying,
    bool? isLoading,
    bool? repeatVerse,
    String? error,
    bool clearError = false,
  }) => RecitationState(
    surah: surah ?? this.surah,
    verse: verse ?? this.verse,
    isPlaying: isPlaying ?? this.isPlaying,
    isLoading: isLoading ?? this.isLoading,
    repeatVerse: repeatVerse ?? this.repeatVerse,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Plays a surah verse by verse, advancing automatically (or repeating one
/// verse, for memorisation). The reader highlights and follows the verse in
/// [RecitationState.verse].
class RecitationNotifier extends Notifier<RecitationState> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _sub;

  /// Mushaf-wide verse numbers of the surah being played, by verse number.
  Map<int, int> _globalByVerse = const {};
  int _lastVerse = 0;

  @override
  RecitationState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _player?.dispose();
    });
    return const RecitationState();
  }

  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (e) {
      debugPrint('Audio session setup failed: $e');
    }
    final player = AudioPlayer();
    _sub = player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _onVerseFinished();
      } else {
        state = state.copyWith(
          isPlaying: s.playing,
          isLoading:
              s.processingState == ProcessingState.loading ||
              s.processingState == ProcessingState.buffering,
        );
      }
    });
    return _player = player;
  }

  /// Starts reciting [surah] at [verse]. [globalByVerse] maps each verse
  /// number to its mushaf-wide number.
  Future<void> play({
    required int surah,
    required int verse,
    required Map<int, int> globalByVerse,
  }) async {
    _globalByVerse = globalByVerse;
    _lastVerse = globalByVerse.keys.fold(0, (a, b) => a > b ? a : b);
    await _playVerse(surah, verse);
  }

  Future<void> _playVerse(int surah, int verse) async {
    final global = _globalByVerse[verse];
    if (global == null) return stop();
    state = state.copyWith(
      surah: surah,
      verse: verse,
      isLoading: true,
      clearError: true,
    );
    try {
      final player = await _ensurePlayer();
      final reciter = ref.read(quranReadingProvider).reciter;
      await player.setUrl(reciter.urlFor(global));
      await player.play();
    } catch (e) {
      debugPrint('Recitation failed for $surah:$verse: $e');
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        error:
            'Recitation could not be played. Check your connection and '
            'try again.',
      );
    }
  }

  void _onVerseFinished() {
    final surah = state.surah, verse = state.verse;
    if (surah == null || verse == null) return;
    if (state.repeatVerse) {
      _playVerse(surah, verse);
    } else if (verse < _lastVerse) {
      _playVerse(surah, verse + 1);
    } else {
      stop();
    }
  }

  Future<void> togglePlayPause() async {
    final player = _player;
    if (player == null) return;
    HapticFeedback.lightImpact();
    player.playing ? await player.pause() : await player.play();
  }

  Future<void> next() async {
    final s = state.surah, v = state.verse;
    if (s != null && v != null && v < _lastVerse) await _playVerse(s, v + 1);
  }

  Future<void> previous() async {
    final s = state.surah, v = state.verse;
    if (s != null && v != null && v > 1) await _playVerse(s, v - 1);
  }

  void toggleRepeat() {
    HapticFeedback.selectionClick();
    state = state.copyWith(repeatVerse: !state.repeatVerse);
  }

  Future<void> stop() async {
    await _player?.stop();
    state = RecitationState(repeatVerse: state.repeatVerse);
  }
}

final recitationProvider =
    NotifierProvider<RecitationNotifier, RecitationState>(
      RecitationNotifier.new,
    );

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:ehsan_pathways/core/services/api_service.dart';

/// One of the ten collections.
class HadithBook {
  const HadithBook({
    required this.slug,
    required this.name,
    this.arabicName,
    this.compiler,
    this.description,
    required this.hadithCount,
    required this.chapterCount,
  });

  final String slug;
  final String name;
  final String? arabicName;
  final String? compiler;
  final String? description;
  final int hadithCount;
  final int chapterCount;

  factory HadithBook.fromJson(Map<String, dynamic> j) => HadithBook(
    slug: j['slug'] as String,
    name: j['name'] as String? ?? '',
    arabicName: j['arabic_name'] as String?,
    compiler: j['compiler'] as String?,
    description: j['description'] as String?,
    hadithCount: (j['hadith_count'] as num?)?.toInt() ?? 0,
    chapterCount: (j['chapter_count'] as num?)?.toInt() ?? 0,
  );
}

class HadithChapter {
  const HadithChapter({
    required this.number,
    this.name,
    this.arabicName,
    required this.hadithCount,
  });

  final int number;
  final String? name;
  final String? arabicName;
  final int hadithCount;

  factory HadithChapter.fromJson(Map<String, dynamic> j) => HadithChapter(
    number: (j['number'] as num).toInt(),
    name: j['name'] as String?,
    arabicName: j['arabic_name'] as String?,
    hadithCount: (j['hadith_count'] as num?)?.toInt() ?? 0,
  );
}

class Hadith {
  const Hadith({
    required this.number,
    this.arabicText,
    this.englishText,
    this.grade,
    this.gradeSource,
    this.chapterName,
    this.bookName,
    this.bookSlug,
  });

  final String number;
  final String? arabicText;
  final String? englishText;
  final String? grade;
  final String? gradeSource;
  final String? chapterName;
  final String? bookName;
  final String? bookSlug;

  factory Hadith.fromJson(Map<String, dynamic> j) {
    final book = j['book'] as Map<String, dynamic>?;
    final chapter = j['chapter'] as Map<String, dynamic>?;

    return Hadith(
      number: j['number']?.toString() ?? '',
      // The API names these `arabic` and `english`; the *_text spellings are
      // accepted too so either shape deserialises.
      arabicText: (j['arabic'] ?? j['arabic_text']) as String?,
      englishText: (j['english'] ?? j['english_text']) as String?,
      grade: j['grade'] as String?,
      gradeSource: j['grade_source'] as String?,
      chapterName: (chapter?['name'] ?? j['chapter_name']) as String?,
      bookName: (book?['name'] ?? j['book_name']) as String?,
      bookSlug: (book?['slug'] ?? j['book_slug']) as String?,
    );
  }
}

/// A page of hadith plus the cursor for the next one.
class HadithPage {
  const HadithPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
  });

  final List<Hadith> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;
}

// ---------------------------------------------------------------------------

final hadithBooksProvider = FutureProvider<List<HadithBook>>((ref) async {
  final res = await ref.watch(apiProvider).get('/islamic-tools/hadith/books');

  return ((res.data as Map<String, dynamic>)['data'] as List)
      .map((e) => HadithBook.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
});

final hadithChaptersProvider = FutureProvider.autoDispose
    .family<List<HadithChapter>, String>((ref, slug) async {
      final res = await ref
          .watch(apiProvider)
          .get('/islamic-tools/hadith/books/$slug/chapters');

      final data =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      return (data['chapters'] as List)
          .map((e) => HadithChapter.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });

/// Identifies one run of hadith: a whole book, or one chapter of it.
class HadithQuery {
  const HadithQuery({required this.bookSlug, this.chapter});

  final String bookSlug;
  final int? chapter;

  @override
  bool operator ==(Object other) =>
      other is HadithQuery &&
      other.bookSlug == bookSlug &&
      other.chapter == chapter;

  @override
  int get hashCode => Object.hash(bookSlug, chapter);
}

/// Pages through a book or chapter. Collections run to thousands of hadith, so
/// nothing here ever asks for all of them at once.
class HadithListNotifier extends StateNotifier<AsyncValue<HadithPage>> {
  HadithListNotifier(this._dio, this._query)
    : super(const AsyncValue.loading()) {
    loadFirst();
  }

  final Dio _dio;
  final HadithQuery _query;

  bool _loadingMore = false;

  Future<void> loadFirst() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _fetch(1));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (_loadingMore || current == null || !current.hasMore) return;

    _loadingMore = true;
    try {
      final next = await _fetch(current.currentPage + 1);
      state = AsyncValue.data(
        HadithPage(
          items: [...current.items, ...next.items],
          currentPage: next.currentPage,
          lastPage: next.lastPage,
          total: next.total,
          hasMore: next.hasMore,
        ),
      );
    } catch (_) {
      // Keep what is already on screen; the footer will offer another try.
    } finally {
      _loadingMore = false;
    }
  }

  Future<HadithPage> _fetch(int page) async {
    final res = await _dio.get(
      '/islamic-tools/hadith/books/${_query.bookSlug}/hadiths',
      queryParameters: {
        'page': page,
        if (_query.chapter != null) 'chapter': _query.chapter,
      },
    );

    final body = res.data as Map<String, dynamic>;
    final meta = body['meta'] as Map<String, dynamic>;

    return HadithPage(
      items: (body['data'] as List)
          .map((e) => Hadith.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      currentPage: (meta['current_page'] as num).toInt(),
      lastPage: (meta['last_page'] as num).toInt(),
      total: (meta['total'] as num).toInt(),
      hasMore: meta['has_more'] as bool? ?? false,
    );
  }
}

final hadithListProvider = StateNotifierProvider.autoDispose
    .family<HadithListNotifier, AsyncValue<HadithPage>, HadithQuery>(
      (ref, query) => HadithListNotifier(ref.watch(apiProvider), query),
    );

/// The hadith of the day, shared by every device.
final dailyHadithProvider = FutureProvider<Hadith>((ref) async {
  final res = await ref.watch(apiProvider).get('/islamic-tools/hadith/daily');

  return Hadith.fromJson(
    (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
  );
});

final hadithStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final res = await ref.watch(apiProvider).get('/islamic-tools/hadith/stats');
  final data =
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  return data.map((k, v) => MapEntry(k, (v as num).toInt()));
});

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

class HadithSearchState {
  const HadithSearchState({
    this.results = const [],
    this.query = '',
    this.total = 0,
    this.loading = false,
    this.error,
    this.searched = false,
  });

  final List<Hadith> results;
  final String query;
  final int total;
  final bool loading;
  final String? error;
  final bool searched;
}

class HadithSearchNotifier extends StateNotifier<HadithSearchState> {
  HadithSearchNotifier(this._dio) : super(const HadithSearchState());

  final Dio _dio;

  Future<void> search(String term, {String? bookSlug}) async {
    final trimmed = term.trim();

    if (trimmed.length < 3) {
      state = HadithSearchState(
        query: trimmed,
        error: 'Type at least three characters.',
        searched: false,
      );
      return;
    }

    state = HadithSearchState(query: trimmed, loading: true);

    try {
      final res = await _dio.get(
        '/islamic-tools/hadith/search',
        queryParameters: {'q': trimmed, if (bookSlug != null) 'book': bookSlug},
      );

      final body = res.data as Map<String, dynamic>;

      state = HadithSearchState(
        query: trimmed,
        results: (body['data'] as List)
            .map((e) => Hadith.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        total: ((body['meta'] as Map<String, dynamic>)['total'] as num).toInt(),
        searched: true,
      );
    } on DioException catch (e) {
      state = HadithSearchState(
        query: trimmed,
        searched: true,
        error: e.response?.statusCode == 422
            ? 'Type at least three characters.'
            : 'The search could not be completed. Check your connection.',
      );
    }
  }

  void clear() => state = const HadithSearchState();
}

final hadithSearchProvider =
    StateNotifierProvider.autoDispose<HadithSearchNotifier, HadithSearchState>(
      (ref) => HadithSearchNotifier(ref.watch(apiProvider)),
    );

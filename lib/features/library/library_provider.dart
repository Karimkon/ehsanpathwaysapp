import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/features/library/models/library_book.dart';

/// Everything the library screen needs in one fetch: the books and the shelves
/// they sit on.
class LibraryCatalogue {
  const LibraryCatalogue({required this.books, required this.categories});

  final List<LibraryBook> books;
  final List<LibraryCategory> categories;

  List<LibraryBook> inCategory(String? slug) => slug == null
      ? books
      : books.where((b) => b.category == slug).toList(growable: false);
}

final libraryCatalogueProvider =
    FutureProvider.autoDispose<LibraryCatalogue>((ref) async {
  final dio = ref.watch(apiProvider);
  final res = await dio.get('/library/books');
  final body = res.data as Map<String, dynamic>;

  return LibraryCatalogue(
    books: (body['data'] as List)
        .map((e) => LibraryBook.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    categories: ((body['meta']?['categories'] ?? []) as List)
        .map((e) => LibraryCategory.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
});

final libraryBookProvider =
    FutureProvider.autoDispose.family<LibraryBook, String>((ref, slug) async {
  final dio = ref.watch(apiProvider);
  final res = await dio.get('/library/books/$slug');

  return LibraryBook.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
});

/// Books this reader has open, newest first. Empty when signed out.
final continueReadingProvider =
    FutureProvider.autoDispose<List<LibraryBook>>((ref) async {
  final dio = ref.watch(apiProvider);

  try {
    final res = await dio.get('/library/continue');
    return ((res.data as Map<String, dynamic>)['data'] as List)
        .map((e) => LibraryBook.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  } on DioException {
    return const [];
  }
});

/// Which shelf the library screen is filtered to; null means all of them.
final libraryFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Reading position
// ---------------------------------------------------------------------------

/// Remembers the page a reader reached.
///
/// The page is written locally first so the book always reopens where they left
/// it, signed in or not, online or not. Signed-in readers also get it synced to
/// the server, which is what carries their place across to a new phone.
class ReadingPositionService {
  ReadingPositionService(this._dio);

  final Dio _dio;

  static String _key(String slug) => 'library_page_$slug';

  Future<int> localPage(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(slug)) ?? 1;
  }

  Future<void> save(String slug, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(slug), page);

    try {
      await _dio.post('/library/books/$slug/progress', data: {'page': page});
    } on DioException {
      // Signed out, or offline. The local page above is the one that matters
      // for reopening the book, so this is not worth surfacing.
    }
  }
}

final readingPositionProvider = Provider<ReadingPositionService>(
    (ref) => ReadingPositionService(ref.watch(apiProvider)));

// ---------------------------------------------------------------------------
// Offline copies
// ---------------------------------------------------------------------------

/// Saves a book to the device so it can be read with no signal.
///
/// Not supported on the web, where there is no writable app directory — there
/// the reader streams instead.
class OfflineLibrary {
  OfflineLibrary(this._dio);

  final Dio _dio;

  Future<Directory?> _dir() async {
    if (kIsWeb) return null;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/library');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> pathIfSaved(String slug) async {
    final dir = await _dir();
    if (dir == null) return null;
    final file = File('${dir.path}/$slug.pdf');
    return await file.exists() ? file.path : null;
  }

  Future<String> download(
    LibraryBook book, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await _dir();
    if (dir == null) {
      throw UnsupportedError('Offline saving is not available on the web.');
    }

    // Write to a temporary name first: a download interrupted halfway must not
    // leave behind a truncated file that later looks like a saved book.
    final target = '${dir.path}/${book.slug}.pdf';
    final partial = '$target.part';

    await _dio.download(
      book.pdfUrl,
      partial,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
      options: Options(headers: {'Accept': 'application/pdf'}),
    );

    await File(partial).rename(target);

    try {
      await _dio.post('/library/books/${book.slug}/downloaded');
    } on DioException {
      // Only a counter.
    }

    return target;
  }

  Future<void> remove(String slug) async {
    final path = await pathIfSaved(slug);
    if (path != null) await File(path).delete();
  }

  Future<int> savedBytes() async {
    final dir = await _dir();
    if (dir == null) return 0;

    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.pdf')) {
        total += await entity.length();
      }
    }
    return total;
  }
}

final offlineLibraryProvider =
    Provider<OfflineLibrary>((ref) => OfflineLibrary(ref.watch(apiProvider)));

/// Whether a given book already has an offline copy.
final offlineCopyProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, slug) =>
        ref.watch(offlineLibraryProvider).pathIfSaved(slug));

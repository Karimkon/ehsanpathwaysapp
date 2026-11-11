import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_search_screen.dart';

/// quran_search_yuhibb.json is a real response from production
/// (/api/v1/quran/search?q=يحب&per_page=5), saved verbatim, so the parsing
/// and the screen are tested against what the server actually sends.
class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.body);
  final String body;
  final List<Uri> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _, Future<void>? __) async {
    calls.add(options.uri);
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final body = File('test/fixtures/quran_search_yuhibb.json').readAsStringSync();
  final json = jsonDecode(body) as Map<String, dynamic>;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('parses the real server response', () {
    final r = QuranSearchResult.fromJson(json['data'] as Map<String, dynamic>);

    expect(r.total, 54);
    expect(r.hits, hasLength(5));
    expect(r.bySurah.length, greaterThan(10));
    expect(r.bySurah.values.fold<int>(0, (a, b) => a + b), 54);

    final first = r.hits.first;
    expect(first.verseKey, '2:165');
    expect(first.highlight, isNotEmpty);
    // Every highlighted word really contains the root letters, once marks
    // are stripped.
    for (final i in first.highlight) {
      final bare = first.words[i].replaceAll(RegExp(r'[ً-ٰٟۖ-ۭ]'), '');
      expect(bare, contains('حب'));
    }
  });

  testWidgets('the screen searches and lists highlighted verses', (tester) async {
    final adapter = _FixtureAdapter(body);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))..httpClientAdapter = adapter;

    await tester.pumpWidget(ProviderScope(
      overrides: [apiProvider.overrideWithValue(dio)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const QuranSearchScreen(initialQuery: 'يحب'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(adapter.calls.single.queryParameters['q'], 'يحب');
    expect(find.textContaining('54 verses'), findsOneWidget);
    expect(find.textContaining('2:165'), findsOneWidget);
    expect(find.textContaining('All · 54'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

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
import 'package:ehsan_pathways/features/ask/ask_screen.dart';

/// ask_parents.json is production's real answer to "how to treat parents".
class _Fixture implements HttpClientAdapter {
  _Fixture(this.body);
  final String body;
  final List<RequestOptions> sent = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? __) async {
    sent.add(o);
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final body = File('test/fixtures/ask_parents.json').readAsStringSync();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('parses a real answer', () {
    final m = AskMessage.fromAnswer((jsonDecode(body) as Map<String, dynamic>)['data'] as Map<String, dynamic>);
    expect(m.text, isNotEmpty);
    expect(m.crisis, isFalse);
    expect(m.sources.map((s) => s.title), contains(contains('17:23')));
  });

  testWidgets('asking shows the answer and its sources', (tester) async {
    // Tall enough that the list keeps the question on screen after it
    // scrolls to the answer (the list builds lazily).
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final adapter = _Fixture(body);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))..httpClientAdapter = adapter;

    await tester.pumpWidget(ProviderScope(
      overrides: [apiProvider.overrideWithValue(dio)],
      child: MaterialApp(theme: AppTheme.light, home: const AskScreen()),
    ));

    await tester.enterText(find.byType(TextField), 'how to treat parents');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(adapter.sent.single.path, '/ask');
    expect((adapter.sent.single.data as Map)['question'], 'how to treat parents');
    expect(find.text('how to treat parents'), findsOneWidget);
    expect(find.textContaining('17:23'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

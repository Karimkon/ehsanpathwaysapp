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
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/core/services/guided_share.dart';
import 'package:ehsan_pathways/features/impact/impact_screen.dart';

/// Both fixtures are what the Laravel ShareController actually returned
/// (captured from a run of the server code, not typed by hand).
class _Fixture implements HttpClientAdapter {
  _Fixture(this.body, {this.status = 200});
  final String body;
  final int status;
  final List<RequestOptions> sent = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? __) async {
    sent.add(o);
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

Dio _dio(_Fixture adapter) => Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))..httpClientAdapter = adapter;

void main() {
  final impactBody = File('test/fixtures/impact_two_shares.json').readAsStringSync();
  final shareBody = File('test/fixtures/share_tracked.json').readAsStringSync();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('a share asks the server for a counted link', () async {
    final adapter = _Fixture(shareBody);
    final link = await GuidedShare.resolve(_dio(adapter), type: 'verse', key: '2:255', fallbackPath: '/quran/2#v255');

    expect(adapter.sent.single.path, '/share');
    expect(adapter.sent.single.data, {'type': 'verse', 'key': '2:255'});
    expect(link.tracked, isTrue);
    expect(link.url, contains('/s/'));
  });

  test('a failed request still shares the plain page', () async {
    final adapter = _Fixture('{"message":"That item cannot be shared."}', status: 422);
    final link = await GuidedShare.resolve(_dio(adapter), type: 'verse', key: '2:255', fallbackPath: '/quran/2#v255');

    expect(link.tracked, isFalse);
    expect(link.url, 'https://ehsanpathways.com/quran/2#v255');
  });

  test('parses the impact response', () {
    final impact = Impact.fromJson(jsonDecode(impactBody) as Map<String, dynamic>);

    expect(impact.reached, 3);
    expect(impact.started, 1);
    expect(impact.shared, 2);
    expect(impact.items.map((i) => i.title), ["Qur'an Al-Baqarah 2:255", 'Foundations of Tawheed']);
    expect(impact.items.first.canStart, isFalse);
    expect(impact.items.last.canStart, isTrue);
    expect(impact.intention, 'To seek the pleasure of Allah alone');
    expect(impact.presets, hasLength(4));
  });

  testWidgets('My Impact shows the numbers, the items and the intention', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final adapter = _Fixture(impactBody);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiProvider.overrideWithValue(_dio(adapter)),
        authProvider.overrideWith(_SignedIn.new),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const ImpactScreen()),
    ));
    await tester.pumpAndSettle();

    expect(adapter.sent.single.path, '/me/impact');
    expect(find.text('3'), findsOneWidget);
    expect(find.text('people reached'), findsOneWidget);
    expect(find.text('Foundations of Tawheed'), findsOneWidget);
    expect(find.text('1 started'), findsOneWidget);
    expect(find.text('2 reached'), findsOneWidget);
    expect(find.text('"To seek the pleasure of Allah alone"'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed out, it invites the user to sign in', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authProvider.overrideWith(_UnAuth.new)],
      child: MaterialApp(theme: AppTheme.dark, home: const ImpactScreen()),
    ));
    await tester.pump();

    expect(find.text('See the good you pass on'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

class _UnAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

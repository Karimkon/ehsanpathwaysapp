import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/features/arabic/arabic_course_detail_screen.dart';
import 'package:ehsan_pathways/features/daily/daily_deed_screen.dart';
import 'package:ehsan_pathways/features/arabic/arabic_screen.dart';
import 'package:ehsan_pathways/features/articles/article_detail_screen.dart';
import 'package:ehsan_pathways/features/articles/articles_screen.dart';
import 'package:ehsan_pathways/features/bookmarks/bookmarks_screen.dart';
import 'package:ehsan_pathways/features/hajj/hajj_guide_detail_screen.dart';
import 'package:ehsan_pathways/features/hajj/hajj_umrah_screen.dart';
import 'package:ehsan_pathways/features/history/history_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/dua/dua_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_books_screen.dart';
import 'package:ehsan_pathways/features/khutbahs/khutbah_detail_screen.dart';
import 'package:ehsan_pathways/features/khutbahs/khutbahs_screen.dart';
import 'package:ehsan_pathways/features/library/library_screen.dart';
import 'package:ehsan_pathways/features/live/live_streams_screen.dart';
import 'package:ehsan_pathways/features/pathways/pathway_detail_screen.dart';
import 'package:ehsan_pathways/features/pathways/pathways_screen.dart';
import 'package:ehsan_pathways/features/podcasts/podcast_detail_screen.dart';
import 'package:ehsan_pathways/features/podcasts/podcasts_screen.dart';
import 'package:ehsan_pathways/features/sadaqah/sadaqah_screen.dart';
import 'package:ehsan_pathways/features/scholars/scholar_detail_screen.dart';
import 'package:ehsan_pathways/features/scholars/scholars_screen.dart';
import 'package:ehsan_pathways/features/videos/videos_screen.dart';

/// Every screen opened against what the server really sends.
///
/// test/fixtures/api/ is written by the Laravel AppApiContractTest (the real
/// controllers over seeded rows: run it with CAPTURE_APP_FIXTURES pointing
/// here); test/fixtures/live/ is production's own responses. A screen passes
/// only if it shows its content and no error state. Before this, pathways,
/// history, Arabic, bookmarks and more were broken on the phone while every
/// unit test passed against hand-typed JSON.

String _fx(String name) {
  // "live:x" forces production's response over the locally captured one.
  if (name.startsWith('live:')) return File('test/fixtures/live/${name.substring(5)}.json').readAsStringSync();
  for (final dir in ['test/fixtures/api', 'test/fixtures/live']) {
    final f = File('$dir/$name.json');
    if (f.existsSync()) return f.readAsStringSync();
  }
  throw StateError('missing fixture $name');
}

/// Request path -> fixture. First match wins.
final _routes = <(RegExp, String)>[
  (RegExp(r'^/home$'), 'home'),
  (RegExp(r'^/videos/feed$'), 'videos_feed'),
  (RegExp(r'^/videos$'), 'videos'),
  (RegExp(r'^/videos/[0-9a-f-]{36}$'), 'video_detail'),
  (RegExp(r'^/articles$'), 'articles'),
  (RegExp(r'^/articles/[\w-]+$'), 'article_detail'),
  (RegExp(r'^/podcasts$'), 'podcasts'),
  (RegExp(r'^/podcasts/[\w-]+$'), 'podcast_detail'),
  (RegExp(r'^/khutbahs$'), 'khutbahs'),
  (RegExp(r'^/khutbahs/[\w-]+$'), 'khutbah_detail'),
  (RegExp(r'^/scholars$'), 'scholars'),
  (RegExp(r'^/scholars/[\w-]+/videos$'), 'scholar_videos'),
  (RegExp(r'^/scholars/[\w-]+/articles$'), 'scholar_articles'),
  (RegExp(r'^/scholars/[\w-]+/podcasts$'), 'scholar_podcasts'),
  (RegExp(r'^/scholars/[\w-]+$'), 'scholar_detail'),
  (RegExp(r'^/pathways$'), 'pathways'),
  (RegExp(r'^/pathways/[\w-]+/enroll$'), 'pathway_enroll'),
  (RegExp(r'^/pathways/[\w-]+/items/\d+/complete$'), 'pathway_complete'),
  (RegExp(r'^/pathways/[\w-]+$'), 'pathway_detail'),
  (RegExp(r'^/arabic/courses$'), 'arabic_courses'),
  (RegExp(r'^/arabic/courses/[\w-]+$'), 'arabic_course_detail'),
  (RegExp(r'^/arabic/courses/[\w-]+/lessons/\d+$'), 'arabic_lesson'),
  (RegExp(r'^/hajj-umrah$'), 'hajj_umrah'),
  (RegExp(r'^/hajj-umrah/[\w-]+$'), 'hajj_detail'),
  (RegExp(r'^/live-streams$'), 'live_streams'),
  (RegExp(r'^/sadaqah/purposes$'), 'sadaqah_purposes'),
  (RegExp(r'^/sadaqah/reports$'), 'sadaqah_reports'),
  (RegExp(r'^/library/books$'), 'library_books'),
  (RegExp(r'^/library/continue$'), 'library_continue'),
  (RegExp(r'^/islamic-tools/dua/categories$'), 'islamic-tools_dua_categories'),
  (RegExp(r'^/islamic-tools/hadith/books$'), 'islamic-tools_hadith_books'),
  (RegExp(r'^/islamic-tools/hadith/collections$'), 'islamic-tools_hadith_collections'),
  (RegExp(r'^/islamic-tools/hadith/daily$'), 'islamic-tools_hadith_daily'),
  (RegExp(r'^/islamic-tools/hadith/stats$'), 'islamic-tools_hadith_stats'),
  (RegExp(r'^/progress/videos$'), 'history'),
  (RegExp(r'^/bookmarks/check$'), 'bookmark_check'),
  (RegExp(r'^/bookmarks$'), 'bookmarks'),
  (RegExp(r'^/notes$'), 'notes_empty'),
  (RegExp(r'^/hifz/progress$'), 'hifz_progress'),
  (RegExp(r'^/guidance$'), 'guidance_mine'),
  (RegExp(r'^/me/impact$'), 'impact'),
  (RegExp(r'^/daily-deed$'), 'daily_deed'),
  (RegExp(r'^/daily-deed/(verse|dhikr|dua)$'), 'daily_deed_mark'),
  (RegExp(r'^/auth/user$'), 'auth_user'),
];

class _Api implements HttpClientAdapter {
  _Api([this.overrides = const {}]);

  /// fixture name -> replacement fixture name, e.g. history -> history_empty.
  final Map<String, String> overrides;
  final List<String> unmatched = [];
  final List<String> sent = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? __) async {
    final path = Uri.parse(o.path).path;
    sent.add('${o.method} $path');
    for (final (rx, name) in _routes) {
      if (rx.hasMatch(path)) {
        return ResponseBody.fromString(_fx(overrides[name] ?? name), 200, headers: {
          Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        });
      }
    }
    unmatched.add('${o.method} $path');
    return ResponseBody.fromString('{"message":"Not Found"}', 404, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _SignedIn extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

/// Text an error state shows. None of these may be on screen.
final _errorText = RegExp(
  r"Failed to load|Could not load|Couldn't load|Something went wrong|is not a subtype|Exception|Error:|Unable to load",
  caseSensitive: false,
);

Future<_Api> _open(WidgetTester tester, Widget screen, {Map<String, String> overrides = const {}, bool signedIn = true}) async {
  if (const bool.fromEnvironment('TRACE_ERRORS')) {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final lines = const LineSplitter().convert(details.toString());
      final keep = lines.where((l) => l.contains('error-causing') || l.contains('lib/features') || l.contains('overflowed'));
      debugPrint('TRACE ${keep.join(' || ')}');
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);

  final api = _Api(overrides);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))..httpClientAdapter = api;
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => screen),
    GoRoute(path: '/:rest(.*)', builder: (_, __) => const Scaffold()),
  ]);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      apiProvider.overrideWithValue(dio),
      if (signedIn) authProvider.overrideWith(_SignedIn.new),
    ],
    child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
  ));
  // Settle network futures without waiting on endless animations (shimmers, players).
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return api;
}

String _visibleText(WidgetTester tester) => find
    .byType(Text)
    .evaluate()
    .map((e) => (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '')
    .where((t) => t.trim().isNotEmpty)
    .take(40)
    .join(' | ');

/// A person scrolls; so does the test, down the main list, before giving up.
Future<void> _scrollTo(WidgetTester tester, String text) async {
  final target = find.textContaining(text, findRichText: true);
  final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  for (var i = 0; i < 12 && target.evaluate().isEmpty && vertical.evaluate().isNotEmpty; i++) {
    await tester.drag(vertical.first, const Offset(0, -500), warnIfMissed: false);
    for (var j = 0; j < 4; j++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _expectHealthy(WidgetTester tester, List<String> mustShow, String screen) async {
  final errors = find.byWidgetPredicate((w) => w is Text && _errorText.hasMatch(w.data ?? w.textSpan?.toPlainText() ?? ''));
  expect(errors, findsNothing,
      reason: '$screen shows an error: ${errors.evaluate().map((e) => (e.widget as Text).data).join(' | ')}');
  for (final text in mustShow) {
    await _scrollTo(tester, text);
    expect(find.textContaining(text, findRichText: true), findsWidgets,
        reason: '$screen should show "$text". On screen: ${_visibleText(tester)}');
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final cases = <(String, Widget Function(), List<String>, Map<String, String>)>[
    ('Videos', () => const VideosScreen(), ['Tawheed explained'], {}),
    ('Articles', () => const ArticlesScreen(), ['Patience in Islam'], {}),
    ('Article detail', () => const ArticleDetailScreen(slug: 'patience-in-islam'), ['Patience in Islam', 'Allah is with the patient'], {}),
    ('Podcasts', () => const PodcastsScreen(), ['Preparing for Ramadan'], {}),
    ('Podcast detail', () => const PodcastDetailScreen(slug: 'ramadan-prep'), ['Preparing for Ramadan'], {}),
    ('Khutbahs', () => const KhutbahsScreen(), ['Taqwa in daily life'], {}),
    ('Khutbah detail', () => const KhutbahDetailScreen(slug: 'jumuah-taqwa'), ['Taqwa in daily life', 'Fear Allah'], {}),
    ('Scholars', () => const ScholarsScreen(), ['Ahmed Ali'], {}),
    ('Scholar detail', () => const ScholarDetailScreen(slug: 'sheikh-ahmed'), ['Ahmed Ali', 'Teaches aqeedah'], {}),
    ('Pathways', () => const PathwaysScreen(), ['Foundations of Faith'], {}),
    ('Pathway detail', () => const PathwayDetailScreen(slug: 'foundations'), ['Foundations of Faith', 'Tawheed explained', 'Patience in Islam'], {}),
    ('Arabic', () => const ArabicScreen(), ['Arabic 101'], {}),
    ('Arabic course', () => const ArabicCourseDetailScreen(slug: 'arabic-101'), ['Arabic 101', 'The alphabet'], {}),
    ('History', () => const HistoryScreen(), ['Tawheed explained'], {}),
    ('History (none yet)', () => const HistoryScreen(), [], {'history': 'history_empty'}),
    ('Bookmarks', () => const BookmarksScreen(), ['Tawheed explained', 'Patience in Islam'], {}),
    ('Bookmarks (none yet)', () => const BookmarksScreen(), [], {'bookmarks': 'bookmarks_empty'}),
    ('Daily deed', () => const DailyDeedScreen(), ['1 of 3 done today', 'Sahih al-Bukhari 6307', 'Remind me', 'After Fajr'], {}),
    ('Library', () => const LibraryScreen(), ['Sahih al-Bukhari'], {'library_books': 'live:library_books'}),
    ('Hadith books', () => const HadithBooksScreen(), ['Sahih al-Bukhari'], {}),
    ('Duas', () => const DuaScreen(), ['Morning Adhkar'], {}),
    ('Hajj & Umrah', () => const HajjUmrahScreen(), ['Hajj Step by Step', 'Duas & Adhkar'], {}),
    ('Hajj guide detail', () => const HajjGuideDetailScreen(slug: 'complete-umrah-guide'), ['Complete Umrah Guide', 'Tawaf', 'Checklists'], {}),
    ('Live streams (none yet)', () => const LiveStreamsScreen(), [], {}),
    ('Sadaqah (none yet)', () => const SadaqahScreen(), [], {}),
  ];

  for (final (name, build, mustShow, overrides) in cases) {
    testWidgets('$name works against the real API', (tester) async {
      final api = await _open(tester, build(), overrides: overrides);
      final early = tester.takeException();
      if (early != null) {
        fail('$name threw: ${early is FlutterError ? early.toStringDeep() : early}');
      }
      await _expectHealthy(tester, mustShow, name);
      final thrown = tester.takeException();
      if (thrown != null) {
        fail('$name threw: ${thrown is FlutterError ? thrown.toStringDeep() : thrown}');
      }
      if (api.unmatched.isNotEmpty) {
        // Not a failure by itself, but every path a screen asks for should be served.
        debugPrint('$name also asked for: ${api.unmatched.join(', ')}');
      }
    });
  }

  testWidgets('Starting a pathway sends the enrolment', (tester) async {
    final api = await _open(tester, const PathwayDetailScreen(slug: 'foundations'));
    await tester.tap(find.text('Start this pathway'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(api.sent, contains('POST /pathways/foundations/enroll'));
    expect(find.textContaining('Could not'), findsNothing);
  });

  testWidgets("Ticking the daily du'a posts it with the phone's date", (tester) async {
    final api = await _open(tester, const DailyDeedScreen());
    await _scrollTo(tester, "I made this du'a");
    await tester.tap(find.text("I made this du'a"));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(api.sent, contains('POST /daily-deed/dua'));
    expect(find.textContaining('Could not'), findsNothing);
  });
}

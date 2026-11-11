import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/features/shell/app_shell.dart';
import 'package:ehsan_pathways/features/home/home_screen.dart';
import 'package:ehsan_pathways/features/videos/videos_screen.dart';
import 'package:ehsan_pathways/features/videos/video_detail_screen.dart';
import 'package:ehsan_pathways/features/articles/articles_screen.dart';
import 'package:ehsan_pathways/features/articles/article_detail_screen.dart';
import 'package:ehsan_pathways/features/podcasts/podcasts_screen.dart';
import 'package:ehsan_pathways/features/podcasts/podcast_detail_screen.dart';
import 'package:ehsan_pathways/features/profile/profile_screen.dart';
import 'package:ehsan_pathways/features/scholars/scholars_screen.dart';
import 'package:ehsan_pathways/features/scholars/scholar_detail_screen.dart';
import 'package:ehsan_pathways/features/search/search_screen.dart';
import 'package:ehsan_pathways/features/auth/login_screen.dart';
import 'package:ehsan_pathways/features/auth/register_screen.dart';
import 'package:ehsan_pathways/features/bookmarks/bookmarks_screen.dart';
import 'package:ehsan_pathways/features/notes/notes_screen.dart';
import 'package:ehsan_pathways/features/guidance/guidance_screen.dart';
import 'package:ehsan_pathways/features/ask/ask_screen.dart';
import 'package:ehsan_pathways/features/pathways/pathways_screen.dart';
import 'package:ehsan_pathways/features/pathways/pathway_detail_screen.dart';
import 'package:ehsan_pathways/features/history/history_screen.dart';
import 'package:ehsan_pathways/features/onboarding/onboarding_screen.dart';
import 'package:ehsan_pathways/features/notifications/notification_settings_screen.dart';
import 'package:ehsan_pathways/features/arabic/arabic_screen.dart';
import 'package:ehsan_pathways/features/arabic/arabic_course_detail_screen.dart';
import 'package:ehsan_pathways/features/khutbahs/khutbahs_screen.dart';
import 'package:ehsan_pathways/features/khutbahs/khutbah_detail_screen.dart';
import 'package:ehsan_pathways/features/hajj/hajj_umrah_screen.dart';
import 'package:ehsan_pathways/features/hajj/hajj_guide_detail_screen.dart';
import 'package:ehsan_pathways/features/live/live_streams_screen.dart';
import 'package:ehsan_pathways/features/sadaqah/sadaqah_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_reader_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_search_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_collection_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_books_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_chapters_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_reader_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_search_screen.dart';
import 'package:ehsan_pathways/features/library/library_screen.dart';
import 'package:ehsan_pathways/features/library/book_detail_screen.dart';
import 'package:ehsan_pathways/features/library/book_reader_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/dua/dua_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/dua/dua_category_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/hifz/hifz_screen.dart';
import 'package:ehsan_pathways/features/prayer/prayer_times_screen.dart';
import 'package:ehsan_pathways/features/qibla/qibla_screen.dart';
import 'package:ehsan_pathways/features/tasbih/tasbih_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/calendar/hijri_calendar_screen.dart';
import 'package:ehsan_pathways/features/islamic_tools/names/asma_ul_husna_screen.dart';
import 'package:ehsan_pathways/features/videos/category_videos_screen.dart';

/// Holds the initial route to open on cold start.
/// Overridden in main() after async-checking SharedPreferences.
final initialRouteProvider = Provider<String>((ref) => '/');

// Navigator keys for each tab branch (keeps back-stack per tab)
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _videosNavKey = GlobalKey<NavigatorState>(debugLabel: 'videos');
final _quranNavKey = GlobalKey<NavigatorState>(debugLabel: 'quran');
final _libraryNavKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Application router exposed as a Riverpod provider.
final routerProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.watch(initialRouteProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      // ── Bottom-navigation shell ──────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0 – Home
          StatefulShellBranch(
            navigatorKey: _homeNavKey,
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // Scholars list accessible from home
                  GoRoute(
                    path: 'scholars',
                    name: 'scholars',
                    builder: (context, state) => const ScholarsScreen(),
                    routes: [
                      GoRoute(
                        path: ':slug',
                        name: 'scholar-detail',
                        builder: (context, state) => ScholarDetailScreen(
                          slug: state.pathParameters['slug']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Tab 1 – Videos
          StatefulShellBranch(
            navigatorKey: _videosNavKey,
            routes: [
              GoRoute(
                path: '/videos',
                name: 'videos',
                builder: (context, state) => const VideosScreen(),
                routes: [
                  GoRoute(
                    path: ':uuid',
                    name: 'video-detail',
                    builder: (context, state) => VideoDetailScreen(
                      uuid: state.pathParameters['uuid']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2 – Quran. The reader itself stays at /islamic-tools/quran/:no
          // on the root navigator, so every existing link to it still resolves.
          StatefulShellBranch(
            navigatorKey: _quranNavKey,
            routes: [
              GoRoute(
                path: '/quran',
                name: 'quran-tab',
                builder: (context, state) => const QuranScreen(),
              ),
            ],
          ),

          // Tab 3 – Library: the scanned books, and the way in to the hadith
          // collections.
          StatefulShellBranch(
            navigatorKey: _libraryNavKey,
            routes: [
              GoRoute(
                path: '/library',
                name: 'library',
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'book/:slug',
                    name: 'library-book',
                    builder: (context, state) => BookDetailScreen(
                      slug: state.pathParameters['slug']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 4 – Profile
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (no bottom nav) ─────────────────────────

      // Articles and podcasts were tabs; they are now reached from Home and
      // Profile. Paths and route names are unchanged so existing links work.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/articles',
        name: 'articles',
        builder: (context, state) => const ArticlesScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: ':slug',
            name: 'article-detail',
            builder: (context, state) =>
                ArticleDetailScreen(slug: state.pathParameters['slug']!),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/podcasts',
        name: 'podcasts',
        builder: (context, state) => const PodcastsScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: ':slug',
            name: 'podcast-detail',
            builder: (context, state) =>
                PodcastDetailScreen(slug: state.pathParameters['slug']!),
          ),
        ],
      ),

      // Reading a scanned book is immersive, so it sits outside the shell.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/read/:slug',
        name: 'library-reader',
        builder: (context, state) =>
            BookReaderScreen(slug: state.pathParameters['slug']!),
      ),

      // ── Hadith collections ─────────────────────────────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/hadith-library',
        name: 'hadith-books',
        builder: (context, state) => const HadithBooksScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: ':slug',
            name: 'hadith-chapters',
            builder: (context, state) =>
                HadithChaptersScreen(slug: state.pathParameters['slug']!),
            routes: [
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                path: 'read',
                name: 'hadith-reader',
                builder: (context, state) {
                  final chapter = state.uri.queryParameters['chapter'];
                  return HadithReaderScreen(
                    slug: state.pathParameters['slug']!,
                    chapter: chapter == null ? null : int.tryParse(chapter),
                    title: state.uri.queryParameters['title'],
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/hadith-search',
        name: 'hadith-search',
        builder: (context, state) =>
            HadithSearchScreen(bookSlug: state.uri.queryParameters['book']),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notes',
        name: 'notes',
        builder: (context, state) => const NotesScreen(),
      ),
      // Whole-Quran verse search (server-side, same results as the website).
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quran-search',
        name: 'quran-search',
        builder: (context, state) => QuranSearchScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
          initialSurah: int.tryParse(state.uri.queryParameters['surah'] ?? ''),
        ),
      ),
      // Ask Ehsan: free Q&A grounded in the Qur'an and hadith.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ask',
        name: 'ask',
        builder: (context, state) => AskScreen(initialQuestion: state.uri.queryParameters['q']),
      ),
      // Seek Guidance: private, free counselling.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/guidance',
        name: 'guidance',
        builder: (context, state) => const GuidanceScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'new',
            name: 'guidance-new',
            builder: (context, state) =>
                GuidanceFormScreen(initialTopic: state.uri.queryParameters['topic']),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'r/:uuid',
            name: 'guidance-thread',
            builder: (context, state) =>
                GuidanceThreadScreen(uuid: state.pathParameters['uuid']!),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pathways',
        name: 'pathways',
        builder: (context, state) => const PathwaysScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: ':slug',
            name: 'pathway-detail',
            builder: (context, state) => PathwayDetailScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/arabic',
        name: 'arabic',
        builder: (context, state) => const ArabicScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: ':slug',
            name: 'arabic-detail',
            builder: (context, state) => ArabicCourseDetailScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/khutbahs',
        name: 'khutbahs',
        builder: (context, state) => const KhutbahsScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: ':slug',
            name: 'khutbah-detail',
            builder: (context, state) => KhutbahDetailScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/hajj-umrah',
        name: 'hajj-umrah',
        builder: (context, state) => const HajjUmrahScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: ':slug',
            name: 'hajj-guide-detail',
            builder: (context, state) => HajjGuideDetailScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/live',
        name: 'live',
        builder: (context, state) => const LiveStreamsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/sadaqah',
        name: 'sadaqah',
        builder: (context, state) => const SadaqahScreen(),
      ),

      // ── Islamic Tools ──────────────────────────────────────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/islamic-tools',
        name: 'islamic-tools',
        builder: (context, state) => const IslamicToolsScreen(),
        routes: [
          // Quran
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'quran',
            name: 'quran',
            builder: (context, state) => const QuranScreen(),
            routes: [
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                path: ':no',
                name: 'quran-reader',
                builder: (context, state) => QuranReaderScreen(
                  surahNo: int.tryParse(
                          state.pathParameters['no'] ?? '1') ??
                      1,
                  initialVerse:
                      int.tryParse(state.uri.queryParameters['verse'] ?? ''),
                  memorise: state.uri.queryParameters['mode'] == 'hifz',
                ),
              ),
            ],
          ),
          // Hadith
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'hadith',
            name: 'hadith',
            builder: (context, state) => const HadithScreen(),
            routes: [
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                path: ':id',
                name: 'hadith-collection',
                builder: (context, state) => HadithCollectionScreen(
                  collectionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          // Dua
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'dua',
            name: 'dua',
            builder: (context, state) => const DuaScreen(),
            routes: [
              GoRoute(
                parentNavigatorKey: _rootNavigatorKey,
                path: ':id',
                name: 'dua-category',
                builder: (context, state) => DuaCategoryScreen(
                  categoryId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          // Hifz
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'hifz',
            name: 'hifz',
            builder: (context, state) => const HifzScreen(),
          ),
          // Prayer Times
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'prayer-times',
            name: 'prayer-times',
            builder: (context, state) => const PrayerTimesScreen(),
          ),
          // Qibla
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'qibla',
            name: 'qibla',
            builder: (context, state) => const QiblaScreen(),
          ),
          // Tasbih
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'tasbih',
            name: 'tasbih',
            builder: (context, state) => const TasbihScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'names',
            name: 'asma-ul-husna',
            builder: (context, state) => const AsmaUlHusnaScreen(),
          ),
          GoRoute(
            parentNavigatorKey: _rootNavigatorKey,
            path: 'calendar',
            name: 'hijri-calendar',
            builder: (context, state) => const HijriCalendarScreen(),
          ),
        ],
      ),

      // ── Category-filtered videos ───────────────────────────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/category/:slug',
        name: 'category-videos',
        builder: (context, state) => CategoryVideosScreen(
          slug: state.pathParameters['slug']!,
          name: state.uri.queryParameters['name'] ?? 'Category',
        ),
      ),
    ],
  );
});

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
import 'package:ehsan_pathways/features/pathways/pathways_screen.dart';
import 'package:ehsan_pathways/features/pathways/pathway_detail_screen.dart';
import 'package:ehsan_pathways/features/history/history_screen.dart';
import 'package:ehsan_pathways/features/onboarding/onboarding_screen.dart';

/// Holds the initial route to open on cold start.
/// Overridden in main() after async-checking SharedPreferences.
final initialRouteProvider = Provider<String>((ref) => '/');

// Navigator keys for each tab branch (keeps back-stack per tab)
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _videosNavKey = GlobalKey<NavigatorState>(debugLabel: 'videos');
final _articlesNavKey = GlobalKey<NavigatorState>(debugLabel: 'articles');
final _podcastsNavKey = GlobalKey<NavigatorState>(debugLabel: 'podcasts');
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

          // Tab 2 – Articles
          StatefulShellBranch(
            navigatorKey: _articlesNavKey,
            routes: [
              GoRoute(
                path: '/articles',
                name: 'articles',
                builder: (context, state) => const ArticlesScreen(),
                routes: [
                  GoRoute(
                    path: ':slug',
                    name: 'article-detail',
                    builder: (context, state) => ArticleDetailScreen(
                      slug: state.pathParameters['slug']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 3 – Podcasts
          StatefulShellBranch(
            navigatorKey: _podcastsNavKey,
            routes: [
              GoRoute(
                path: '/podcasts',
                name: 'podcasts',
                builder: (context, state) => const PodcastsScreen(),
                routes: [
                  GoRoute(
                    path: ':slug',
                    name: 'podcast-detail',
                    builder: (context, state) => PodcastDetailScreen(
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
    ],
  );
});

/// Application-wide configuration constants for EhsanPathways.
///
/// Centralizes API endpoints, app metadata, and feature flags
/// so every part of the app draws from a single source of truth.
class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------
  // App Identity
  // ---------------------------------------------------------------
  static const String appName = 'EhsanPathways';
  static const String appTagline = 'Your Journey to Islamic Knowledge';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ---------------------------------------------------------------
  // API
  // ---------------------------------------------------------------
  /// Base URL for the Laravel backend.
  static const String apiBaseUrl = 'https://ehsanpathways.com/api/v1';

  /// Timeout durations (in milliseconds).
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const int sendTimeout = 15000;

  // ---------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------
  static const int defaultPageSize = 15;
  static const int searchPageSize = 20;

  // ---------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------
  /// How long cached data is considered fresh (in minutes).
  static const int cacheDuration = 30;

  // ---------------------------------------------------------------
  // Storage Keys
  // ---------------------------------------------------------------
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String bookmarksKey = 'bookmarks';

  // ---------------------------------------------------------------
  // Feature Flags
  // ---------------------------------------------------------------
  static const bool enableDarkMode = true;
  static const bool enableNotifications = true;
  static const bool enableOfflineMode = false;
  static const bool enableSadaqah = true;
  static const bool enableLiveStreams = true;
}

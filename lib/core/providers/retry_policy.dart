import 'package:dio/dio.dart';

/// App-wide retry policy for Riverpod providers.
///
/// Riverpod 3 retries a failing provider up to ten times by default, with
/// delays growing to 6.4 s, and reports "loading" throughout. Combined with
/// network timeouts, an offline user watched a spinner for minutes instead of
/// seeing the offline message and its Retry button.
///
/// Policy: retry a dropped connection once, after a second; surface every
/// other failure immediately. Screens offer their own Retry.
Duration? appRetryPolicy(int retryCount, Object error) {
  if (retryCount >= 1) return null;
  if (error is DioException &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout)) {
    return const Duration(seconds: 1);
  }
  return null;
}

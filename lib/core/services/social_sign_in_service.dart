import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Outcome of a native social sign-in attempt.
///
/// The native step never throws: every failure is mapped to a
/// [SocialSignInFailure] with a message that is safe to show the user, and the
/// technical detail is logged for diagnosis.
sealed class SocialSignInResult {
  const SocialSignInResult();
}

/// The provider returned a token the backend can verify.
class SocialSignInSuccess extends SocialSignInResult {
  const SocialSignInSuccess({required this.token, this.name});

  /// Google ID token, or Apple identity token (JWT).
  final String token;

  /// Display name. Apple sends it only on the very first authorisation.
  final String? name;
}

/// The user closed the sheet. Not an error: show nothing.
class SocialSignInCancelled extends SocialSignInResult {
  const SocialSignInCancelled();
}

class SocialSignInFailure extends SocialSignInResult {
  const SocialSignInFailure(this.message);

  /// User-facing message.
  final String message;
}

/// Wraps google_sign_in and sign_in_with_apple so screens share one,
/// crash-proof implementation.
class SocialSignInService {
  SocialSignInService._();

  /// iOS OAuth client (CLIENT_ID in ios/Runner/GoogleService-Info.plist).
  ///
  /// Passed explicitly so the Google SDK never starts without a configuration.
  /// Without one, GIDSignIn raises a native NSException that Dart cannot
  /// catch, which crashed the app in App Review (build 1.1.0 (9)).
  static const iosClientId =
      '246875707165-o7ipce8cf6e3t5aih8p99cu4eqp7g50m.apps.googleusercontent.com';

  /// Web OAuth client. Google issues the ID token for this audience, and the
  /// backend verifies the token against it (GOOGLE_CLIENT_IDS).
  static const serverClientId =
      '246875707165-0sbf8f8thrs14b9h73fh2l4lm6g0ecip.apps.googleusercontent.com';

  static const _networkMessage =
      'No internet connection. Please check your connection and try again.';

  static GoogleSignIn _google() => GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: !kIsWeb && (Platform.isIOS || Platform.isMacOS)
        ? iosClientId
        : null,
    serverClientId: serverClientId,
  );

  /// Whether to offer Sign in with Apple on this device.
  static bool get appleSupportedPlatform =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  static Future<SocialSignInResult> google() async {
    try {
      final googleSignIn = _google();
      // Clear any cached session so the account picker always appears. A
      // failure here must not block the sign-in itself.
      try {
        await googleSignIn.signOut();
      } catch (e) {
        _log('google.signOut', e);
      }

      final account = await googleSignIn.signIn();
      if (account == null) return const SocialSignInCancelled();

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        _log('google.idToken', 'signIn succeeded but idToken was null');
        return const SocialSignInFailure(
          'Google did not return your sign-in details. '
          'Please try again, or sign in with email.',
        );
      }
      return SocialSignInSuccess(token: idToken, name: account.displayName);
    } on PlatformException catch (e, st) {
      _log('google', e, st);
      switch (e.code) {
        case GoogleSignIn.kSignInCanceledError:
          return const SocialSignInCancelled();
        case GoogleSignIn.kNetworkError:
          return const SocialSignInFailure(_networkMessage);
        default:
          return const SocialSignInFailure(
            'Google sign-in is unavailable right now. '
            'Please try again, or sign in with email.',
          );
      }
    } catch (e, st) {
      _log('google', e, st);
      return const SocialSignInFailure(
        'Google sign-in is unavailable right now. '
        'Please try again, or sign in with email.',
      );
    }
  }

  static Future<SocialSignInResult> apple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        return const SocialSignInFailure(
          'Sign in with Apple is not available on this device. '
          'Please sign in with email instead.',
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        _log('apple.identityToken', 'credential had no identityToken');
        return const SocialSignInFailure(
          'Apple did not return your sign-in details. Please try again.',
        );
      }

      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

      return SocialSignInSuccess(
        token: identityToken,
        name: name.isEmpty ? null : name,
      );
    } on SignInWithAppleAuthorizationException catch (e, st) {
      _log('apple', '${e.code}: ${e.message}', st);
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return const SocialSignInCancelled();
        case AuthorizationErrorCode.notInteractive:
          return const SocialSignInFailure(
            'Please sign in to your Apple ID in Settings, then try again.',
          );
        default:
          return const SocialSignInFailure(
            'Sign in with Apple could not be completed. '
            'Please try again, or sign in with email.',
          );
      }
    } catch (e, st) {
      _log('apple', e, st);
      return const SocialSignInFailure(
        'Sign in with Apple could not be completed. '
        'Please try again, or sign in with email.',
      );
    }
  }

  static void _log(String step, Object error, [StackTrace? stackTrace]) {
    developer.log(
      'Social sign-in failed at $step',
      name: 'ehsan.auth',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

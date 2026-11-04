# App Review resubmission: 1.1.0 (10)

Build 1.1.0 (9) was rejected under Guidelines 2.1(a) (twice) and 2.3.6. This
note records the cause of each issue, the fix in code, and the steps that have
to be done by hand in Apple's and Google's consoles before uploading build 10.

## 1. Sign in with Apple showed "Apple sign-in failed" (2.1(a))

**Cause.** `ios/Runner/Runner.entitlements` contained the
`com.apple.developer.applesignin` entitlement, but the Xcode project never
referenced it: `CODE_SIGN_ENTITLEMENTS` was missing from every Runner build
configuration. The signed app therefore had no Sign in with Apple capability,
`ASAuthorizationController` failed with error 1000, and the app showed its
generic banner.

**Fixed in code.**
- `project.pbxproj`: `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` on
  Debug, Release and Profile.
- `lib/core/services/social_sign_in_service.dart`: one implementation for the
  login and register screens. It checks `SignInWithApple.isAvailable()`, maps
  each `AuthorizationErrorCode` to a specific message, treats cancel as a
  no-op, and logs details under `ehsan.auth`.
- Backend (`SocialAuthController`): verifies `aud` against the bundle ID,
  caches Apple's keys, tolerates 60 s of clock skew, and never returns raw
  exception text to the app.

**By hand, before archiving:**
1. developer.apple.com → Identifiers → `com.ehsanpathways.ehsanPathways`:
   enable **Sign in with Apple** and **Associated Domains** (the entitlements
   file declares both; signing fails if the App ID lacks either).
2. Regenerate the App Store provisioning profile (or let Xcode's automatic
   signing do it) so it carries both capabilities.
3. In Xcode → Runner → Signing & Capabilities, confirm both capabilities appear
   without warnings.

No Team ID, Key ID or `.p8` key is needed for native sign-in: the backend checks
the identity token with Apple's public keys. Those credentials are only needed
for web Sign in with Apple or for revoking Apple tokens server-side.

## 2. Google sign-in crashed the app (2.1(a))

**Cause.** `GoogleService-Info.plist` sat in `ios/Runner/` but was not part of
the Xcode project, so it never reached the app bundle, and `Info.plist` had no
`GIDClientID`. With no configuration, the Google SDK raises a native
`NSException`, which Dart cannot catch, and the app terminates.

**Fixed in code.**
- `Info.plist`: `GIDClientID` (iOS client) and `GIDServerClientID` (web client).
  The reversed client ID URL scheme was already present.
- `project.pbxproj`: `GoogleService-Info.plist` added to the Runner target's
  Copy Bundle Resources.
- `GoogleSignIn(...)` now also receives `clientId` explicitly on iOS.
- Every platform exception is caught and shown as a friendly message; a null
  `idToken` is handled; cancel is a no-op.
- The register screen had no `serverClientId`, so it could never obtain an ID
  token on Android. Both screens now share the service.
- Backend verifies `aud` (web, iOS and Android client IDs) and `iss`.

**By hand:** in Google Cloud Console → Credentials, confirm the iOS OAuth client
`246875707165-o7ipce8c…` has bundle ID `com.ehsanpathways.ehsanPathways`.

## 3. In-App Controls listed but not found (2.3.6)

The app has no parental controls or age-assurance feature. Correct the metadata:

1. App Store Connect → the app → **App Information** → **Age Rating** → Edit.
2. Under **In-App Controls**, set **Parental Controls** to **None** and **Age
   Assurance** to **None**.
3. Review the remaining answers (the content is educational, with no
   user-generated mature content), save, and check the resulting rating.

## 4. iPad Air 11-inch (M3)

- The login and register forms are capped at 480 pt and centred, so fields and
  buttons no longer stretch across the iPad screen.
- Rows that overflowed at narrow widths or large text sizes now wrap or
  truncate.
- `test/auth/auth_screens_layout_test.dart` renders both screens at iPhone SE,
  iPhone 16 Pro Max and iPad Air 11" (portrait and landscape) and fails on any
  layout overflow.

## 5. Found while fixing: account deletion (5.1.1(v))

The app let people create accounts but offered no way to delete one, which is
a common rejection reason. Profile → **Delete Account** now confirms and calls
`DELETE /api/v1/user/account`. The backend previously required a password, which
Apple and Google users never have. It now also accepts an explicit
confirmation, and it scrubs the email and social IDs so the person can sign up
again later.

## 6. Found while fixing: auto-login never ran

`AuthNotifier.build()` wrote to `state` before returning, which Riverpod 3
rejects with "Tried to read the state of an uninitialized provider". Saved
sessions were never restored at launch. Auto-login now runs after `build()`.

## Suggested App Review notes

> Thank you for the feedback. In 1.1.0 (10):
> - Sign in with Apple: the Sign in with Apple entitlement was not applied to the
>   signed build. It is now enabled and verified on iPhone and iPad.
> - Google Sign-In: the crash came from a missing Google SDK configuration in the
>   app bundle. That configuration is now included, and sign-in errors are shown
>   without closing the app.
> - Age Rating: the app has no parental controls or age assurance. We corrected
>   the In-App Controls answers to "None".
> - Account deletion is available under Profile → Delete Account.
>
> Demo account: <email> / <password>

## Before uploading build 10

- [ ] App ID capabilities enabled and profile regenerated (section 1)
- [ ] Age Rating In-App Controls set to None (section 3)
- [ ] Backend deployed, then `php artisan config:clear && php artisan migrate`
- [ ] On a real iPhone **and** iPad: Apple sign-in, Google sign-in, cancel each,
      airplane-mode error message, delete account, sign in again
- [ ] Demo account credentials entered in App Review Information

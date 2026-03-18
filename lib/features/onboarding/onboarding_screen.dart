import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:ehsan_pathways/core/providers/onboarding_provider.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Onboarding page data
// ---------------------------------------------------------------------------

class _OnboardingPage {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.menu_book_rounded,
    iconBg: Color(0xFFDCFCE7),
    iconColor: Color(0xFF16A34A),
    title: 'Seek Knowledge',
    subtitle:
        'Access thousands of Islamic videos, articles, and podcasts — completely free, for everyone.',
    gradient: [Color(0xFF052E16), Color(0xFF166534), Color(0xFF16A34A)],
  ),
  _OnboardingPage(
    icon: Icons.headphones_rounded,
    iconBg: Color(0xFFEDE9FE),
    iconColor: Color(0xFF7C3AED),
    title: 'Watch, Listen, Read',
    subtitle:
        'Videos from trusted scholars, podcasts to listen on the go, and in-depth articles to deepen your understanding.',
    gradient: [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF6D28D9)],
  ),
  _OnboardingPage(
    icon: Icons.route_rounded,
    iconBg: Color(0xFFFEF3C7),
    iconColor: Color(0xFFD97706),
    title: 'Your Learning Path',
    subtitle:
        'Follow curated learning pathways designed by scholars to guide you step by step on your Islamic journey.',
    gradient: [Color(0xFF1C1917), Color(0xFF78350F), Color(0xFFD97706)],
  ),
  _OnboardingPage(
    icon: Icons.people_alt_rounded,
    iconBg: Color(0xFFDCFCE7),
    iconColor: Color(0xFF16A34A),
    title: 'Join the Ummah',
    subtitle:
        'Create an account to save bookmarks, track progress, and get personalised recommendations.',
    gradient: [Color(0xFF052E16), Color(0xFF166534), Color(0xFF16A34A)],
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await markOnboardingSeen();
    if (mounted) context.go('/');
  }

  Future<void> _skip() async {
    await markOnboardingSeen();
    if (mounted) context.go('/');
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return; // user cancelled
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Could not retrieve Google ID token');

      await ref.read(authProvider.notifier).socialLogin(
            provider: 'google',
            token: idToken,
          );

      await markOnboardingSeen();
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('Could not retrieve Apple identity token');

      // Build display name from Apple credential (only present on first sign-in)
      final givenName = credential.givenName ?? '';
      final familyName = credential.familyName ?? '';
      final name = [givenName, familyName].where((s) => s.isNotEmpty).join(' ');

      await ref.read(authProvider.notifier).socialLogin(
            provider: 'apple',
            token: identityToken,
            name: name.isEmpty ? null : name,
          );

      await markOnboardingSeen();
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple sign-in failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: page.gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // -- Skip button -----------------------------------------------
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                  child: GestureDetector(
                    onTap: _skip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // -- Pages -------------------------------------------------------
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) =>
                      _PageContent(page: _pages[index]),
                ),
              ),

              // -- Dots -------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // -- Bottom actions --------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: isLast
                    ? _LastPageActions(
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        onEmail: _finish,
                        onGoogle: _signInWithGoogle,
                        onApple: _signInWithApple,
                      )
                    : _NextButton(onTap: _nextPage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page content (icon + title + subtitle)
// ---------------------------------------------------------------------------

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: page.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(page.icon, size: 44, color: page.iconColor),
              ),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next button (pages 1-3)
// ---------------------------------------------------------------------------

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF052E16),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Color(0xFF16A34A), size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Last page: sign-in actions
// ---------------------------------------------------------------------------

class _LastPageActions extends StatelessWidget {
  const _LastPageActions({
    required this.isLoading,
    this.errorMessage,
    required this.onEmail,
    required this.onGoogle,
    required this.onApple,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onEmail;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Error message
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.red.shade200),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Google button
        _SocialButton(
          onTap: isLoading ? null : onGoogle,
          icon: _GoogleIcon(),
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          textColor: const Color(0xFF1F2937),
        ),

        const SizedBox(height: 12),

        // Apple button (iOS/macOS only)
        if (Platform.isIOS || Platform.isMacOS)
          _SocialButton(
            onTap: isLoading ? null : onApple,
            icon: const Icon(Icons.apple, color: Colors.white, size: 22),
            label: 'Sign in with Apple',
            backgroundColor: Colors.black,
            textColor: Colors.white,
          ),

        if (Platform.isIOS || Platform.isMacOS) const SizedBox(height: 12),

        // Divider
        Row(
          children: [
            Expanded(
                child:
                    Divider(color: Colors.white.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
                child:
                    Divider(color: Colors.white.withValues(alpha: 0.3))),
          ],
        ),

        const SizedBox(height: 12),

        // Email button
        _SocialButton(
          onTap: isLoading ? null : onEmail,
          icon: const Icon(Icons.email_outlined,
              color: Colors.white, size: 22),
          label: 'Continue with Email',
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          textColor: Colors.white,
          borderColor: Colors.white.withValues(alpha: 0.3),
        ),

        const SizedBox(height: 16),

        // Loading indicator
        if (isLoading)
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          ),

        const SizedBox(height: 8),

        // Terms text
        Text(
          'By continuing, you agree to our Terms & Privacy Policy',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    this.onTap,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
          boxShadow: backgroundColor == Colors.white
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, height: 24, child: icon),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google "G" icon (drawn manually — no asset needed)
// ---------------------------------------------------------------------------

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GooglePainter(),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Blue
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.25,
      1.6,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );
    // Red
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.35,
      1.15,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );
    // Yellow
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      2.5,
      0.8,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );
    // Green
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.3,
      0.62,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt,
    );
    // Horizontal bar (blue)
    final barY = cy + r * 0.07;
    canvas.drawLine(
      Offset(cx, barY),
      Offset(cx + r * 0.92, barY),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

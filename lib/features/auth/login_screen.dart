import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/services/social_sign_in_service.dart';
import 'package:ehsan_pathways/features/auth/register_screen.dart';
import 'package:ehsan_pathways/config/theme.dart';

/// A polished login screen with an Islamic-inspired gradient header,
/// clean input fields, and full Riverpod auth integration.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  String? _googleError;
  bool _isAppleLoading = false;
  String? _appleError;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // -- Colours ----------------------------------------------------------------
  static const _green500 = AppColors.emerald700;
  static const _green900 = AppColors.emerald900;
  static const _gold = AppColors.gold;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _googleError = null;
      _appleError = null;
    });
    final result = await SocialSignInService.google();
    await _completeSocialSignIn(
      'google',
      result,
      onError: (message) => _googleError = message,
    );
    if (mounted) setState(() => _isGoogleLoading = false);
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isAppleLoading = true;
      _appleError = null;
      _googleError = null;
    });
    final result = await SocialSignInService.apple();
    await _completeSocialSignIn(
      'apple',
      result,
      onError: (message) => _appleError = message,
    );
    if (mounted) setState(() => _isAppleLoading = false);
  }

  /// Exchanges the provider token with the backend. Navigation on success is
  /// handled by the authProvider listener in build().
  Future<void> _completeSocialSignIn(
    String provider,
    SocialSignInResult result, {
    required void Function(String message) onError,
  }) async {
    switch (result) {
      case SocialSignInCancelled():
        return;
      case SocialSignInFailure(:final message):
        if (mounted) setState(() => onError(message));
        return;
      case SocialSignInSuccess(:final token, :final name):
        await ref
            .read(authProvider.notifier)
            .socialLogin(provider: provider, token: token, name: name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final size = MediaQuery.sizeOf(context);

    // Single navigation point: all login paths go through here
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && mounted) {
        context.go('/');
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ----------------------------------------------------------------
                // Gradient header with geometric pattern feel
                // ----------------------------------------------------------------
                _GradientHeader(
                  height: size.height * 0.38,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        // Decorative icon ring
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white38, width: 2),
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ehsan Pathways',
                          style: GoogleFonts.lora(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Journey to Islamic Knowledge',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ----------------------------------------------------------------
                // Form body
                // ----------------------------------------------------------------
                Padding(
                  // Keep the form a readable width on iPad and in landscape.
                  padding: EdgeInsets.symmetric(
                    horizontal: _formGutter(size.width),
                    vertical: 28,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.lora(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: _green900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to continue your learning journey',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // -- Error card -----------------------------------------
                          if (authState.errorMessage != null) ...[
                            _ErrorCard(message: authState.errorMessage!),
                            const SizedBox(height: 16),
                          ],

                          // -- Email field ----------------------------------------
                          _StyledField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // -- Password field -------------------------------------
                          _StyledField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade500,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // -- Forgot password ------------------------------------
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Navigate to forgot-password screen
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: _green500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // -- Login button ---------------------------------------
                          _GradientButton(
                            label: 'Sign In',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _submit,
                          ),

                          const SizedBox(height: 20),

                          // -- Social divider ------------------------------------
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // -- Google error --------------------------------------
                          if (_googleError != null) ...[
                            _ErrorCard(message: _googleError!),
                            const SizedBox(height: 12),
                          ],

                          // -- Google Sign In button -----------------------------
                          _GoogleButton(
                            isLoading: _isGoogleLoading,
                            onPressed:
                                (isLoading ||
                                    _isGoogleLoading ||
                                    _isAppleLoading)
                                ? null
                                : _signInWithGoogle,
                          ),

                          const SizedBox(height: 12),

                          // -- Apple error ---------------------------------------
                          if (_appleError != null) ...[
                            _ErrorCard(message: _appleError!),
                            const SizedBox(height: 12),
                          ],

                          // -- Sign in with Apple button -------------------------
                          if (SocialSignInService.appleSupportedPlatform)
                            _AppleButton(
                              isLoading: _isAppleLoading,
                              onPressed:
                                  (isLoading ||
                                      _isGoogleLoading ||
                                      _isAppleLoading)
                                  ? null
                                  : _signInWithApple,
                            ),

                          const SizedBox(height: 24),

                          // -- Register link --------------------------------------
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                child: Text(
                                  'Register',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _green500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // -- Divider ornament -----------------------------------
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: _gold.withValues(alpha: 0.7),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'All content is completely FREE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Full-screen loading overlay shown during any authentication call
          if (isLoading || _isGoogleLoading || _isAppleLoading)
            _AuthLoadingOverlay(
              message: _isGoogleLoading
                  ? 'Signing in with Google…'
                  : _isAppleLoading
                  ? 'Signing in with Apple…'
                  : 'Signing in…',
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// PRIVATE REUSABLE WIDGETS
// =============================================================================

/// Curved gradient header with decorative circles (geometric pattern feel).
/// Horizontal padding that centres the auth form at no more than
/// [_maxFormWidth] wide, with at least 28pt gutters on phones.
const double _maxFormWidth = 480;
double _formGutter(double screenWidth) =>
    math.max(28, (screenWidth - _maxFormWidth) / 2);

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvedClipper(),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.emerald700, AppColors.emerald600, AppColors.emerald900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles (Islamic geometric hint)
            Positioned(
              top: -30,
              right: -30,
              child: _decorativeCircle(
                140,
                Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Positioned(
              top: 60,
              left: -50,
              child: _decorativeCircle(
                120,
                Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 40,
              child: _decorativeCircle(
                80,
                Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              top: 20,
              left: 30,
              child: _decorativeCircle(
                50,
                Colors.white.withValues(alpha: 0.03),
              ),
            ),
            // Gold accent circle
            Positioned(
              bottom: 60,
              left: -20,
              child: _decorativeCircle(
                60,
                AppColors.gold.withValues(alpha: 0.12),
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    );
  }

  static Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 50)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + 20,
        size.width,
        size.height - 50,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A rounded text field with prefix icon and subtle shadow.
class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey.shade900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.emerald700),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.emerald700,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gradient login/register button with loading spinner.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.emerald700, AppColors.emerald800],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald700.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Small red error card.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerOnDark),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.dangerOnDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sign in with Apple button.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.isLoading, this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.black,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apple, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Sign in with Apple',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Google Sign In button.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.grey.shade600,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    height: 22,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 26,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Continue with Google',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading overlay — full-screen translucent during auth
// ---------------------------------------------------------------------------
class _AuthLoadingOverlay extends StatelessWidget {
  final String message;
  const _AuthLoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.emerald700),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please wait…',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

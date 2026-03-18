import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

/// Size presets for [ScholarAvatar].
enum ScholarAvatarSize {
  small(32),
  medium(48),
  large(80);

  const ScholarAvatarSize(this.diameter);

  /// The diameter of the avatar in logical pixels.
  final double diameter;
}

/// A beautiful circular scholar avatar with cached network image support,
/// placeholder initials, an optional verified badge, and an elegant
/// primary-colour border ring.
class ScholarAvatar extends StatelessWidget {
  const ScholarAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = ScholarAvatarSize.medium,
    this.isVerified = false,
    this.onTap,
    this.borderColor,
  });

  /// Scholar's display name – used to derive placeholder initials.
  final String name;

  /// Network URL for the scholar's photo.
  final String? imageUrl;

  /// Visual size variant.
  final ScholarAvatarSize size;

  /// Whether to show a verified (green checkmark) badge.
  final bool isVerified;

  /// Called when the avatar is tapped.
  final VoidCallback? onTap;

  /// Override for the border ring colour. Falls back to primary green.
  final Color? borderColor;

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Extract up to two initials from the scholar name.
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  double get _borderWidth {
    switch (size) {
      case ScholarAvatarSize.small:
        return 2.0;
      case ScholarAvatarSize.medium:
        return 2.5;
      case ScholarAvatarSize.large:
        return 3.0;
    }
  }

  double get _fontSize {
    switch (size) {
      case ScholarAvatarSize.small:
        return 12;
      case ScholarAvatarSize.medium:
        return 17;
      case ScholarAvatarSize.large:
        return 28;
    }
  }

  double get _badgeSize {
    switch (size) {
      case ScholarAvatarSize.small:
        return 14;
      case ScholarAvatarSize.medium:
        return 18;
      case ScholarAvatarSize.large:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF16A34A);
    final Color ring = borderColor ?? primaryGreen;

    final double d = size.diameter;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: d + _borderWidth * 2 + (isVerified ? _badgeSize / 2 : 0),
        height: d + _borderWidth * 2 + (isVerified ? _badgeSize / 2 : 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // -- Border ring -----------------------------------------------
            Container(
              width: d + _borderWidth * 2,
              height: d + _borderWidth * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ring,
                    ring.withValues(alpha: 0.6),
                  ],
                ),
              ),
              padding: EdgeInsets.all(_borderWidth),
              child: ClipOval(
                child: _buildImage(d),
              ),
            ),

            // -- Verified badge --------------------------------------------
            if (isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: _badgeSize * 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double diameter) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (_, __) => _initialsPlaceholder(diameter),
        errorWidget: (_, __, ___) => _initialsPlaceholder(diameter),
      );
    }

    return _initialsPlaceholder(diameter);
  }

  Widget _initialsPlaceholder(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16A34A),
            Color(0xFF059669),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.inter(
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

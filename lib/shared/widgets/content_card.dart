import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// The type of content a card represents.
enum ContentType { video, article, podcast, document, khutbah }

/// A gorgeous, reusable content card for videos, articles, podcasts,
/// documents, and khutbahs. Features smooth tap animation, shimmer image
/// loading, and colour-coded type badges.
class ContentCard extends StatefulWidget {
  const ContentCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.contentType,
    this.trailingInfo,
    this.trailingIcon,
    this.onTap,
    this.height,
  });

  /// Primary title (content name).
  final String title;

  /// Secondary line, typically the scholar name.
  final String? subtitle;

  /// Network image URL for the thumbnail.
  final String? imageUrl;

  /// Determines the badge colour shown on the card.
  final ContentType? contentType;

  /// Trailing metadata string (e.g. "12 min", "24 pages").
  final String? trailingInfo;

  /// Optional icon shown next to [trailingInfo].
  final IconData? trailingIcon;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Optional fixed height for the image area.
  final double? height;

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -- Badge colours keyed by content type ----------------------------------

  static const Map<ContentType, Color> _badgeColors = {
    ContentType.video: Color(0xFF3B82F6), // blue
    ContentType.article: Color(0xFF10B981), // emerald
    ContentType.podcast: Color(0xFF8B5CF6), // purple
    ContentType.document: Color(0xFFEF4444), // red
    ContentType.khutbah: Color(0xFFF59E0B), // amber
  };

  static const Map<ContentType, IconData> _badgeIcons = {
    ContentType.video: Icons.play_circle_outline_rounded,
    ContentType.article: Icons.article_outlined,
    ContentType.podcast: Icons.headphones_rounded,
    ContentType.document: Icons.description_outlined,
    ContentType.khutbah: Icons.mosque_rounded,
  };

  static const Map<ContentType, String> _badgeLabels = {
    ContentType.video: 'Video',
    ContentType.article: 'Article',
    ContentType.podcast: 'Podcast',
    ContentType.document: 'Document',
    ContentType.khutbah: 'Khutbah',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // -- Thumbnail ------------------------------------------------
              if (widget.imageUrl != null)
                SizedBox(
                  height: widget.height ?? 180,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE5E7EB),
                          highlightColor: isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFF3F4F6),
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF3F4F6),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: isDark
                                ? Colors.white38
                                : Colors.black26,
                          ),
                        ),
                      ),

                      // Subtle bottom gradient for legibility
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Type badge
                      if (widget.contentType != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _TypeBadge(
                            type: widget.contentType!,
                            color: _badgeColors[widget.contentType]!,
                            icon: _badgeIcons[widget.contentType]!,
                            label: _badgeLabels[widget.contentType]!,
                          ),
                        ),

                      // Trailing info on image
                      if (widget.trailingInfo != null)
                        Positioned(
                          bottom: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.trailingIcon != null) ...[
                                  Icon(
                                    widget.trailingIcon,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  widget.trailingInfo!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // -- Text content ---------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge (when there is no image)
                    if (widget.imageUrl == null && widget.contentType != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TypeBadge(
                          type: widget.contentType!,
                          color: _badgeColors[widget.contentType]!,
                          icon: _badgeIcons[widget.contentType]!,
                          label: _badgeLabels[widget.contentType]!,
                        ),
                      ),

                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),

                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],

                    // Trailing info (when there is no image)
                    if (widget.imageUrl == null && widget.trailingInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            if (widget.trailingIcon != null) ...[
                              Icon(
                                widget.trailingIcon,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              widget.trailingInfo!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helper – the coloured type badge pill
// ---------------------------------------------------------------------------

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.type,
    required this.color,
    required this.icon,
    required this.label,
  });

  final ContentType type;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

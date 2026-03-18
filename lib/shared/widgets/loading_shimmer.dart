import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ---------------------------------------------------------------------------
// Core shimmer building block
// ---------------------------------------------------------------------------

/// A single rounded shimmer box used as a loading placeholder.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer wrapper that provides the silver gradient animation
// ---------------------------------------------------------------------------

/// Wraps [child] in the standard shimmer effect matching the app's style.
class ShimmerWrap extends StatelessWidget {
  const ShimmerWrap({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor:
          isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
      highlightColor:
          isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF9FAFB),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerCard – matches ContentCard layout
// ---------------------------------------------------------------------------

/// A shimmer placeholder that mirrors the [ContentCard] layout so the
/// transition from loading to loaded feels seamless.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.imageHeight = 180,
  });

  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image area
            ShimmerBox(
              width: double.infinity,
              height: imageHeight,
              borderRadius: 16,
            ),
            const SizedBox(height: 14),

            // Title line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 160, height: 16),
                  const SizedBox(height: 10),
                  // Subtitle
                  const ShimmerBox(width: 120, height: 12),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerListTile – matches a horizontal list-tile style row
// ---------------------------------------------------------------------------

/// A shimmer placeholder shaped like a list tile (leading circle + text lines).
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar circle
            const ShimmerBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 14),
            // Text lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerList – a vertical list of shimmer tiles
// ---------------------------------------------------------------------------

/// Renders [itemCount] shimmer list-tile placeholders in a [Column].
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => const ShimmerListTile(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerGrid – a grid of shimmer cards
// ---------------------------------------------------------------------------

/// Renders a grid of [ShimmerCard] placeholders.
class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
    this.imageHeight = 140,
    this.childAspectRatio = 0.78,
    this.padding = const EdgeInsets.all(16),
  });

  final int crossAxisCount;
  final int itemCount;
  final double imageHeight;
  final double childAspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => ShimmerCard(imageHeight: imageHeight),
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerHorizontalList – horizontal scrolling shimmer cards
// ---------------------------------------------------------------------------

/// A horizontal list of shimmer card placeholders, perfect for carousels.
class ShimmerHorizontalList extends StatelessWidget {
  const ShimmerHorizontalList({
    super.key,
    this.itemCount = 4,
    this.cardWidth = 220,
    this.imageHeight = 130,
    this.height = 230,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final int itemCount;
  final double cardWidth;
  final double imageHeight;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => SizedBox(
          width: cardWidth,
          child: ShimmerCard(imageHeight: imageHeight),
        ),
      ),
    );
  }
}

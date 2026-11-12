import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ehsan_pathways/features/pathways/pathway_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/config/theme.dart';

const Color _green = AppColors.emerald700;
const Color _gold = AppColors.gold;

class PathwaysScreen extends ConsumerWidget {
  const PathwaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pathwaysAsync = ref.watch(pathwayListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.slate : AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // -- Header --
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.slate : Colors.white,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.emerald950,
                      AppColors.emerald900,
                      AppColors.emerald700,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    // Scales down instead of overflowing when the phone's
                    // text size is set larger than default.
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_rounded,
                                  size: 14, color: _gold),
                              const SizedBox(width: 6),
                              Text(
                                'Learning Pathways',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Structured Journeys\nto Knowledge',
                          style: GoogleFonts.lora(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // -- Content --
          pathwaysAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(itemCount: 4),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Failed to load pathways',
                subtitle: error.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(pathwayListProvider),
              ),
            ),
            data: (pathways) {
              if (pathways.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.route_outlined,
                    title: 'No pathways available',
                    subtitle:
                        'Learning pathways are coming soon, inshaAllah!',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList.separated(
                  itemCount: pathways.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _PathwayCard(
                      pathway: pathways[index],
                      isDark: isDark,
                      onTap: () =>
                          context.push('/pathways/${pathways[index].slug}'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pathway Card
// ---------------------------------------------------------------------------

class _PathwayCard extends StatelessWidget {
  const _PathwayCard({
    required this.pathway,
    required this.isDark,
    required this.onTap,
  });

  final Pathway pathway;
  final bool isDark;
  final VoidCallback onTap;

  Color get _levelColor {
    switch (pathway.difficultyLevel?.toLowerCase()) {
      case 'beginner':
        return AppColors.emerald500;
      case 'intermediate':
        return AppColors.sapphire;
      case 'advanced':
        return AppColors.amethyst;
      default:
        return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.slateCard : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / gradient header
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _levelColor.withValues(alpha: 0.8),
                    _levelColor.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (pathway.thumbnailUrl != null)
                    CachedNetworkImage(
                      imageUrl: pathway.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),

                  // Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),

                  // Level badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _levelColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pathway.levelLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Items count
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${pathway.totalItems} items',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrow
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 18, color: _levelColor),
                    ),
                  ),
                ],
              ),
            ),

            // Text content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pathway.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? Colors.white : AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                  if (pathway.description != null &&
                      pathway.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      pathway.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.onDarkMuted
                            : AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (pathway.hoursLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.onDarkSubtle
                                : AppColors.subtle),
                        const SizedBox(width: 4),
                        Text(
                          '~${pathway.hoursLabel} estimated',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.onDarkSubtle
                                : AppColors.subtle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

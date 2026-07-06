import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/features/home/home_provider.dart' show dioProvider;
import 'package:ehsan_pathways/features/videos/video_provider.dart';
import 'package:ehsan_pathways/shared/widgets/content_card.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

const _green = Color(0xFF16A34A);

/// Fetches videos filtered by a category slug. Isolated from the Videos tab's
/// shared list state so a category view can't clobber the main feed.
final categoryVideosProvider =
    FutureProvider.autoDispose.family<PaginatedVideos, String>((ref, slug) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/videos', queryParameters: {
    'category': slug,
    'per_page': 30,
  });
  return PaginatedVideos.fromJson(response.data as Map<String, dynamic>);
});

/// Shows all videos within a single category, reached by tapping a topic chip
/// on the Home screen.
class CategoryVideosScreen extends ConsumerWidget {
  const CategoryVideosScreen({
    super.key,
    required this.slug,
    required this.name,
  });

  final String slug;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(categoryVideosProvider(slug));

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(
          name,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: () async => ref.invalidate(categoryVideosProvider(slug)),
        child: async.when(
          loading: () => GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => const ShimmerCard(imageHeight: 120),
          ),
          error: (_, __) => ListView(
            children: [
              const SizedBox(height: 120),
              EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Something went wrong',
                subtitle: 'Please check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(categoryVideosProvider(slug)),
                iconColor: Colors.red.shade400,
              ),
            ],
          ),
          data: (paginated) {
            if (paginated.data.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'No videos yet',
                    subtitle:
                        'There is no content in this topic yet. Check back soon.',
                  ),
                ],
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              itemCount: paginated.data.length,
              itemBuilder: (context, i) {
                final video = paginated.data[i];
                return ContentCard(
                  title: video.title,
                  subtitle: video.scholar?.name,
                  imageUrl: video.thumbnailUrl,
                  contentType: ContentType.video,
                  trailingInfo: video.durationFormatted,
                  trailingIcon: Icons.access_time_rounded,
                  height: 120,
                  onTap: () => context.push('/videos/${video.uuid}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

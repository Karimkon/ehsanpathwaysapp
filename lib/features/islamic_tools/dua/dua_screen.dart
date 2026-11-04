import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';

class DuaScreen extends ConsumerWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(duaCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.accentGold,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duas', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'أدعية من القرآن والسنة',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(duaCategoriesProvider),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) =>
            _buildError(() => ref.invalidate(duaCategoriesProvider)),
        data: (categories) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) =>
              _CategoryCard(category: categories[index]),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.sand,
      highlightColor: AppColors.cream,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.sandDeep,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load duas',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final DuaCategory category;
  const _CategoryCard({required this.category});

  Color get _color {
    switch (category.color) {
      case 'green':
        return AppTheme.primaryGreen;
      case 'blue':
        return AppColors.sapphire;
      case 'amber':
        return AppTheme.accentGold;
      case 'purple':
        return AppColors.amethyst;
      case 'red':
        return AppColors.danger;
      case 'teal':
        return AppColors.teal;
      case 'indigo':
        return AppColors.amethyst;
      case 'rose':
        return AppColors.ruby;
      case 'cyan':
        return AppColors.teal;
      case 'orange':
        return AppColors.goldDeep;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/islamic-tools/dua/${category.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sand),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${category.count} duas',
                style: const TextStyle(fontSize: 11, color: AppColors.subtle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

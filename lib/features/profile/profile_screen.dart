import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/providers/theme_provider.dart';
import 'package:ehsan_pathways/shared/widgets/scholar_avatar.dart';
import 'package:ehsan_pathways/core/models/user_stats_model.dart';
import 'package:ehsan_pathways/config/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _green = AppColors.emerald700;
  static const _greenDark = AppColors.emerald800;
  static const _gold = AppColors.gold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.slate
          : AppColors.cream,
      body:
          authState.status == AuthStatus.authenticated && authState.user != null
          ? _AuthenticatedProfile(user: authState.user!, isDark: isDark)
          : _UnauthenticatedProfile(isDark: isDark),
    );
  }
}

// ---------------------------------------------------------------------------
// Unauthenticated view - beautiful login prompt
// ---------------------------------------------------------------------------

class _UnauthenticatedProfile extends StatelessWidget {
  const _UnauthenticatedProfile({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Decorative icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ProfileScreen._green.withValues(alpha: 0.12),
                    ProfileScreen._green.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ProfileScreen._green.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: ProfileScreen._green.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Welcome to Ehsan Pathways',
              style: GoogleFonts.lora(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Sign in to track your learning progress, bookmark content, and personalize your experience.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.onDarkMuted
                    : AppColors.muted,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32),

            // Sign in button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [ProfileScreen._green, ProfileScreen._greenDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ProfileScreen._green.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/login'),
                    child: Center(
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => context.push('/register'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ProfileScreen._green.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Create Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ProfileScreen._green,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Ornament
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: ProfileScreen._gold.withValues(alpha: 0.7),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'All content is completely FREE\nfor the sake of Allah',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Authenticated view - profile header + settings
// ---------------------------------------------------------------------------

class _AuthenticatedProfile extends ConsumerWidget {
  const _AuthenticatedProfile({required this.user, required this.isDark});

  final dynamic user;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    return CustomScrollView(
      slivers: [
        // -- Gradient header with profile info -------------------------
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ProfileScreen._green,
                  AppColors.emerald600,
                  ProfileScreen._greenDark,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  children: [
                    // Title row
                    Row(
                      children: [
                        Text(
                          'Profile',
                          style: GoogleFonts.lora(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Avatar + info
                    Row(
                      children: [
                        ScholarAvatar(
                          name: user.name,
                          imageUrl: user.avatar,
                          size: ScholarAvatarSize.large,
                          borderColor: Colors.white,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Learning stats strip
                    _buildStatsRow(statsAsync),
                  ],
                ),
              ),
            ),
          ),
        ),

        // -- Your Library section ------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Your Library',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),

                const SizedBox(height: 12),

                // 2x2 grid of quick-access tiles
                Row(
                  children: [
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.bookmark_rounded,
                        label: 'Bookmarks',
                        color: AppColors.sapphire,
                        isDark: isDark,
                        onTap: () => context.push('/bookmarks'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.note_alt_rounded,
                        label: 'Notes',
                        color: AppColors.emerald500,
                        isDark: isDark,
                        onTap: () => context.push('/notes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.route_rounded,
                        label: 'Pathways',
                        color: AppColors.amethyst,
                        isDark: isDark,
                        onTap: () => context.push('/pathways'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.history_rounded,
                        label: 'Watch History',
                        color: ProfileScreen._gold,
                        isDark: isDark,
                        onTap: () => context.push('/history'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.volunteer_activism_rounded,
                        label: 'My Impact',
                        color: AppColors.emerald600,
                        isDark: isDark,
                        onTap: () => context.push('/impact'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessTile(
                        icon: Icons.forum_rounded,
                        label: 'Ask Ehsan',
                        color: AppColors.sapphire,
                        isDark: isDark,
                        onTap: () => context.push('/ask'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // -- Settings list -------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Settings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),

                const SizedBox(height: 12),

                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded,
                      iconColor: AppColors.amethyst,
                      title: 'Dark Mode',
                      isDark: isDark,
                      trailing: Switch.adaptive(
                        value: isDark,
                        activeTrackColor: ProfileScreen._green,
                        onChanged: (val) =>
                            ref.read(themeModeProvider.notifier).setDark(val),
                      ),
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.sapphire,
                      title: 'Language',
                      subtitle: 'English',
                      isDark: isDark,
                      onTap: () {},
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      iconColor: ProfileScreen._gold,
                      title: 'Notifications & Prayer Times',
                      isDark: isDark,
                      onTap: () => context.push('/notifications'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _SettingsCard(
                  isDark: isDark,
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.muted,
                      title: 'About',
                      isDark: isDark,
                      onTap: () {},
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.danger,
                      title: 'Sign Out',
                      titleColor: AppColors.danger,
                      isDark: isDark,
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                    _divider(isDark),
                    _SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      iconColor: AppColors.danger,
                      title: 'Delete Account',
                      titleColor: AppColors.danger,
                      isDark: isDark,
                      onTap: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Center(
                  child: Text(
                    'Ehsan Pathways v1.1.0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 56,
    color: isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppColors.creamDeep,
  );

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This permanently deletes your account, bookmarks, notes and '
          'progress. This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(authProvider.notifier).deleteAccount();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Your account has been deleted.')),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings card container
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick access tile (2x2 grid)
// ---------------------------------------------------------------------------

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.slateCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings tile
// ---------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.isDark,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          titleColor ??
                          (isDark ? Colors.white : AppColors.ink),
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.onDarkMuted
                              : AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats strip inside gradient header
// ---------------------------------------------------------------------------

extension on _AuthenticatedProfile {
  Widget _buildStatsRow(AsyncValue<UserStatsModel> statsAsync) {
    final stats = statsAsync.asData?.value;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatItem(value: _fmt(stats?.videosWatched), label: 'Watched'),
          _vDiv(),
          _StatItem(value: _fmt(stats?.bookmarks), label: 'Saved'),
          _vDiv(),
          _StatItem(value: _fmt(stats?.notes), label: 'Notes'),
          _vDiv(),
          _StatItem(value: _fmt(stats?.pathwaysEnrolled), label: 'Paths'),
        ],
      ),
    );
  }

  Widget _vDiv() => Container(width: 1, height: 32, color: Colors.white24);

  String _fmt(int? v) => v != null ? '$v' : '—';
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

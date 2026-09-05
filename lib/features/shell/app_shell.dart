import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';

/// The bottom navigation.
///
/// The five destinations are the things a Muslim opens the app to do daily —
/// Quran and the library sit here rather than three taps down inside a tools
/// menu, which is where they used to live.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_Destination>[
    _Destination(
      icon: Icons.wb_twilight_rounded,
      activeIcon: Icons.wb_twilight_rounded,
      label: 'Today',
    ),
    _Destination(
      icon: Icons.play_circle_outline_rounded,
      activeIcon: Icons.play_circle_rounded,
      label: 'Watch',
    ),
    _Destination(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'Quran',
    ),
    _Destination(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
      label: 'Library',
    ),
    _Destination(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.inkSoft : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.inkLine : AppTheme.sand,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: _destinations[i],
                      isSelected: navigationShell.currentIndex == i,
                      isDark: isDark,
                      onTap: () => navigationShell.goBranch(
                        i,
                        // Tapping the tab you are already on returns to its
                        // root, which is what people expect of a tab bar.
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final _Destination destination;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final active = isDark ? AppTheme.primaryGreenLight : AppTheme.primaryGreen;
    final idle = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;
    final color = isSelected ? active : idle;

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A short bar above the active icon, instead of a filled pill —
              // it marks the tab without crowding five of them together.
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 3,
                width: isSelected ? 22 : 0,
                decoration: BoxDecoration(
                  color: active,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 7),
              Icon(
                isSelected ? destination.activeIcon : destination.icon,
                color: color,
                size: 23,
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.ui(
                  size: 10.5,
                  weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

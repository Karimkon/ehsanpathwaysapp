import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';

/// The app's top-level navigation.
///
/// The five destinations are the things a Muslim opens the app to do daily.
/// Phones get a bottom bar; from 768 pt wide (iPad) a navigation rail runs
/// down the side, as iPadOS apps do, and from 1,100 pt it shows labels.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const railBreakpoint = 768.0;
  static const extendedRailBreakpoint = 1100.0;

  static const _destinations = <_Destination>[
    _Destination(Icons.wb_twilight_rounded, Icons.wb_twilight_rounded, 'Today'),
    _Destination(Icons.play_circle_outline_rounded, Icons.play_circle_rounded, 'Watch'),
    _Destination(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Quran'),
    _Destination(Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Library'),
    _Destination(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  void _go(int i) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      i,
      // Tapping the tab you are already on returns to its root.
      initialLocation: i == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= railBreakpoint) {
      return _RailLayout(
        shell: navigationShell,
        destinations: _destinations,
        extended: width >= extendedRailBreakpoint,
        onSelect: _go,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateDeep : AppColors.card,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.slateLine : AppColors.sand),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald950.withValues(alpha: isDark ? 0.3 : 0.06),
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
                      onTap: () => _go(i),
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

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.shell,
    required this.destinations,
    required this.extended,
    required this.onSelect,
  });

  final StatefulNavigationShell shell;
  final List<_Destination> destinations;
  final bool extended;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: isDark ? AppColors.slateLine : AppColors.sand),
              ),
            ),
            child: SafeArea(
              right: false,
              child: NavigationRail(
                extended: extended,
                minExtendedWidth: 216,
                selectedIndex: shell.currentIndex,
                onDestinationSelected: onSelect,
                labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                groupAlignment: -0.85,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: _RailBrand(extended: extended),
                ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mark = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppGradients.emerald,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.8)),
      ),
      child: const Icon(Icons.mosque_rounded, color: AppColors.goldLight, size: 24),
    );
    if (!extended) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Text(
          'Ehsan\nPathways',
          style: AppTheme.display(
            size: 17,
            height: 1.1,
            color: isDark ? AppColors.onDark : AppColors.emerald900,
          ),
        ),
      ],
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.activeIcon, this.label);
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
    final active = isDark ? AppColors.goldLight : AppColors.emerald900;
    final idle = isDark ? AppColors.onDarkSubtle : AppColors.subtle;
    final color = isSelected ? active : idle;

    return Semantics(
      selected: isSelected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A short gold bar above the active icon.
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.standard),
                curve: AppMotion.curve,
                height: 3,
                width: isSelected ? 22 : 0,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
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

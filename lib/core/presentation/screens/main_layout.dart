import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../theme.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _FloatingPillNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingPillNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(
      icon: PhosphorIconsRegular.house,
      activeIcon: PhosphorIconsFill.house,
      label: 'Home',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.bookBookmark,
      activeIcon: PhosphorIconsFill.bookBookmark,
      label: 'Notes',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.trophy,
      activeIcon: PhosphorIconsFill.trophy,
      label: 'Leaderboard',
    ),
    _NavItem(
      icon: PhosphorIconsRegular.user,
      activeIcon: PhosphorIconsFill.user,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: bottomPad > 0 ? bottomPad + 4 : 16,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.navBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isActive = currentIndex == index;
            return _NavButton(
              item: item,
              isActive: isActive,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Icon(
          isActive ? item.activeIcon : item.icon,
          color: isActive ? AppTheme.onPrimary : AppTheme.navIconInactive,
          size: 22,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/jala_theme.dart';

class JalaNavDestination {
  const JalaNavDestination({
    required this.icon,
    this.label,
  });

  final IconData icon;
  final String? label;
}

class JalaBottomNavBar extends StatelessWidget {
  const JalaBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<JalaNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 84 + bottomPadding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                destinations.length,
                (index) => _NavButton(
                  icon: destinations[index].icon,
                  label: destinations[index].label,
                  isActive: selectedIndex == index,
                  onTap: () => onTabSelected(index),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomPadding * 0.5),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = JalaBrand.amber;
    final inactiveColor = context.brand.greyDark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 56,
        height: 56,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isActive ? activeColor : inactiveColor,
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: JalaBrand.amber,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

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
    this.activeColor = JalaBrand.amber,
    this.inactiveColor = const Color(0xFF9A9A9A),
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<JalaNavDestination> destinations;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 84 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
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
    required this.activeColor,
    required this.inactiveColor,
    this.label,
  });

  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
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
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

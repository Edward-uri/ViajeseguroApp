import 'package:flutter/material.dart';

import 'jala_floating_circle_button.dart';

class JalaTopBar extends StatelessWidget {
  const JalaTopBar({
    super.key,
    this.onMenuTap,
    this.onProfileTap,
    this.topPadding = 16,
    this.horizontalPadding = 24,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
  final double topPadding;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final top = mediaQuery.padding.top + topPadding;

    return Positioned(
      top: top,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          JalaFloatingCircleButton(
            icon: Icons.menu,
            onTap: onMenuTap ?? () {},
          ),
          if (onProfileTap != null)
            JalaFloatingCircleButton(
              icon: Icons.person_outline,
              onTap: onProfileTap!,
            ),
        ],
      ),
    );
  }
}

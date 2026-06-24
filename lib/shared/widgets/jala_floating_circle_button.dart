import 'package:flutter/material.dart';

class JalaFloatingCircleButton extends StatelessWidget {
  const JalaFloatingCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF1A1410),
    this.iconSize = 26,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final double iconSize;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}

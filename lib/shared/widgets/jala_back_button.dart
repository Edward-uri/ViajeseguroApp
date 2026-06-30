import 'package:flutter/material.dart';

import '../../theme/jala_theme.dart';

class JalaBackButton extends StatelessWidget {
  const JalaBackButton({
    super.key,
    this.onTap,
    this.size = 44,
    this.iconSize = 24,
    this.backgroundColor,
    this.iconColor,
    this.icon = Icons.arrow_back_rounded,
  });

  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? context.colors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.colors.onSurface.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? context.colors.onSurface,
        ),
      ),
    );
  }
}

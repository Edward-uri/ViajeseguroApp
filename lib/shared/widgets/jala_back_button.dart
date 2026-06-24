import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class JalaBackButton extends StatelessWidget {
  const JalaBackButton({
    super.key,
    this.onTap,
    this.size = 44,
    this.iconSize = 24,
    this.backgroundColor = Colors.white,
    this.iconColor = JalaBrand.ink,
    this.icon = Icons.arrow_back_rounded,
  });

  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(26, 20, 15, 0.14),
              blurRadius: 12,
              offset: Offset(0, 4),
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

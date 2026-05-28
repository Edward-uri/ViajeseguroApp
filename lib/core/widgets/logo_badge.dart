import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/theme.dart';

class LogoBadge extends StatelessWidget {
  const LogoBadge({super.key, this.size = 132});

  final double size;

  static const Color _disc = Color(0xfffffdf9);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _disc,
        border: Border.all(color: JalaBrand.amber, width: size * 0.022),
        boxShadow: [
          BoxShadow(
            color: JalaBrand.amber.withValues(alpha: 0.22),
            blurRadius: size * 0.28,
            spreadRadius: 1,
            offset: Offset(0, size * 0.06),
          ),
          BoxShadow(
            color: JalaBrand.ink.withValues(alpha: 0.06),
            blurRadius: size * 0.10,
            offset: Offset(0, size * 0.03),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/logo.svg',
        width: size * 0.6,
        height: size * 0.6,
        semanticsLabel: 'Jala',
      ),
    );
  }
}
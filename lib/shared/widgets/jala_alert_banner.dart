import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../theme/theme_extensions.dart';

enum JalaAlertType { error, success, warning, info }

class JalaAlertBanner extends StatefulWidget {
  const JalaAlertBanner({
    super.key,
    required this.message,
    this.type = JalaAlertType.error,
    this.onDismiss,
  });

  final String message;
  final JalaAlertType type;
  final VoidCallback? onDismiss;

  @override
  State<JalaAlertBanner> createState() => _JalaAlertBannerState();
}

class _JalaAlertBannerState extends State<JalaAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor(BuildContext context) {
    final brand = context.brand;
    final s = Theme.of(context).colorScheme;
    switch (widget.type) {
      case JalaAlertType.error:
        return s.errorContainer;
      case JalaAlertType.success:
        return brand.successLight;
      case JalaAlertType.warning:
        return brand.accentSurface;
      case JalaAlertType.info:
        return s.primaryContainer;
    }
  }

  Color _accentColor(BuildContext context) {
    final brand = context.brand;
    final s = Theme.of(context).colorScheme;
    switch (widget.type) {
      case JalaAlertType.error:
        return s.error;
      case JalaAlertType.success:
        return brand.success;
      case JalaAlertType.warning:
        return context.isDark ? JalaBrand.amberLight : JalaBrand.amber;
      case JalaAlertType.info:
        return s.primary;
    }
  }

  Color _textColor(BuildContext context) {
    final brand = context.brand;
    final s = Theme.of(context).colorScheme;
    switch (widget.type) {
      case JalaAlertType.error:
        return s.onErrorContainer;
      case JalaAlertType.success:
        return brand.success;
      case JalaAlertType.warning:
        return context.isDark ? JalaBrand.amberLight : JalaBrand.amberDeep;
      case JalaAlertType.info:
        return s.onPrimaryContainer;
    }
  }

  IconData _icon() {
    switch (widget.type) {
      case JalaAlertType.error:
        return Icons.error_rounded;
      case JalaAlertType.success:
        return Icons.check_circle_rounded;
      case JalaAlertType.warning:
        return Icons.warning_amber_rounded;
      case JalaAlertType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bg = _backgroundColor(context);
    final accent = _accentColor(context);
    final txt = _textColor(context);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(
              BorderSide(color: accent.withValues(alpha: 0.4), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon(), size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: text.bodySmall?.copyWith(
                    color: txt,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              if (widget.onDismiss != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.close, size: 18, color: accent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

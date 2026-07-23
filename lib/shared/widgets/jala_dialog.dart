import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../../theme/theme_extensions.dart';
import 'jala_alert_banner.dart';

class JalaDialog extends StatelessWidget {
  const JalaDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.type = JalaAlertType.info,
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final JalaAlertType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancel;

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    JalaAlertType type = JalaAlertType.warning,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => JalaDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        type: type,
        showCancel: true,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Entendido',
    JalaAlertType type = JalaAlertType.info,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => JalaDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        type: type,
        showCancel: false,
        onConfirm: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Color _accentColor(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    switch (type) {
      case JalaAlertType.error:
        return s.error;
      case JalaAlertType.success:
        return context.brand.success;
      case JalaAlertType.warning:
        return JalaBrand.amber;
      case JalaAlertType.info:
        return s.primary;
    }
  }

  IconData _icon() {
    switch (type) {
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = _accentColor(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(), size: 28, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                if (showCancel) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          cancelText,
                          maxLines: 1,
                          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: showCancel ? 1 : 2,
                  child: FilledButton(
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        confirmText,
                        maxLines: 1,
                        style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class JalaMenuOption {
  const JalaMenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

class JalaMenuSheet extends StatelessWidget {
  const JalaMenuSheet({super.key, required this.options, this.userName});

  final List<JalaMenuOption> options;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          if (userName != null) ...[
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: JalaBrand.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 32,
                color: JalaBrand.amber,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName!,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          ...options.map((opt) => _MenuTile(option: opt)),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.option});

  final JalaMenuOption option;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = option.isDestructive ? scheme.error : scheme.onSurface;
    final iconColor = option.isDestructive ? scheme.error : JalaBrand.amber;

    return ListTile(
      onTap: option.onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(option.icon, size: 20, color: iconColor),
      ),
      title: Text(
        option.label,
        style: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant,
        size: 24,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

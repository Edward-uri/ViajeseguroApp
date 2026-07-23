import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/current_user_provider.dart';
import '../../core/di/core_module.dart';
import '../../theme/jala_theme.dart';
import 'auth_image_provider.dart';
import 'fade_slide_in.dart';

class JalaSidebarOption {
  const JalaSidebarOption({
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

class JalaSidebarSection {
  const JalaSidebarSection({required this.label, required this.options});

  final String label;
  final List<JalaSidebarOption> options;
}

class JalaSidebar extends StatelessWidget {
  const JalaSidebar({
    super.key,
    required this.userName,
    required this.userInitials,
    required this.userSubtitle,
    required this.sections,
    required this.onLogout,
    this.logoutLabel = 'Cerrar sesion',
    this.userId,
  });

  final String userName;
  final String userInitials;
  final String userSubtitle;
  final List<JalaSidebarSection> sections;
  final VoidCallback onLogout;
  final String logoutLabel;
  final int? userId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final topPad = MediaQuery.of(context).padding.top;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: context.brand.surfaceLight,
      child: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16 + topPad, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Menu',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: _UserCard(
                  initials: userInitials,
                  name: userName,
                  subtitle: userSubtitle,
                  userId: userId,
                ),
              ),
              const SizedBox(height: 24),
              ...sections.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                return FadeSlideIn(
                  delay: Duration(milliseconds: 300 + (index * 150)),
                  child: _SidebarSection(section: section),
                );
              }),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: Duration(milliseconds: 300 + (sections.length * 150)),
                child: _LogoutCard(label: logoutLabel, onTap: onLogout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.initials,
    required this.name,
    required this.subtitle,
    this.userId,
  });

  final String initials;
  final String name;
  final String subtitle;
  final int? userId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final apiClient = ProviderScope.containerOf(context).read(apiClientProvider);

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: JalaBrand.amber,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: userId != null
                ? Consumer(
                    builder: (context, ref, _) {
                      final version = ref.watch(profilePhotoVersionProvider);
                      return Image(
                        image: AuthImageProvider(
                          userId: userId!,
                          apiClient: apiClient,
                          version: version,
                        ),
                        fit: BoxFit.cover,
                        width: 64,
                        height: 64,
                        errorBuilder: (_, __, ___) => Text(
                          initials,
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                : Text(
                    initials,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: context.brand.greyDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.section});

  final JalaSidebarSection section;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Text(
            section.label,
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.06 * 12,
              color: context.brand.greyDark,
            ),
          ),
        ),
        Container(
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              for (int i = 0; i < section.options.length; i++) ...[
                _OptionTile(option: section.options[i]),
                if (i < section.options.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: context.colors.outlineVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final JalaSidebarOption option;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color = option.isDestructive
        ? context.brand.destructive
        : onSurface;
    final iconColor = option.isDestructive
        ? context.brand.destructive
        : onSurface;

    return ListTile(
      onTap: option.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(option.icon, size: 24, color: iconColor),
      title: Text(
        option.label,
        style: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: context.colors.outline,
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: _cardDecoration(context),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.logout_rounded,
          size: 24,
          color: context.brand.destructive,
        ),
        title: Text(
          label,
          style: text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: context.brand.destructive,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: context.colors.outline,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: context.colors.surfaceContainerLow,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: context.brand.divider, width: 1),
    boxShadow: [
      BoxShadow(
        color: context.colors.onSurface.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

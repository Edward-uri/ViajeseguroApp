import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

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
  });

  final String userName;
  final String userInitials;
  final String userSubtitle;
  final List<JalaSidebarSection> sections;
  final VoidCallback onLogout;
  final String logoutLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final topPad = MediaQuery.of(context).padding.top;

    return Material(
      color: const Color(0xFFF6F6F6),
      child: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16 + topPad, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Menu',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: JalaBrand.ink,
                ),
              ),
              const SizedBox(height: 24),
              _UserCard(
                initials: userInitials,
                name: userName,
                subtitle: userSubtitle,
              ),
              const SizedBox(height: 24),
              ...sections.map((section) => _SidebarSection(section: section)),
              const SizedBox(height: 16),
              _LogoutCard(label: logoutLabel, onTap: onLogout),
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
  });

  final String initials;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: JalaBrand.amber,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
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
                    color: JalaBrand.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6B6661),
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
              color: const Color(0xFF6B6661),
            ),
          ),
        ),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              for (int i = 0; i < section.options.length; i++) ...[
                _OptionTile(option: section.options[i]),
                if (i < section.options.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 56),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
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
    final color = option.isDestructive
        ? const Color(0xFFD84315)
        : JalaBrand.ink;
    final iconColor = option.isDestructive
        ? const Color(0xFFD84315)
        : JalaBrand.ink;

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
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Color(0xFFC4C4C4),
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
      decoration: _cardDecoration(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(
          Icons.logout_rounded,
          size: 24,
          color: Color(0xFFD84315),
        ),
        title: Text(
          label,
          style: text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: const Color(0xFFD84315),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Color(0xFFC4C4C4),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFECECEC), width: 1),
    boxShadow: const [
      BoxShadow(
        color: Color.fromRGBO(26, 20, 15, 0.06),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );
}

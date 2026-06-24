import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class JalaHomeBottomSheet extends StatelessWidget {
  const JalaHomeBottomSheet({
    super.key,
    required this.greetingName,
    this.onSearchTap,
    this.onSavedAddressTap,
  });

  final String greetingName;
  final VoidCallback? onSearchTap;
  final void Function(String title)? onSavedAddressTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D1),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $greetingName 👋',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B6661),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '¿A dónde vas?',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1410),
                  ),
                ),
                const SizedBox(height: 16),
                _SearchBar(onTap: onSearchTap),
                const SizedBox(height: 20),
                _SavedAddress(
                  icon: Icons.home_outlined,
                  title: 'Casa',
                  subtitle: 'Av. Hidalgo 123',
                  onTap: () => onSavedAddressTap?.call('Casa'),
                ),
                const SizedBox(height: 14),
                _SavedAddress(
                  icon: Icons.work_outline,
                  title: 'Trabajo',
                  subtitle: 'Primaria 5 de mayo',
                  onTap: () => onSavedAddressTap?.call('Trabajo'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD1D1D1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(
              Icons.search,
              color: Color(0xFF6B6661),
              size: 22,
            ),
            const SizedBox(width: 10),
            const Text(
              'Buscar destino',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB6B3B1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddress extends StatelessWidget {
  const _SavedAddress({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: JalaBrand.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1410),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B6661),
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

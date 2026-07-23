import 'package:flutter/material.dart';

import '../../features/trip/trip-in-progress/domain/entities/trip.dart';
import '../../theme/jala_theme.dart';
import 'fade_slide_in.dart';

class JalaHomeBottomSheet extends StatelessWidget {
  const JalaHomeBottomSheet({
    super.key,
    required this.greetingName,
    this.onSearchTap,
    this.savedAddresses = const [],
    this.activeTrip,
    this.onActiveTripTap,
  });

  final String greetingName;
  final VoidCallback? onSearchTap;
  final List<JalaSavedAddress> savedAddresses;
  final Trip? activeTrip;
  final VoidCallback? onActiveTripTap;

  bool get _hasActiveTrip =>
      activeTrip != null &&
      activeTrip!.status != TripStatus.completado &&
      activeTrip!.status != TripStatus.cancelado;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Hola, $greetingName 👋',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.brand.greyDark,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    _hasActiveTrip ? 'Tu viaje' : '¿A dónde vas?',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_hasActiveTrip)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: _ActiveTripCard(
                      trip: activeTrip!,
                      onTap: onActiveTripTap,
                    ),
                  )
                else ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: _SearchBar(onTap: onSearchTap),
                  ),
                  if (savedAddresses.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: _SavedAddressList(items: savedAddresses),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({
    required this.trip,
    this.onTap,
  });

  final Trip trip;
  final VoidCallback? onTap;

  String get _statusLabel {
    switch (trip.status) {
      case TripStatus.solicitado:
        return 'Buscando conductor...';
      case TripStatus.aceptado:
        return 'Conductor en camino';
      case TripStatus.enCurso:
        return 'En viaje';
      case TripStatus.completado:
        return 'Completado';
      case TripStatus.cancelado:
        return 'Cancelado';
    }
  }

  IconData get _statusIcon {
    switch (trip.status) {
      case TripStatus.solicitado:
        return Icons.search_rounded;
      case TripStatus.aceptado:
        return Icons.directions_bike_rounded;
      case TripStatus.enCurso:
        return Icons.navigation_rounded;
      case TripStatus.completado:
        return Icons.check_circle_rounded;
      case TripStatus.cancelado:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.brand.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.brand.greyBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: JalaBrand.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _statusIcon,
                color: JalaBrand.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.origin.address} → ${trip.destination.address}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: context.brand.greyDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.brand.greyDark,
              size: 24,
            ),
          ],
        ),
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
          color: context.brand.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.brand.greyBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: context.brand.greyDark,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Buscar destino',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: context.brand.greyLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Destino guardado que se muestra en la home (mapeado desde una direccion
/// favorita en la pantalla del pasajero).
class JalaSavedAddress {
  const JalaSavedAddress({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SavedAddressList extends StatelessWidget {
  const _SavedAddressList({required this.items});

  final List<JalaSavedAddress> items;

  @override
  Widget build(BuildContext context) {
    // Altura acotada + scroll: el sheet no crece de mas y el ultimo destino se
    // ve completo al hacer scroll.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 190),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final a = items[index];
          return _SavedAddress(
            icon: Icons.place_outlined,
            title: a.title,
            subtitle: a.subtitle,
            onTap: a.onTap,
          );
        },
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
              color: context.brand.accentSurface,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: context.brand.greyDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

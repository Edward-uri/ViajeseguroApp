import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../../theme/theme.dart';
import '../../../trip-searching/di/trip_searching_module.dart';
import '../../../trip-searching/domain/repositories/trip_search_repository.dart';
import '../../domain/entities/trip.dart';
import '../provider/trip_in_progress_viewmodel.dart';

class TripInProgressScreen extends ConsumerStatefulWidget {
  const TripInProgressScreen({super.key, required this.trip});

  final Trip trip;

  @override
  ConsumerState<TripInProgressScreen> createState() =>
      _TripInProgressScreenState();
}

class _TripInProgressScreenState extends ConsumerState<TripInProgressScreen> {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  bool _routeDrawn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripInProgressViewModelProvider.notifier).setTrip(widget.trip);
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    try {
      _polylineManager =
          await mapboxMap.annotations.createPolylineAnnotationManager();
    } catch (e) {
      debugPrint('[TripInProgress] PolylineAnnotation no disponible: $e');
    }
    _drawRoute();
    _fitRoute();
  }

  void _drawRoute() async {
    if (_routeDrawn) return;
    final trip = widget.trip;
    try {
      final repo = ref.read(tripSearchRepositoryProvider);
      final routeCoords = await repo.getRoute(
        originLat: trip.origin.latitude,
        originLng: trip.origin.longitude,
        destinationLat: trip.destination.latitude,
        destinationLng: trip.destination.longitude,
      );

      final coordinates = routeCoords.isNotEmpty
          ? routeCoords.map((c) => Position(c[0], c[1])).toList()
          : [
              Position(trip.origin.longitude, trip.origin.latitude),
              Position(trip.destination.longitude, trip.destination.latitude),
            ];

      final polylineOptions = PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: JalaBrand.amber.toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.9,
      );
      _polylineManager?.create(polylineOptions);
      _routeDrawn = true;
    } catch (e) {
      debugPrint('[TripInProgress] No se pudo dibujar ruta: $e');
    }
  }

  void _fitRoute() {
    final trip = widget.trip;
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(
          (trip.origin.longitude + trip.destination.longitude) / 2,
          (trip.origin.latitude + trip.destination.latitude) / 2,
        )),
        zoom: 13.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(tripInProgressViewModelProvider);
    final trip = vm.trip ?? widget.trip;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    ref.listen<TripInProgressViewModelState>(
      tripInProgressViewModelProvider,
      (previous, next) {
        final status = next.trip?.status;
        if (status == TripStatus.completado ||
            status == TripStatus.cancelado) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.passengerHome,
              (route) => false,
            );
          }
        }
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          JalaMapView(
            onMapCreated: _onMapCreated,
            showLocationMarker: false,
            showCurrentLocationPin: false,
          ),
          Positioned(
            top: topPad + 16,
            left: 24,
            child: JalaBackButton(
              onTap: () => _showExitConfirm(context),
            ),
          ),
          Positioned(
            top: topPad + 16,
            right: 24,
            child: JalaBackButton(
              icon: Icons.menu_rounded,
              onTap: () {},
            ),
          ),
          if (trip.status == TripStatus.aceptado ||
              trip.status == TripStatus.enCurso)
            Positioned(
              top: topPad + 80,
              left: 0,
              right: 0,
              child: Center(
                child: SvgPicture.asset(
                  'lib/shared/icons/MototaxiMapa.svg',
                  width: 48,
                  height: 48,
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _TripBottomPanel(
              trip: trip,
              vm: vm,
              bottomPad: bottomPad,
              onCancel: () => _showCancelDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitConfirm(BuildContext context) async {
    final ok = await JalaDialog.confirm(
      context,
      title: 'Salir',
      message: '¿Seguro que quieres salir? Puedes volver desde el historial.',
      confirmText: 'Salir',
      type: JalaAlertType.info,
    );
    if (ok && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final ok = await JalaDialog.confirm(
      context,
      title: 'Cancelar viaje',
      message: '¿Estas seguro de que quieres cancelar este viaje?',
      confirmText: 'Si, cancelar',
      type: JalaAlertType.warning,
    );
    if (ok) {
      ref.read(tripInProgressViewModelProvider.notifier).cancelTrip();
    }
  }
}

class _TripBottomPanel extends StatelessWidget {
  const _TripBottomPanel({
    required this.trip,
    required this.vm,
    required this.bottomPad,
    required this.onCancel,
  });

  final Trip trip;
  final TripInProgressViewModelState vm;
  final double bottomPad;
  final VoidCallback onCancel;

  String get _statusTitle {
    switch (trip.status) {
      case TripStatus.solicitado:
        return 'Buscando mototaxi';
      case TripStatus.aceptado:
        return 'Llega en 3 min';
      case TripStatus.enCurso:
        return 'En viaje';
      case TripStatus.completado:
        return 'Viaje completado';
      case TripStatus.cancelado:
        return 'Viaje cancelado';
    }
  }

  String get _statusSubtitle {
    switch (trip.status) {
      case TripStatus.solicitado:
        return 'Esperando conductor';
      case TripStatus.aceptado:
        return 'Tu mototaxi esta en camino';
      case TripStatus.enCurso:
        return 'Dirigete a tu destino';
      case TripStatus.completado:
        return 'Gracias por usar Jala';
      case TripStatus.cancelado:
        return 'El viaje fue cancelado';
    }
  }

  double get _progress {
    switch (trip.status) {
      case TripStatus.solicitado:
        return 0.1;
      case TripStatus.aceptado:
        return 0.63;
      case TripStatus.enCurso:
        return 0.85;
      case TripStatus.completado:
        return 1.0;
      case TripStatus.cancelado:
        return 0.0;
    }
  }

  String get _driverInitials {
    final name = trip.driverName ?? '??';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(26, 20, 15, 0.12),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 14, 24, bottomPad + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _statusTitle,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: JalaBrand.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _statusSubtitle,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B6661),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFECECEC),
                valueColor: const AlwaysStoppedAnimation<Color>(JalaBrand.amber),
              ),
            ),
            const SizedBox(height: 20),
            _DriverCard(
              initials: _driverInitials,
              name: trip.driverName ?? 'Conductor',
              rating: '4.9',
              vehicleInfo: trip.vehicleInfo ?? 'Mototaxi',
              plate: 'ABC-123',
            ),
            const SizedBox(height: 16),
            _ActionButton(
              label: 'Mensaje',
              icon: Icons.chat_bubble_rounded,
              isGradient: true,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFECECEC), height: 1),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: vm.isLoading ? null : onCancel,
                child: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Cancelar viaje',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD84315),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.initials,
    required this.name,
    required this.rating,
    required this.vehicleInfo,
    required this.plate,
  });

  final String initials;
  final String name;
  final String rating;
  final String vehicleInfo;
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: JalaBrand.amber,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: JalaBrand.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: JalaBrand.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$rating · $vehicleInfo',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B6661),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: JalaBrand.ink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              plate,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.isOutlined = false,
    this.isGradient = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isOutlined;
  final bool isGradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = 52.0;

    if (isGradient) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [JalaBrand.amber, Color(0xFFFFB300)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JalaBrand.amber, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: JalaBrand.amber),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: JalaBrand.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

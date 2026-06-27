import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../../theme/theme.dart';
import '../../../trip-in-progress/domain/entities/trip.dart';
import '../../di/trip_searching_module.dart';
import '../../domain/entities/trip_location.dart';
import '../provider/trip_searching_viewmodel.dart';

class TripSearchingScreen extends ConsumerStatefulWidget {
  const TripSearchingScreen({super.key});

  @override
  ConsumerState<TripSearchingScreen> createState() => _TripSearchingScreenState();
}

class _TripSearchingScreenState extends ConsumerState<TripSearchingScreen> {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _originFocusNode = FocusNode();
  final _destinationFocusNode = FocusNode();
  geo.Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripSearchingViewModelProvider.notifier).resetAll();
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      if (mounted) {
        setState(() => _currentPosition = position);
        _flyTo(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicacion: $e');
    }
  }

  void _flyTo(double latitude, double longitude) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 1000, startDelay: 0),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    try {
      _polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    } catch (e) {
      debugPrint('[TripSearching] PolylineAnnotation no disponible: $e');
    }

    if (_currentPosition != null) {
      _flyTo(_currentPosition!.latitude, _currentPosition!.longitude);
    }
  }

  void _onCameraChanged(CameraChangedEventData data) {
    final notifier = ref.read(tripSearchingViewModelProvider.notifier);
    final vm = ref.read(tripSearchingViewModelProvider);
    if (!vm.isPickingOnMap) return;

    final center = data.cameraState.center;
    final lat = center.coordinates.lat.toDouble();
    final lng = center.coordinates.lng.toDouble();
    notifier.updatePendingMapPosition(lat, lng);
  }

  void _onMapIdle(MapIdleEventData data) {
    final vm = ref.read(tripSearchingViewModelProvider);
    if (!vm.isPickingOnMap) return;
    if (vm.pendingMapLat == null || vm.pendingMapLng == null) return;
  }

  void _drawRoute(TripLocation origin, TripLocation destination) async {
    _polylineManager?.deleteAll();
    try {
      final repo = ref.read(tripSearchRepositoryProvider);
      final routeCoords = await repo.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destinationLat: destination.latitude,
        destinationLng: destination.longitude,
      );

      final coordinates = routeCoords.isNotEmpty
          ? routeCoords.map((c) => Position(c[0], c[1])).toList()
          : [
              Position(origin.longitude, origin.latitude),
              Position(destination.longitude, destination.latitude),
            ];

      final polylineOptions = PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: JalaBrand.amber.toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.9,
      );
      _polylineManager?.create(polylineOptions);
    } catch (e) {
      debugPrint('[TripSearching] No se pudo dibujar ruta: $e');
    }

    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(
          (origin.longitude + destination.longitude) / 2,
          (origin.latitude + destination.latitude) / 2,
        )),
        zoom: 12.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  void _clearRoute() {
    _polylineManager?.deleteAll();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(tripSearchingViewModelProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    ref.listen<TripSearchingViewModelState>(
      tripSearchingViewModelProvider,
      (previous, next) {
        if (next.origin != null && previous?.origin != next.origin) {
          _originController.text = next.origin!.address;
        }
        if (next.destination != null && previous?.destination != next.destination) {
          _destinationController.text = next.destination!.address;
        }
        if (next.hasRoute && next.origin != null && next.destination != null) {
          _drawRoute(next.origin!, next.destination!);
        } else if (!next.hasRoute) {
          _clearRoute();
        }
        if (next.isPickingOnMap && !next.isSearching) {
          _originFocusNode.unfocus();
          _destinationFocusNode.unfocus();
        }
      },
    );

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Mapa aislado: solo se reconstruye cuando cambia isPickingOnMap,
          // no en cada tecla del buscador ni en cada cambio del panel inferior.
          Consumer(
            builder: (context, ref, _) {
              final isPickingOnMap = ref.watch(
                tripSearchingViewModelProvider.select((s) => s.isPickingOnMap),
              );
              return JalaMapView(
                onMapCreated: _onMapCreated,
                showLocationMarker: false,
                showCurrentLocationPin: true,
                showPinMarker: isPickingOnMap,
                onCameraChanged: _onCameraChanged,
                onMapIdle: _onMapIdle,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            child: JalaBackButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          // Boton flotante: su posicion depende de la altura del panel.
          // .select sobre un double -> solo rebuild cuando esa altura cambia,
          // no en cada keystroke ni en cada tick de camara.
          if (_currentPosition != null)
            Consumer(
              builder: (context, ref, _) {
                final panelHeight = ref.watch(
                  tripSearchingViewModelProvider.select(_bottomPanelHeight),
                );
                return Positioned(
                  right: 24,
                  bottom: panelHeight + bottomPadding + 16,
                  child: JalaFloatingCircleButton(
                    icon: Icons.my_location,
                    iconColor: const Color(0xFF005B9F),
                    iconSize: 24,
                    onTap: _getCurrentLocation,
                  ),
                );
              },
            ),
          // Panel inferior: consume el estado que realmente renderiza, pero
          // aislado del mapa (que ya no se reconstruye junto con el).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer(
              builder: (context, ref, _) {
                final vm = ref.watch(tripSearchingViewModelProvider);
                return _BottomPanel(
                  vm: vm,
                  notifier: notifier,
                  originController: _originController,
                  destinationController: _destinationController,
                  originFocusNode: _originFocusNode,
                  destinationFocusNode: _destinationFocusNode,
                  bottomPadding: bottomPadding,
                  onConfirmTrip: () => _confirmTrip(context, notifier),
                  onRequestFare: () => _requestFare(notifier),
                  onUseCurrentLocation: () {
                    if (_currentPosition == null) return;
                    final location = TripLocation(
                      address: 'Mi ubicacion actual',
                      latitude: _currentPosition!.latitude,
                      longitude: _currentPosition!.longitude,
                      placeName: 'Mi ubicacion',
                    );
                    if (vm.activeInput == LocationInputMode.origin) {
                      notifier.selectOrigin(location);
                      _destinationFocusNode.requestFocus();
                    } else {
                      notifier.selectDestination(location);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _bottomPanelHeight(TripSearchingViewModelState vm) {
    double base = 340;
    if (vm.searchResults.isNotEmpty || vm.isSearching) base += 200;
    if (vm.hasRoute) base += 80;
    if (vm.isPickingOnMap) base += 20;
    return base;
  }

  Future<void> _confirmTrip(BuildContext context, TripSearchingViewModel notifier) async {
    final trip = await notifier.confirmFare();
    if (trip != null && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.tripInProgress,
        (route) => route.isFirst,
        arguments: trip,
      );
    }
  }

  Future<void> _requestFare(TripSearchingViewModel notifier) async {
    await notifier.requestFare();
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.vm,
    required this.notifier,
    required this.originController,
    required this.destinationController,
    required this.originFocusNode,
    required this.destinationFocusNode,
    required this.bottomPadding,
    required this.onConfirmTrip,
    required this.onUseCurrentLocation,
    required this.onRequestFare,
  });

  final TripSearchingViewModelState vm;
  final TripSearchingViewModel notifier;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocusNode;
  final FocusNode destinationFocusNode;
  final double bottomPadding;
  final VoidCallback onConfirmTrip;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onRequestFare;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
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
                  const Text(
                    'A donde vas?',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1410),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LocationInputs(
                    vm: vm,
                    notifier: notifier,
                    originController: originController,
                    destinationController: destinationController,
                    originFocusNode: originFocusNode,
                    destinationFocusNode: destinationFocusNode,
                  ),
                  if (vm.isPickingOnMap) ...[
                    const SizedBox(height: 16),
                    _PickOnMapPanel(
                      vm: vm,
                      notifier: notifier,
                    ),
                  ],
                  if (!vm.isPickingOnMap && vm.searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SearchResults(
                      results: vm.searchResults,
                      isSearching: vm.isSearching,
                      onSelect: (location) {
                        if (vm.activeInput == LocationInputMode.origin) {
                          notifier.selectOrigin(location);
                          destinationFocusNode.requestFocus();
                        } else {
                          notifier.selectDestination(location);
                        }
                      },
                    ),
                  ],
                  if (!vm.isPickingOnMap &&
                      vm.searchQuery.isEmpty &&
                      vm.searchResults.isEmpty &&
                      !vm.isSearching &&
                      vm.activeInput == LocationInputMode.origin &&
                      vm.origin == null) ...[
                    const SizedBox(height: 12),
                    _CurrentLocationButton(onTap: onUseCurrentLocation),
                  ],
                  if (vm.hasRoute && vm.step != TripSearchingStep.fareShown) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: vm.isLoading ? null : () => onRequestFare(),
                        child: vm.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Solicitar viaje'),
                      ),
                    ),
                  ],
                  if (vm.step == TripSearchingStep.fareShown && vm.trip != null) ...[
                    const SizedBox(height: 20),
                    _FareSummaryCard(trip: vm.trip!),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => notifier.rejectFare(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => onConfirmTrip(),
                            child: const Text('Confirmar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    JalaAlertBanner(
                      message: vm.errorMessage!,
                      onDismiss: notifier.clearError,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}

class _LocationInputs extends StatelessWidget {
  const _LocationInputs({
    required this.vm,
    required this.notifier,
    required this.originController,
    required this.destinationController,
    required this.originFocusNode,
    required this.destinationFocusNode,
  });

  final TripSearchingViewModelState vm;
  final TripSearchingViewModel notifier;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocusNode;
  final FocusNode destinationFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LocationField(
          label: 'Origen',
          icon: Icons.trip_origin,
          controller: originController,
          focusNode: originFocusNode,
          isActive: vm.activeInput == LocationInputMode.origin && !vm.isPickingOnMap,
          isPickingOnMap: vm.isPickingOnMap && vm.activeInput == LocationInputMode.origin,
          enabled: !vm.isPickingOnMap,
          onTap: () => notifier.activateOriginInput(),
          onPinTap: () {
            notifier.activateOriginInput();
            notifier.startPickOnMap();
          },
          onChanged: (value) {
            if (!vm.isPickingOnMap) {
              notifier.setSearchQuery(value);
            }
          },
        ),
        const SizedBox(height: 12),
        _LocationField(
          label: 'Destino',
          icon: Icons.location_on,
          controller: destinationController,
          focusNode: destinationFocusNode,
          isActive: vm.activeInput == LocationInputMode.destination && !vm.isPickingOnMap,
          isPickingOnMap: vm.isPickingOnMap && vm.activeInput == LocationInputMode.destination,
          enabled: vm.origin != null && !vm.isPickingOnMap,
          onTap: () => notifier.activateDestinationInput(),
          onPinTap: () {
            if (vm.origin != null) {
              notifier.activateDestinationInput();
              notifier.startPickOnMap();
            }
          },
          onChanged: (value) {
            if (!vm.isPickingOnMap) {
              notifier.setSearchQuery(value);
            }
          },
        ),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.isPickingOnMap,
    required this.enabled,
    required this.onTap,
    required this.onPinTap,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool isPickingOnMap;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onPinTap;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isActive || isPickingOnMap)
                ? JalaBrand.amber
                : const Color(0xFFD1D1D1),
            width: (isActive || isPickingOnMap) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: (isActive || isPickingOnMap)
                  ? JalaBrand.amber
                  : const Color(0xFF6B6661),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                onChanged: onChanged,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1410),
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar $label',
                  hintStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB6B3B1),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? onPinTap : null,
              child: Icon(
                isPickingOnMap ? Icons.close : Icons.place,
                color: isPickingOnMap
                    ? Colors.red
                    : enabled
                        ? JalaBrand.amber
                        : const Color(0xFFD1D1D1),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickOnMapPanel extends StatelessWidget {
  const _PickOnMapPanel({required this.vm, required this.notifier});

  final TripSearchingViewModelState vm;
  final TripSearchingViewModel notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JalaBrand.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.place, color: JalaBrand.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Mueve el mapa para seleccionar',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1410),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => notifier.cancelPickOnMap(),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: vm.isLoading ? null : () => notifier.confirmPinFromMap(),
                  icon: vm.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D1D1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location,
                color: JalaBrand.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Usar mi ubicacion actual',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1410),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.isSearching,
    required this.onSelect,
  });

  final List<TripLocation> results;
  final bool isSearching;
  final void Function(TripLocation location) onSelect;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No se encontraron resultados',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: Color(0xFF6B6661),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final location = results[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: JalaBrand.amber),
            title: Text(
              location.placeName ?? location.address,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              location.address,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF6B6661),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelect(location),
          );
        },
      ),
    );
  }
}

class _FareSummaryCard extends StatelessWidget {
  const _FareSummaryCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JalaBrand.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarifa del viaje',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B6661),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${trip.fare.totalFare.toStringAsFixed(2)} MXN',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1410),
                ),
              ),
              if (trip.distanciaKm != null)
                Text(
                  '${trip.distanciaKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1410),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

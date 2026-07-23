import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../../routes/app_routes.dart';
import '../../../../../shared/utils/svg_to_mapbox.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../../theme/jala_theme.dart';
import '../../../trip-in-progress/domain/entities/estimacion_viaje.dart';
import '../../../trip-in-progress/domain/entities/tipo_servicio.dart';
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
  PointAnnotationManager? _pinMarkerManager;
  bool _pinImagesLoaded = false;
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _originFocusNode = FocusNode();
  final _destinationFocusNode = FocusNode();
  geo.Position? _currentPosition;
  Timer? _cameraDebounce;

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
    _cameraDebounce?.cancel();
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
    try {
      _pinMarkerManager = await mapboxMap.annotations.createPointAnnotationManager();
    } catch (e) {
      debugPrint('[TripSearching] PinMarkerManager no disponible: $e');
    }

    // El mapa puede recrearse (p.ej. cambio de tema claro/oscuro): el estilo
    // nuevo no tiene las imágenes anteriores.
    _pinImagesLoaded = false;

    // Cargar pines PNG como imágenes de estilo del mapa
    await _loadPinImages();

    // Si ya había ruta confirmada, redibujarla en el mapa nuevo.
    final vm = ref.read(tripSearchingViewModelProvider);
    if (vm.hasRoute && vm.origin != null && vm.destination != null) {
      _drawRoute(vm.origin!, vm.destination!);
    }

    if (_currentPosition != null) {
      _flyTo(_currentPosition!.latitude, _currentPosition!.longitude);
    }
  }

  Future<void> _loadPinImages() async {
    if (_pinImagesLoaded || _mapboxMap == null) return;
    try {
      final verdeOk = await addPngPinToMap(
        _mapboxMap!,
        'pin-verde',
        'lib/shared/icons/map-icons/Pin-Verde.png',
        width: 30,
        height: 36,
      );
      final naranjaOk = await addPngPinToMap(
        _mapboxMap!,
        'pin-naranja',
        'lib/shared/icons/map-icons/Pin-Naranja.png',
        width: 30,
        height: 36,
      );
      // Ambas imágenes deben quedar registradas; si alguna falló, las
      // anotaciones apuntarían a imágenes inexistentes (marcador invisible).
      _pinImagesLoaded = verdeOk && naranjaOk;
    } catch (e) {
      debugPrint('[TripSearching] Error cargando pines PNG: $e');
    }
  }

  void _onCameraChanged(CameraChangedEventData data) {
    final notifier = ref.read(tripSearchingViewModelProvider.notifier);
    final vm = ref.read(tripSearchingViewModelProvider);
    if (!vm.isPickingOnMap) return;

    final center = data.cameraState.center;
    final lat = center.coordinates.lat.toDouble();
    final lng = center.coordinates.lng.toDouble();

    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        notifier.updatePendingMapPosition(lat, lng);
      }
    });
  }

  void _onMapIdle(MapIdleEventData data) {
    final vm = ref.read(tripSearchingViewModelProvider);
    if (!vm.isPickingOnMap) return;
    if (vm.pendingMapLat == null || vm.pendingMapLng == null) return;
  }

  void _drawRoute(TripLocation origin, TripLocation destination) async {
    _polylineManager?.deleteAll();

    // Respaldo (línea recta) si OSRM no responde: la ruta y los pines deben
    // verse siempre mientras se confirma el viaje.
    var coordinates = <Position>[
      Position(origin.longitude, origin.latitude),
      Position(destination.longitude, destination.latitude),
    ];
    try {
      final repo = ref.read(tripSearchRepositoryProvider);
      final routeCoords = await repo.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destinationLat: destination.latitude,
        destinationLng: destination.longitude,
      );
      if (routeCoords.isNotEmpty) {
        coordinates = routeCoords.map((c) => Position(c[0], c[1])).toList();
      }
    } catch (e) {
      debugPrint('[TripSearching] OSRM falló, uso línea recta: $e');
    }

    try {
      _polylineManager?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: JalaBrand.amber.toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
    } catch (e) {
      debugPrint('[TripSearching] No se pudo dibujar la ruta: $e');
    }

    // Dibujar pines de origen y destino en el mapa
    _drawOriginDestinationPins(origin, destination);

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

  void _drawOriginDestinationPins(TripLocation origin, TripLocation destination) {
    if (_pinMarkerManager == null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pinMarkerManager != null && mounted) {
          _drawOriginDestinationPins(origin, destination);
        }
      });
      return;
    }

    // Si las imágenes SVG aún no se han cargado, esperar y reintentar
    if (!_pinImagesLoaded) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pinImagesLoaded && mounted) {
          _drawOriginDestinationPins(origin, destination);
        }
      });
      return;
    }

    try {
      _pinMarkerManager!.deleteAll();

      // Pin de origen (verde) — PNG
      _pinMarkerManager!.create(PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(origin.longitude, origin.latitude),
        ),
        iconImage: 'pin-verde',
        iconSize: 1.0,
      )).then((_) {}).catchError((_) {});

      // Pin de destino (naranja) — PNG
      _pinMarkerManager!.create(PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(destination.longitude, destination.latitude),
        ),
        iconImage: 'pin-naranja',
        iconSize: 1.0,
      )).then((_) {}).catchError((_) {});
    } catch (e) {
      debugPrint('[TripSearching] Error dibujando pines: $e');
    }
  }

  void _clearRoute() {
    _polylineManager?.deleteAll();
    _pinMarkerManager?.deleteAll();
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
              final vm = ref.watch(
                tripSearchingViewModelProvider.select((s) => (
                  s.isPickingOnMap,
                  s.activeInput,
                )),
              );
              final isPickingOnMap = vm.$1;
              final activeInput = vm.$2;
              final pinAsset = activeInput == LocationInputMode.origin
                  ? 'lib/shared/icons/map-icons/Pin-Verde.png'
                  : 'lib/shared/icons/map-icons/Pin-Naranja.png';
              return JalaMapView(
                onMapCreated: _onMapCreated,
                showLocationMarker: false,
                showCurrentLocationPin: true,
                showPinMarker: isPickingOnMap,
                pinMarkerAsset: pinAsset,
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
          // AnimatedPositioned para que la transicion sea suave.
          if (_currentPosition != null)
            Consumer(
              builder: (context, ref, _) {
                final panelHeight = ref.watch(
                  tripSearchingViewModelProvider.select(_bottomPanelHeight),
                );
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  right: 24,
                  bottom: panelHeight + bottomPadding + 16,
                  child: JalaFloatingCircleButton(
                    icon: Icons.my_location,
                    iconColor: context.brand.accentBlue,
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
                  onUseCurrentLocation: () async {
                    if (_currentPosition == null) return;
                    final wasOrigin =
                        vm.activeInput == LocationInputMode.origin;
                    // Resolver la direccion real por reverse geocoding en vez
                    // de guardar el texto fijo "Mi ubicacion".
                    await notifier.useCurrentLocation(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    );
                    if (wasOrigin) _destinationFocusNode.requestFocus();
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
    // Selector viaje/paquete (46px + 18px de separacion); solo visible mientras
    // no se muestra la tarifa.
    if (vm.step != TripSearchingStep.fareShown) base += 64;
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
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vm.step != TripSearchingStep.fareShown) ...[
                    _ServiceTypeSelector(
                      selected: vm.tipoServicio,
                      onChanged: notifier.setTipoServicio,
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    vm.tipoServicio == TipoServicio.envio
                        ? 'A donde lo envias?'
                        : 'A donde vas?',
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LocationInputs(
                    vm: vm,
                    notifier: notifier,
                    originController: originController,
                    destinationController: destinationController,
                    originFocusNode: originFocusNode,
                    destinationFocusNode: destinationFocusNode,
                  ),
                  const _SectionSpacer(isVisible: true),
                  _AnimatedSection(
                    visible: vm.isPickingOnMap,
                    sectionKey: 'pickOnMap',
                    child: _PickOnMapPanel(vm: vm, notifier: notifier),
                  ),
                  _AnimatedSection(
                    visible: !vm.isPickingOnMap && vm.searchQuery.isNotEmpty,
                    sectionKey: 'searchResults',
                    child: _SearchResults(
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
                  ),
                  _AnimatedSection(
                    visible: !vm.isPickingOnMap &&
                        vm.searchQuery.isEmpty &&
                        vm.searchResults.isEmpty &&
                        !vm.isSearching &&
                        vm.activeInput == LocationInputMode.origin &&
                        vm.origin == null,
                    sectionKey: 'currentLocation',
                    child: _CurrentLocationButton(onTap: onUseCurrentLocation),
                  ),
                  _AnimatedSection(
                    visible: vm.hasRoute && vm.step != TripSearchingStep.fareShown,
                    sectionKey: 'passengers',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PassengerSelector(
                          count: vm.numPersonas,
                          onChanged: notifier.setNumPersonas,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: vm.isLoading ? null : () => onRequestFare(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                            ),
                            child: vm.isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Estimar viaje'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (vm.step == TripSearchingStep.fareShown && vm.estimacion != null)
                    _AnimatedSection(
                      visible: true,
                      sectionKey: 'fareCard',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _EstimationCard(estimacion: vm.estimacion!),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => notifier.rejectFare(),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: vm.isLoading ? null : () => onConfirmTrip(),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                  ),
                                  child: vm.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Confirmar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    JalaAlertBanner(
                      message: vm.errorMessage!,
                      onDismiss: notifier.clearError,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTypeSelector extends StatelessWidget {
  const _ServiceTypeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.brand.divider,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ServiceTypeOption(
            icon: Icons.two_wheeler_rounded,
            label: 'Viaje',
            isActive: selected != TipoServicio.envio,
            onTap: () => onChanged(TipoServicio.viaje),
          ),
          _ServiceTypeOption(
            icon: Icons.inventory_2_rounded,
            label: 'Paquete',
            isActive: selected == TipoServicio.envio,
            onTap: () => onChanged(TipoServicio.envio),
          ),
        ],
      ),
    );
  }
}

class _ServiceTypeOption extends StatelessWidget {
  const _ServiceTypeOption({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? context.colors.surfaceContainerLow
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: context.colors.onSurface.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? JalaBrand.amber : context.brand.greyDark,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? context.colors.onSurface
                      : context.brand.greyDark,
                ),
              ),
            ],
          ),
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
        isOrigin: true,
        controller: originController,
        focusNode: originFocusNode,
        isActive: vm.activeInput == LocationInputMode.origin && !vm.isPickingOnMap,
        isPickingOnMap: vm.isPickingOnMap && vm.activeInput == LocationInputMode.origin,
        enabled: !vm.isPickingOnMap,
        onTap: () => notifier.activateOriginInput(),
        onPinTap: () {
          if (vm.isPickingOnMap && vm.activeInput == LocationInputMode.origin) {
            notifier.cancelPickOnMap();
          } else {
            notifier.activateOriginInput();
            notifier.startPickOnMap();
          }
        },
        onChanged: (value) {
          if (!vm.isPickingOnMap) {
            notifier.setSearchQuery(value);
          }
        },
        onClear: () {
          originController.clear();
          notifier.clearOrigin();
        },
      ),
      const SizedBox(height: 12),
      _LocationField(
        label: 'Destino',
        isOrigin: false,
        controller: destinationController,
        focusNode: destinationFocusNode,
        isActive: vm.activeInput == LocationInputMode.destination && !vm.isPickingOnMap,
        isPickingOnMap: vm.isPickingOnMap && vm.activeInput == LocationInputMode.destination,
        enabled: vm.origin != null && !vm.isPickingOnMap,
        onTap: () => notifier.activateDestinationInput(),
        onPinTap: () {
          if (vm.isPickingOnMap && vm.activeInput == LocationInputMode.destination) {
            notifier.cancelPickOnMap();
          } else if (vm.origin != null) {
            notifier.activateDestinationInput();
            notifier.startPickOnMap();
          }
        },
        onChanged: (value) {
          if (!vm.isPickingOnMap) {
            notifier.setSearchQuery(value);
          }
        },
        onClear: () {
          destinationController.clear();
          notifier.clearDestination();
        },
      ),
    ],
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  const _AnimatedSection({required this.visible, required this.child, this.sectionKey});

  final bool visible;
  final Widget child;
  final String? sectionKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: visible
            ? Padding(
                key: ValueKey(sectionKey ?? 'section'),
                padding: const EdgeInsets.only(top: 12),
                child: child,
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}

class _SectionSpacer extends StatelessWidget {
  const _SectionSpacer({required this.isVisible});

  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.hardEdge,
      child: isVisible ? const SizedBox(height: 12) : const SizedBox.shrink(),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.isOrigin,
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.isPickingOnMap,
    required this.enabled,
    required this.onTap,
    required this.onPinTap,
    required this.onChanged,
    required this.onClear,
  });

  final String label;
  final bool isOrigin;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final bool isPickingOnMap;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onPinTap;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: brand.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: brand.greyBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _PinSvg(isOrigin: isOrigin),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                onChanged: onChanged,
                style: context.text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar $label',
                  hintStyle: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: brand.greyLight,
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
            // Botón de limpiar: aparece cuando el campo tiene texto (para
            // vaciar y volver a elegir el punto). Oculto al elegir en el mapa.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, _) {
                if (value.text.isEmpty || !enabled || isPickingOnMap) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: colors.onSurfaceVariant),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? onPinTap : null,
              child: Icon(
                isPickingOnMap ? Icons.close : Icons.place,
                color: isPickingOnMap
                    ? colors.error
                    : enabled
                        ? colors.onSurfaceVariant
                        : brand.greyBorder,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pin SVG de origen (azul) o destino (naranja).
class _PinSvg extends StatelessWidget {
  const _PinSvg({required this.isOrigin, this.size = 20});

  final bool isOrigin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      isOrigin
          ? 'lib/shared/icons/Pin-Azul.svg'
          : 'lib/shared/icons/Pin-Naranja.svg',
      width: size,
      height: size * 1.2,
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
        color: context.brand.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.brand.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place, color: JalaBrand.amber, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mueve el mapa para seleccionar',
                  style: context.text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    textStyle: context.text.labelMedium,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedOpacity(
                  opacity: vm.isLoading ? 0.6 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: AnimatedScale(
                    scale: vm.isLoading ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: FilledButton.icon(
                      onPressed: vm.isLoading ? null : () => notifier.confirmPinFromMap(),
                      icon: vm.isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 16),
                      label: const Text('Confirmar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        textStyle: context.text.labelMedium,
                      ),
                    ),
                  ),
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
          color: context.brand.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.brand.greyBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.brand.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.my_location,
                color: context.brand.accentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Usar mi ubicacion actual',
              style: context.text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatefulWidget {
  const _SearchResults({
    required this.results,
    required this.isSearching,
    required this.onSelect,
  });

  final List<TripLocation> results;
  final bool isSearching;
  final void Function(TripLocation location) onSelect;

  @override
  State<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<_SearchResults> {
  int _previousCount = 0;

  @override
  void didUpdateWidget(covariant _SearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.results.length != oldWidget.results.length) {
      _previousCount = oldWidget.results.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSearching) {
      return Container(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.results.isEmpty) {
      return Container(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.all(16),
        child: Text(
          'No se encontraron resultados',
          style: context.text.bodyMedium?.copyWith(
            color: context.brand.greyDark,
          ),
        ),
      );
    }

    const itemHeight = 72.0;
    const visibleCount = 3;
    final maxHeight = itemHeight * visibleCount;
    final needsScroll = widget.results.length > visibleCount;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: needsScroll
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(bottom: needsScroll ? 24 : 0),
              itemCount: widget.results.length,
              itemBuilder: (context, index) {
                return _AnimatedSearchItem(
                  key: ValueKey(widget.results[index].address + index.toString()),
                  location: widget.results[index],
                  delay: index < _previousCount
                      ? Duration.zero
                      : Duration(milliseconds: 60 * (index - _previousCount).clamp(0, 4)),
                  onSelect: widget.onSelect,
                );
              },
            ),
            if (needsScroll)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.colors.surfaceContainerLowest.withValues(alpha: 0.0),
                        context.colors.surfaceContainerLowest.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Desliza para ver mas',
                    style: context.text.labelSmall?.copyWith(
                      color: context.brand.greyDark,
                      fontSize: 10,
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

class _AnimatedSearchItem extends StatefulWidget {
  const _AnimatedSearchItem({
    super.key,
    required this.location,
    required this.delay,
    required this.onSelect,
  });

  final TripLocation location;
  final Duration delay;
  final void Function(TripLocation location) onSelect;

  @override
  State<_AnimatedSearchItem> createState() => _AnimatedSearchItemState();
}

class _AnimatedSearchItemState extends State<_AnimatedSearchItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.value = 1.0;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onSelect(widget.location),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: JalaBrand.amber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: JalaBrand.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.location.placeName ?? widget.location.address,
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.location.address,
                          style: context.text.bodySmall?.copyWith(
                            color: context.brand.greyDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassengerSelector extends StatelessWidget {
  const _PassengerSelector({required this.count, required this.onChanged});

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.brand.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.brand.greyBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.group_rounded, size: 22, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            'Pasajeros',
            style: context.text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _PassengerButton(
                icon: Icons.remove_rounded,
                enabled: count > 1,
                onTap: () => onChanged(count - 1),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              _PassengerButton(
                icon: Icons.add_rounded,
                enabled: count < 3,
                onTap: () => onChanged(count + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassengerButton extends StatelessWidget {
  const _PassengerButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? JalaBrand.amber.withValues(alpha: 0.15)
              : context.brand.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? JalaBrand.amber : context.brand.greyBorder,
        ),
      ),
    );
  }
}

class _EstimationCard extends StatelessWidget {
  const _EstimationCard({required this.estimacion});

  final EstimacionViaje estimacion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.brand.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brand.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tarifa destacada
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${estimacion.tarifa.toStringAsFixed(0)}',
                style: context.text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'MXN',
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.brand.greyDark,
                ),
              ),
              const Spacer(),
              if (estimacion.tarifaEstimada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Estimada',
                    style: context.text.labelSmall?.copyWith(
                      color: context.brand.greyDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: context.colors.outlineVariant, height: 1),
          const SizedBox(height: 10),
          // Detalles: distancia/tiempo y personas/precio-unitario
          Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: context.brand.greyDark),
              const SizedBox(width: 6),
              if (estimacion.distanciaKm > 0)
                Text(
                  '${estimacion.distanciaKm.toStringAsFixed(1)} km · ${estimacion.duracionMin.toStringAsFixed(0)} min',
                  style: context.text.bodySmall?.copyWith(
                    color: context.brand.greyDark,
                  ),
                )
              else
                Text(
                  'Zona fija',
                  style: context.text.bodySmall?.copyWith(
                    color: context.brand.greyDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.group_rounded, size: 16, color: context.brand.greyDark),
              const SizedBox(width: 6),
              Text(
                '${estimacion.personas} ${estimacion.personas == 1 ? "persona" : "personas"} · \$${estimacion.tarifaPorPersona.toStringAsFixed(0)} c/u',
                style: context.text.bodySmall?.copyWith(
                  color: context.brand.greyDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

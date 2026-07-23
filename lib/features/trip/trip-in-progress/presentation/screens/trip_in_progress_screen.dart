import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/core_module.dart';
import '../../../../../core/http/api_client.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../shared/utils/svg_to_mapbox.dart';
import '../../../../../shared/widgets/auth_image_provider.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../../theme/jala_theme.dart';
import '../../../trip-searching/di/trip_searching_module.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/trip_tracking_service.dart';
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
  PointAnnotationManager? _driverMarkerManager;
  PointAnnotation? _driverMarker;
  PointAnnotationManager? _pinMarkerManager;
  PolylineAnnotation? _routeLine;
  List<Position> _routeCoords = [];
  int _routeIndex = 0;
  _RouteKind? _routeKind;
  bool _fetchingRoute = false;
  bool _pinImagesLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Asegura el socket conectado durante el viaje (idempotente).
      ref.read(socketServiceProvider).connect();
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
    try {
      _driverMarkerManager =
          await mapboxMap.annotations.createPointAnnotationManager();
    } catch (e) {
      debugPrint('[TripInProgress] DriverMarkerManager no disponible: $e');
    }
    try {
      _pinMarkerManager =
          await mapboxMap.annotations.createPointAnnotationManager();
    } catch (e) {
      debugPrint('[TripInProgress] PinMarkerManager no disponible: $e');
    }

    // El mapa puede recrearse (p.ej. cambio de tema claro/oscuro): el estilo
    // nuevo no tiene las imágenes ni las anotaciones anteriores.
    _pinImagesLoaded = false;
    _routeLine = null;
    _routeKind = null;
    _routeIndex = 0;
    _driverMarker = null;

    // Cargar pines PNG como imágenes de estilo del mapa
    await _loadPinImages();

    _drawOriginDestinationPins();
    _syncRoute();
    _fitRoute();

    // Si ya recibimos una posición del conductor antes de que el mapa estuviera
    // listo, dibújala de inmediato (no esperar al siguiente tick de 5 s).
    final pos = ref.read(tripInProgressViewModelProvider).driverPosition;
    if (pos != null) _updateDriverMarker(pos);
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
      final mototaxiOk = await addPngPinToMap(
        _mapboxMap!,
        'mototaxi-mapa',
        'lib/shared/icons/map-icons/MototaxiMapa.png',
        width: 40,
        height: 40,
      );
      // Marcar como cargado solo si TODAS las imágenes quedaron registradas.
      // Si alguna falló, no marcar — el caller reintentará en el siguiente tick.
      _pinImagesLoaded = verdeOk && naranjaOk && mototaxiOk;
      debugPrint('[TripInProgress] Pines cargados: verde=$verdeOk, naranja=$naranjaOk, mototaxi=$mototaxiOk');
    } catch (e) {
      debugPrint('[TripInProgress] Error cargando pines PNG: $e');
    }
  }

  /// Dibuja/actualiza la línea de ruta según la fase del viaje:
  /// aceptado → conductor→origen (se acorta al acercarse a recoger);
  /// en curso → origen→destino (se acorta al acercarse al destino);
  /// sin posición del conductor → ruta completa origen→destino.
  void _syncRoute() async {
    if (!mounted) return;
    final manager = _polylineManager;
    if (manager == null) return;

    final vmState = ref.read(tripInProgressViewModelProvider);
    final trip = vmState.trip ?? widget.trip;
    final pos = vmState.driverPosition;
    final toOrigin = trip.status == TripStatus.aceptado && pos != null;
    final kind = toOrigin ? _RouteKind.toOrigin : _RouteKind.trip;

    // La ruta de esta fase ya está dibujada: solo recortarla.
    if (kind == _routeKind && _routeLine != null) {
      if (pos != null && vmState.isActive) _trimRoute(pos);
      return;
    }
    if (_fetchingRoute) return;
    _fetchingRoute = true;

    final double fromLat, fromLng, toLat, toLng;
    if (toOrigin) {
      fromLat = pos.latitude;
      fromLng = pos.longitude;
      toLat = trip.origin.latitude;
      toLng = trip.origin.longitude;
    } else {
      fromLat = trip.origin.latitude;
      fromLng = trip.origin.longitude;
      toLat = trip.destination.latitude;
      toLng = trip.destination.longitude;
    }

    // Respaldo (línea recta) si OSRM no responde: la ruta y los pines SIEMPRE
    // deben verse mientras haya un viaje activo.
    var coordinates = <Position>[
      Position(fromLng, fromLat),
      Position(toLng, toLat),
    ];
    try {
      final repo = ref.read(tripSearchRepositoryProvider);
      final routeCoords = await repo.getRoute(
        originLat: fromLat,
        originLng: fromLng,
        destinationLat: toLat,
        destinationLng: toLng,
      );
      if (routeCoords.isNotEmpty) {
        coordinates = routeCoords.map((c) => Position(c[0], c[1])).toList();
      }
    } catch (e) {
      debugPrint('[TripInProgress] OSRM falló, uso línea recta: $e');
    }

    try {
      await manager.deleteAll();
      _routeLine = await manager.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: JalaBrand.amber.toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ));
      _routeCoords = coordinates;
      _routeIndex = 0;
      _routeKind = kind;
    } catch (e) {
      debugPrint('[TripInProgress] No se pudo dibujar la ruta: $e');
    } finally {
      _fetchingRoute = false;
    }
  }

  /// Recorta la línea al tramo que falta por recorrer (estilo Uber/DiDi).
  /// ponytail: recorte por vértice más cercano con avance monotónico; si la
  /// ruta se cruza consigo misma podría saltar tramo — proyección por
  /// segmento si algún día hace falta. Si el conductor se desvía, la línea
  /// no se recalcula (sin re-ruteo).
  void _trimRoute(DriverPosition pos) async {
    final line = _routeLine;
    if (line == null || _routeCoords.length < 2) return;

    var best = _routeIndex;
    var bestD = double.infinity;
    for (var i = _routeIndex; i < _routeCoords.length; i++) {
      final dLat = _routeCoords[i].lat - pos.latitude;
      final dLng = _routeCoords[i].lng - pos.longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestD) {
        bestD = d.toDouble();
        best = i;
      }
    }
    _routeIndex = best;

    try {
      line.geometry = LineString(coordinates: [
        Position(pos.longitude, pos.latitude),
        ..._routeCoords.sublist(best),
      ]);
      await _polylineManager?.update(line);
    } catch (e) {
      debugPrint('[TripInProgress] Error recortando ruta: $e');
    }
  }

  void _drawOriginDestinationPins() {
    final trip = widget.trip;
    if (_pinMarkerManager == null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pinMarkerManager != null && mounted) {
          _drawOriginDestinationPins();
        }
      });
      return;
    }

    if (!_pinImagesLoaded) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pinImagesLoaded && mounted) {
          _drawOriginDestinationPins();
        }
      });
      return;
    }

    try {
      _pinMarkerManager!.deleteAll();

      // Pin de origen (verde) — PNG
      _pinMarkerManager!.create(PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(trip.origin.longitude, trip.origin.latitude),
        ),
        iconImage: 'pin-verde',
        iconSize: 1.0,
      ));

      // Pin de destino (naranja) — PNG
      _pinMarkerManager!.create(PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(trip.destination.longitude, trip.destination.latitude),
        ),
        iconImage: 'pin-naranja',
        iconSize: 1.0,
      ));
    } catch (e) {
      debugPrint('[TripInProgress] Error dibujando pines: $e');
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

  void _updateDriverMarker(DriverPosition pos) async {
    if (!mounted) return;
    // Si las imágenes no están cargadas aún, cargarlas ahora y reintentar.
    if (!_pinImagesLoaded) {
      await _loadPinImages();
      if (!_pinImagesLoaded) {
        debugPrint('[TripInProgress] Pines no cargados aún, reintentando...');
        return;
      }
    }

    final manager = _driverMarkerManager;
    if (manager == null) {
      debugPrint('[TripInProgress] DriverMarkerManager no disponible');
      return;
    }

    // Solo mostrar el marcador si el viaje está aceptado o en curso.
    final status = ref.read(tripInProgressViewModelProvider).trip?.status;
    if (status != TripStatus.aceptado && status != TripStatus.enCurso) return;

    final point = Point(coordinates: Position(pos.longitude, pos.latitude));
    try {
      if (_driverMarker == null) {
        // Mototaxi del conductor (mismo icono de map-icons que el resto de pines).
        _driverMarker = await manager.create(PointAnnotationOptions(
          geometry: point,
          iconImage: 'mototaxi-mapa',
          iconSize: 1.0,
        ));
        debugPrint('[TripInProgress] Marcador del conductor creado en (${pos.latitude}, ${pos.longitude})');
      } else {
        // Mover el marcador existente (no recrear: evita parpadeo).
        _driverMarker!.geometry = point;
        await manager.update(_driverMarker!);
      }
    } catch (e) {
      debugPrint('[TripInProgress] Error actualizando marcador del conductor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    ref.listen<TripInProgressViewModelState>(
      tripInProgressViewModelProvider,
      (previous, next) {
        if (!mounted) return;

        // Actualizar marcador del conductor y recortar la ruta en tiempo real
        if (next.driverPosition != null &&
            next.driverPosition != previous?.driverPosition) {
          debugPrint('[TripInProgress] DriverPosition recibida: ${next.driverPosition!.latitude}, ${next.driverPosition!.longitude}');
          _updateDriverMarker(next.driverPosition!);
          _syncRoute();
        }

        // Cambio de fase (p.ej. aceptado → en curso): redibujar la ruta.
        if (next.trip?.status != previous?.trip?.status) {
          debugPrint('[TripInProgress] Status cambió: ${previous?.trip?.status} → ${next.trip?.status}');
          _syncRoute();
        }

        // Al completar: pasar a calificar al conductor. Al cancelar: ir al home.
        final status = next.trip?.status;
        if (status == TripStatus.completado) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.tripEvaluation,
            (route) => false,
            arguments: next.trip,
          );
        } else if (status == TripStatus.cancelado) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.passengerHome,
            (route) => false,
          );
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final status = ref.read(tripInProgressViewModelProvider).trip?.status;
        if (status == TripStatus.solicitado ||
            status == TripStatus.aceptado ||
            status == TripStatus.enCurso) {
          _showExitConfirm(context);
        }
      },
      child: Scaffold(
      body: Stack(
        children: [
          // Mapa estatico: no depende del estado, asi que los ticks de
          // posicion del conductor (sub-segundo) ya no lo reconstruyen.
          JalaMapView(
            onMapCreated: _onMapCreated,
            showLocationMarker: false,
            showCurrentLocationPin: true,
          ),
          Positioned(
            top: topPad + 16,
            left: 24,
            child: JalaBackButton(
              onTap: () {
                final status = ref.read(tripInProgressViewModelProvider).trip?.status;
                if (status == TripStatus.completado || status == TripStatus.cancelado) {
                  Navigator.of(context).pop();
                } else {
                  _showExitConfirm(context);
                }
              },
            ),
          ),
          // Panel: se reconstruye con el viaje (poll de 5s) o isLoading,
          // NO en cada tick de driverPosition (que no se renderiza).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer(
              builder: (context, ref, _) {
                final trip = ref.watch(tripInProgressViewModelProvider
                        .select((s) => s.trip)) ??
                    widget.trip;
                final isLoading = ref.watch(
                  tripInProgressViewModelProvider.select((s) => s.isLoading),
                );
                // ETA del backend: solo rebuild cuando cambia el minuto,
                // no en cada tick de posición.
                final etaMin = ref.watch(
                  tripInProgressViewModelProvider.select((s) => s.etaMin),
                );
                return _TripBottomPanel(
                  trip: trip,
                  etaMin: etaMin,
                  isLoading: isLoading,
                  bottomPad: bottomPad,
                  onCancel: () => _showCancelDialog(context),
                  onCallDriver: _callDriver,
                  apiClient: ref.read(apiClientProvider),
                );
              },
            ),
          ),
        ],
      ),
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
    final motivo = await _CancelReasonDialog.show(context);
    if (motivo != null && motivo.isNotEmpty) {
      ref.read(tripInProgressViewModelProvider.notifier).cancelTrip(motivo: motivo);
    }
  }

  void _callDriver(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo llamar al $phone')),
        );
      }
    }
  }
}

class _TripBottomPanel extends StatefulWidget {
  const _TripBottomPanel({
    required this.trip,
    required this.etaMin,
    required this.isLoading,
    required this.bottomPad,
    required this.onCancel,
    required this.onCallDriver,
    required this.apiClient,
  });

  final Trip trip;
  final int? etaMin;
  final bool isLoading;
  final double bottomPad;
  final VoidCallback onCancel;
  final void Function(String phone) onCallDriver;
  final ApiClient apiClient;

  @override
  State<_TripBottomPanel> createState() => _TripBottomPanelState();
}

class _TripBottomPanelState extends State<_TripBottomPanel>
    with SingleTickerProviderStateMixin {
  static final _whitespace = RegExp(r'\s+');
  static const _searchStart = 0.1;
  static const _searchEnd = 0.63;

  AnimationController? _searchController;
  Timer? _countdownTimer;
  bool _wasSearching = false;
  String _countdownText = '';

  Trip get trip => widget.trip;

  @override
  void initState() {
    super.initState();
    _ensureSearchController();
  }

  @override
  void didUpdateWidget(_TripBottomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSearchController();
  }

  Duration get _searchDuration {
    final expiraEn = trip.expiraEn;
    if (expiraEn == null) return const Duration(minutes: 5);
    final remaining = expiraEn.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  void _ensureSearchController() {
    final isSearching = trip.status == TripStatus.solicitado;

    if (isSearching && !_wasSearching) {
      _searchController?.dispose();
      _countdownTimer?.cancel();

      final duration = _searchDuration;
      _updateCountdownText();

      _searchController = AnimationController(
        vsync: this,
        duration: duration,
        lowerBound: _searchStart,
        upperBound: _searchEnd,
        value: _searchStart,
      )..forward();

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateCountdownText();
      });

      _wasSearching = true;
    } else if (!isSearching && _wasSearching) {
      _searchController?.stop();
      _searchController?.dispose();
      _searchController = null;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _countdownText = '';
      _wasSearching = false;
    }
  }

  void _updateCountdownText() {
    final expiraEn = trip.expiraEn;
    if (expiraEn == null) {
      setState(() => _countdownText = '');
      return;
    }
    final remaining = expiraEn.difference(DateTime.now());
    if (remaining.isNegative) {
      setState(() => _countdownText = '0:00');
      return;
    }
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    setState(() {
      _countdownText = '$minutes:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController?.dispose();
    super.dispose();
  }

  String get _statusTitle {
    switch (trip.status) {
      case TripStatus.solicitado:
        return 'Buscando mototaxi';
      case TripStatus.aceptado:
        return 'Llega tu mototaxi';
      case TripStatus.enCurso:
        return 'En viaje';
      case TripStatus.completado:
        return 'Viaje completado';
      case TripStatus.cancelado:
        return trip.canceladoPor == 'sistema'
            ? 'Sin conductor disponible'
            : 'Viaje cancelado';
    }
  }

  String get _statusSubtitle {
    switch (trip.status) {
      case TripStatus.solicitado:
        if (_countdownText.isNotEmpty) {
          return 'Expira en $_countdownText';
        }
        return 'Esperando conductor';
      case TripStatus.aceptado:
        final eta = widget.etaMin;
        return eta != null
            ? 'Llega en ~$eta min'
            : 'Tu mototaxi esta en camino';
      case TripStatus.enCurso:
        final eta = widget.etaMin;
        return eta != null
            ? 'Llegas a tu destino en ~$eta min'
            : 'Dirigete a tu destino';
      case TripStatus.completado:
        return 'Gracias por usar Jala';
      case TripStatus.cancelado:
        return trip.canceladoPor == 'sistema'
            ? 'Intenta de nuevo'
            : 'El viaje fue cancelado';
    }
  }

  double get _progress {
    if (trip.status == TripStatus.solicitado) {
      return _searchController?.value ?? _searchStart;
    }
    switch (trip.status) {
      case TripStatus.aceptado:
        return 0.63;
      case TripStatus.enCurso:
        return 0.85;
      case TripStatus.completado:
        return 1.0;
      case TripStatus.cancelado:
        return 0.0;
      default:
        return _searchStart;
    }
  }

  String get _driverInitials {
    final name = trip.driverName ?? '??';
    final parts = name.split(_whitespace);
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  bool get _isSearching => trip.status == TripStatus.solicitado;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 14, 24, widget.bottomPad + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Text(
                _statusTitle,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: Text(
                _statusSubtitle,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: context.brand.greyDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Barra de progreso animada
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: _searchController != null
                    ? AnimatedBuilder(
                        animation: _searchController!,
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: _searchController!.value,
                            minHeight: 6,
                            backgroundColor: context.brand.divider,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(JalaBrand.amber),
                          );
                        },
                      )
                    : LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: context.brand.divider,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(JalaBrand.amber),
                      ),
              ),
            ),
            // Contenido condicional
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _isSearching
                  ? FadeSlideIn(
                      key: const ValueKey('searching'),
                      delay: Duration.zero,
                      child: _TripSummaryCard(trip: trip),
                    )
                  : Column(
                      key: ValueKey('driver-${trip.id}'),
                      children: [
                        const SizedBox(height: 20),
                        _DriverCard(
                          initials: _driverInitials,
                          name: trip.driverName ?? 'Conductor',
                          rating: trip.driverRating?.toStringAsFixed(1),
                          vehicleInfo: trip.vehicleInfo?.isNotEmpty == true
                              ? trip.vehicleInfo!
                              : 'Mototaxi',
                          plate: trip.vehiclePlaca ?? 'Sin placa',
                          idConductor: trip.idConductor,
                          apiClient: widget.apiClient,
                          phone: trip.driverPhone,
                        ),
                        const SizedBox(height: 16),
                        if (trip.driverPhone != null)
                          _ActionButton(
                            label: 'Llamar',
                            icon: Icons.phone_rounded,
                            isOutlined: false,
                            onTap: () => widget.onCallDriver(trip.driverPhone!),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Divider(color: context.brand.divider, height: 1),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: widget.isLoading ? null : widget.onCancel,
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Cancelar viaje',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.brand.destructive,
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

/// Tarjeta con origen, destino y tarifa — visible mientras busca conductor.
class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.brand.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _RouteRow(
            text: trip.origin.address,
            isOrigin: true,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(
              height: 16,
              width: 2,
              color: context.brand.greyBorder,
            ),
          ),
          _RouteRow(
            text: trip.destination.address,
            isOrigin: false,
          ),
          const SizedBox(height: 12),
          Divider(color: context.brand.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tarifa',
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.brand.greyDark,
                ),
              ),
              Text(
                '\$${trip.fare.totalFare.toStringAsFixed(2)} MXN',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.text,
    required this.isOrigin,
  });

  final String text;
  final bool isOrigin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          isOrigin
              ? 'lib/shared/icons/Pin-Azul.svg'
              : 'lib/shared/icons/Pin-Naranja.svg',
          width: 15,
          height: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
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
    required this.apiClient,
    this.idConductor,
    this.phone,
  });

  final String initials;
  final String name;
  final String? rating;
  final String vehicleInfo;
  final String plate;
  final ApiClient apiClient;
  final int? idConductor;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.brand.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _avatar(context),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star_rounded, size: 14, color: JalaBrand.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating!,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        vehicleInfo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: context.brand.greyDark,
                        ),
                      ),
                    ),
                  ],
                ),
                if (idConductor != null)
                  JalaReputationChips(idUsuario: idConductor!, rol: 'conductor'),
                if (phone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: context.brand.greyDark),
                      const SizedBox(width: 4),
                      Text(
                        phone!,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: context.brand.greyDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.inverseSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              plate,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colors.onInverseSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final fallback = Text(
      initials,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
    return ClipOval(
      child: Container(
        width: 52,
        height: 52,
        color: JalaBrand.amber,
        alignment: Alignment.center,
        child: idConductor == null
            ? fallback
            : Image(
                image: AuthImageProvider(userId: idConductor!, apiClient: apiClient),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.isOutlined = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isOutlined;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final height = 52.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: JalaBrand.amber,
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
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  static const List<String> _reasons = [
    'Ya no necesito el viaje',
    'El conductor tarda mucho',
    'Cambié de opinión',
    'Otro',
  ];

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CancelReasonDialog(),
    );
  }

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  String? _selectedReason;
  final _otherController = TextEditingController();
  bool _isOpen = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    if (_selectedReason == null) return false;
    if (_selectedReason == 'Otro') {
      return _otherController.text.trim().isNotEmpty;
    }
    return true;
  }

  String? get _motivo {
    if (_selectedReason == null) return null;
    if (_selectedReason == 'Otro') {
      final text = _otherController.text.trim();
      return text.isEmpty ? null : text;
    }
    return _selectedReason;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        // Teclado (viewInsets) + barra de navegacion del telefono (padding),
        // sin doble conteo: el boton de confirmar ya no queda tapado abajo.
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: JalaBrand.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 22, color: JalaBrand.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancelar viaje',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¿Por qué quieres cancelar?',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.help_outline_rounded, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedReason ?? 'Selecciona un motivo',
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _selectedReason != null
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _isOpen
                    ? Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.onSurface.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _CancelReasonDialog._reasons.length,
                      itemBuilder: (context, index) {
                        final reason = _CancelReasonDialog._reasons[index];
                        final isSelected = _selectedReason == reason;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 20,
                            color: isSelected ? JalaBrand.amber : scheme.onSurfaceVariant,
                          ),
                          title: Text(
                            reason,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedReason = reason;
                              _isOpen = false;
                            });
                          },
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_selectedReason == 'Otro') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otherController,
              autofocus: true,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              style: text.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Escribe el motivo...',
                hintStyle: text.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.isDark ? JalaBrand.amberDeep : JalaBrand.ink, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _canConfirm
                  ? () => Navigator.of(context).pop(_motivo)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: JalaBrand.amber,
                disabledBackgroundColor: scheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirmar cancelación',
                style: text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _canConfirm ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Qué tramo representa la línea dibujada en el mapa.
enum _RouteKind {
  /// Conductor → origen (viaje aceptado, va a recoger al pasajero).
  toOrigin,

  /// Origen → destino (viaje en curso o aún sin posición del conductor).
  trip,
}

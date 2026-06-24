import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../theme/theme.dart';

class JalaPinMarker extends StatelessWidget {
  const JalaPinMarker({
    super.key,
    this.pinColor = Colors.white,
    this.accentColor = const Color(0xFFFF8F00),
  });

  final Color pinColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: CustomPaint(
          size: const Size(48, 62),
          painter: _PinPainter(pinColor: pinColor, accentColor: accentColor),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.pinColor, required this.accentColor});

  final Color pinColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.cubicTo(
      size.width / 2,
      size.height * 0.65,
      0,
      size.height * 0.45,
      0,
      size.height * 0.3,
    );
    path.arcTo(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.3),
        radius: size.width / 2,
      ),
      3.14159,
      3.14159,
      false,
    );
    path.cubicTo(
      size.width,
      size.height * 0.45,
      size.width / 2,
      size.height * 0.65,
      size.width / 2,
      size.height,
    );
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.25), 4.0, false);

    canvas.drawPath(
      path,
      Paint()
        ..color = pinColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.3),
      size.width * 0.2,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.3),
      size.width * 0.1,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JalaLocationMarker extends StatelessWidget {
  const JalaLocationMarker({
    super.key,
    this.outerSize = 64,
    this.innerSize = 18,
    this.markerColor = const Color(0xFFFF8F00),
  });

  final double outerSize;
  final double innerSize;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          color: markerColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JalaMapView extends StatefulWidget {
  const JalaMapView({
    super.key,
    required this.onMapCreated,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZoom = 2.0,
    this.showLocationMarker = false,
    this.showPinMarker = false,
    this.showCurrentLocationPin = true,
    this.onMapIdle,
    this.onCameraChanged,
    this.autoLocate = true,
  });

  final void Function(MapboxMap) onMapCreated;
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialZoom;
  final bool showLocationMarker;
  final bool showPinMarker;
  final bool showCurrentLocationPin;
  final void Function(CameraChangedEventData)? onCameraChanged;
  final void Function(MapIdleEventData)? onMapIdle;
  final bool autoLocate;

  @override
  State<JalaMapView> createState() => _JalaMapViewState();
}

class _JalaMapViewState extends State<JalaMapView> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  geo.Position? _currentPosition;
  bool _located = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoLocate &&
        widget.initialLatitude == null &&
        widget.initialLongitude == null) {
      _resolveCurrentLocation();
    }
  }

  Future<void> _resolveCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      final lastKnown = await geo.Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
        _flyToCurrent(lastKnown.latitude, lastKnown.longitude);
        _tryAddCurrentLocationPin();
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _currentPosition = position);
      _flyToCurrent(position.latitude, position.longitude);
      _tryAddCurrentLocationPin();
    } catch (e) {
      debugPrint('[JalaMapView] Error obteniendo ubicacion: $e');
    }
  }

  void _flyToCurrent(double latitude, double longitude) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 1000, startDelay: 0),
    );
  }

  Future<void> _tryAddCurrentLocationPin() async {
    if (!widget.showCurrentLocationPin) return;
    if (_mapboxMap == null || _currentPosition == null) return;

    try {
      _circleManager ??=
          await _mapboxMap!.annotations.createCircleAnnotationManager();
      _circleManager!.deleteAll();

      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final amber = JalaBrand.amber.toARGB32();

      await _circleManager!.createMulti([
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleColor: amber,
          circleRadius: 22.0,
          circleOpacity: 0.18,
          circleStrokeWidth: 0,
        ),
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleColor: amber,
          circleRadius: 10.0,
          circleOpacity: 0.9,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3.0,
        ),
      ]);
    } catch (e) {
      debugPrint('[JalaMapView] CircleAnnotation no disponible: $e');
      _circleManager = null;
    }
  }

  void _handleMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _hideMapOrnaments(mapboxMap);
    if (!_located && _currentPosition != null) {
      _located = true;
      _flyToCurrent(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    _tryAddCurrentLocationPin();
    widget.onMapCreated(mapboxMap);
  }

  void _hideMapOrnaments(MapboxMap mapboxMap) {
    try {
      mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    } catch (_) {}
    try {
      mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    } catch (_) {}
    try {
      mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    } catch (_) {}
    try {
      mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.initialLatitude ?? _currentPosition?.latitude;
    final lng = widget.initialLongitude ?? _currentPosition?.longitude;
    final hasPosition = lat != null && lng != null;

    return Stack(
      children: [
        Positioned.fill(
          child: MapWidget(
            key: const ValueKey("jalaMapWidget"),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  lng ?? 0,
                  lat ?? 0,
                ),
              ),
              zoom: hasPosition ? 16.0 : widget.initialZoom,
            ),
            onMapCreated: _handleMapCreated,
            onCameraChangeListener: widget.onCameraChanged,
            onMapIdleListener: widget.onMapIdle,
          ),
        ),
        if (widget.showLocationMarker)
          Positioned.fill(
            child: IgnorePointer(
              child: JalaLocationMarker(),
            ),
          ),
        if (widget.showPinMarker)
          Positioned.fill(
            child: IgnorePointer(
              child: JalaPinMarker(),
            ),
          ),
      ],
    );
  }
}

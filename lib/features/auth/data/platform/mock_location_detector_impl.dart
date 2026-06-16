import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/services/mock_location_detector.dart';

class MockLocationDetectorImpl implements MockLocationDetector {
  static const MethodChannel _channel =
      MethodChannel('app.viajeseguro/mock_location');

  @override
  Future<bool> isMockLocationActive() async {
    if (!Platform.isAndroid) return false;

    try {
      // 1. Verificar vía Settings (MethodChannel) - Es lo más rápido
      final fromSettings = await _isMockLocationEnabledFromSettings()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (fromSettings) return true;

      // 2. Verificar vía Geolocator (Posición real)
      final permissionGranted = await _ensureLocationPermission()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (!permissionGranted) return false;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Cambiado a low para mayor rapidez en emuladores
        timeLimit: const Duration(seconds: 4),
      );
      return position.isMocked;
    } catch (e) {
      // Si algo falla o hay timeout, asumimos que no hay mock para no bloquear al usuario
      return false;
    }
  }

  Future<bool> _isMockLocationEnabledFromSettings() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isMockLocationEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }
}

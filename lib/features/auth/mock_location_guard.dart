import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class MockLocationGuard {
  static const MethodChannel _channel =
      MethodChannel('app.viajeseguro/mock_location');

  Future<bool> isMockLocationEnabled() async {
    if (!Platform.isAndroid) return false;

    final fromSettings = await _isMockLocationEnabledFromSettings();
    if (fromSettings) return true;

    final permissionGranted = await _ensureLocationPermission();
    if (!permissionGranted) return false;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      return position.isMocked;
    } on TimeoutException {
      return false;
    } on Exception {
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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

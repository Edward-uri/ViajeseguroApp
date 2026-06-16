import 'dart:io';
import 'package:flutter/services.dart';
import '../../domain/services/usb_debug_detector.dart';

class UsbDebugDetectorImpl implements UsbDebugDetector {
  static const MethodChannel _channel =
      MethodChannel('app.viajeseguro/security');

  @override
  Future<bool> isUsbDebuggingActive() async {
    // Solo aplica para Android
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isUsbDebuggingEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}

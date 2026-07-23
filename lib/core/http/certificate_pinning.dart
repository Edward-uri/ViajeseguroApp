import 'package:flutter/foundation.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

/// Servicio de SSL/TLS Certificate Pinning.
///
/// Valida que el certificado del servidor sea el esperado antes de cada
/// petición HTTP, protegiendo contra ataques Man-in-the-Middle (MitM).
class CertificatePinning {
  CertificatePinning._();

  static final CertificatePinning instance = CertificatePinning._();

  /// SHA-256 fingerprint del certificado de api.codigoverse.space.
  static const String _productionFingerprint =
      '05:C8:4A:CB:C3:3A:83:8B:CF:E7:5E:FC:31:31:B6:CE:'
      '92:5A:12:3E:61:41:9D:82:6F:5A:6E:41:61:BA:7A:47';

  static const String _serverUrl = 'https://api.codigoverse.space';

  bool _lastCheckResult = true;
  bool get isSecure => _lastCheckResult;

  /// Valida que el certificado del servidor coincida con el fingerprint
  /// configurado. Retorna `true` si es seguro, `false` si se detectó
  /// un certificado sospechoso (posible interceptación MitM).
  Future<bool> check() async {
    try {
      final result = await HttpCertificatePinning.check(
        serverURL: _serverUrl,
        sha: SHA.SHA256,
        allowedSHAFingerprints: [_productionFingerprint],
        timeout: 30000,
      );
      // check() retorna "CONNECTION_SECURE" si el certificado es válido
      _lastCheckResult = result == 'CONNECTION_SECURE';
      return _lastCheckResult;
    } catch (e) {
      debugPrint('[CertificatePinning] Error verificando certificado: $e');
      _lastCheckResult = false;
      return false;
    }
  }
}

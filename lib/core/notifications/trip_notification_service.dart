import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificación persistente del viaje activo (estilo Uber/DiDi):
/// muestra el estado y el ETA del conductor, y se actualiza en segundo plano
/// con cada tick de ubicación mientras el proceso siga vivo (el socket sigue
/// recibiendo eventos con la app minimizada).
///
/// Sonido y vibración: el canal se crea con ambos habilitados y las
/// actualizaciones usan `onlyAlertOnce`, así solo suena/vibra al aparecer o
/// cuando se fuerza una alerta (cambio de fase), no en cada tick de ETA.
class TripNotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const _notificationId = 7001;

  /// Id distinto para la notificación final: así `cancel()` (que limpia la
  /// persistente) no borra el aviso de viaje terminado.
  static const _finishedId = 7002;

  static const _channel = AndroidNotificationChannel(
    'viaje_activo',
    'Viaje activo',
    description: 'Estado y tiempo de llegada de tu mototaxi',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
      // Android 13+: permiso de notificaciones en runtime (no-op si ya se dio).
      await android?.requestNotificationsPermission();
      _initialized = true;
    } catch (e) {
      debugPrint('[TripNotification] Error inicializando: $e');
    }
    return _initialized;
  }

  /// Muestra o actualiza la notificación del viaje.
  /// Con [alert] true vuelve a sonar/vibrar (p.ej. conductor asignado,
  /// viaje iniciado); si es false la actualización es silenciosa.
  Future<void> update({
    required String title,
    required String body,
    bool alert = false,
  }) async {
    if (!await _ensureInitialized()) return;
    try {
      if (alert) {
        // Cancelar resetea onlyAlertOnce para que la nueva fase sí alerte.
        await _plugin.cancel(id: _notificationId);
      }
      await _plugin.show(
        id: _notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: false,
            category: AndroidNotificationCategory.navigation,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBanner: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[TripNotification] Error mostrando notificación: $e');
    }
  }

  /// Aviso final con sonido y vibración (viaje terminado): reemplaza la
  /// notificación persistente por una normal que el usuario puede descartar.
  Future<void> finish({required String title, required String body}) async {
    if (!await _ensureInitialized()) return;
    try {
      await _plugin.cancel(id: _notificationId);
      await _plugin.show(
        id: _finishedId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBanner: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[TripNotification] Error en aviso final: $e');
    }
  }

  /// Quita la notificación (viaje completado/cancelado o pantalla cerrada).
  Future<void> cancel() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (e) {
      debugPrint('[TripNotification] Error cancelando: $e');
    }
  }
}

/// Servicio de mensajería push (FCM).
///
/// Encapsula permisos, suscripción a topics y registro de handlers, para que el
/// resto de la app no dependa directamente de `firebase_messaging`.
abstract class PushMessagingService {
  /// Inicializa el servicio: pide permisos, se suscribe al topic del usuario y
  /// registra los listeners de mensajes en primer plano.
  Future<void> initialize();
}

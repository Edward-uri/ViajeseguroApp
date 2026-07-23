/// Tipo de servicio de un viaje.
///
/// Los valores coinciden con el enum `tipo_servicio_viaje` del backend
/// ('viaje' | 'envio'); NO cambiar sin actualizar el backend.
abstract class TipoServicio {
  const TipoServicio._();

  static const String viaje = 'viaje';
  static const String envio = 'envio';

  /// Etiqueta legible para mostrar al usuario.
  static String label(String tipo) => tipo == envio ? 'Paquete' : 'Viaje';
}

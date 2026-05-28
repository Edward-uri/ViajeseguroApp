class User {
  const User({
    required this.idUsuario,
    required this.nombreUsuario,
    required this.rol,
    required this.estadoCuenta,
    this.fechaRegistro,
    this.fotoPerfilUrl,
  });

  final int idUsuario;
  final String nombreUsuario;

  /// `pasajero` | `conductor` | `propietario` | `admin`
  final String rol;

  /// `activo` | `suspendido` | `eliminado`
  final String estadoCuenta;

  final DateTime? fechaRegistro;
  final String? fotoPerfilUrl;
///funciona como react, solo renderiza lo que se actualiza y no hace la carga de lo que no cambio
  User copyWith({String? fotoPerfilUrl, String? estadoCuenta}) {
    return User(
      idUsuario: idUsuario,
      nombreUsuario: nombreUsuario,
      rol: rol,
      estadoCuenta: estadoCuenta ?? this.estadoCuenta,
      fechaRegistro: fechaRegistro,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
    );
  }
}

class User {
  const User({
    required this.idUsuario,
    required this.telefono,
    required this.correoElectronico,
    required this.rol,
    required this.estadoCuenta,
    required this.telefonoVerificado,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.idMunicipio,
    this.fotoPerfilUrl,
    this.fechaRegistro,
  });

  final int idUsuario;
  final String telefono;
  final String? correoElectronico;
  final String rol;
  final String estadoCuenta;
  final bool telefonoVerificado;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final int? idMunicipio;
  final String? fotoPerfilUrl;
  final DateTime? fechaRegistro;

  String get nombreUsuario => correoElectronico ?? telefono;

  String get nombreCompleto {
    final parts = <String>[
      if (nombre != null && nombre!.isNotEmpty) nombre!,
      if (apellidoPaterno != null && apellidoPaterno!.isNotEmpty) apellidoPaterno!,
      if (apellidoMaterno != null && apellidoMaterno!.isNotEmpty) apellidoMaterno!,
    ];
    if (parts.isEmpty) return 'Pasajero';
    return parts.join(' ');
  }

  String get nombreParaMostrar {
    if (nombre != null && nombre!.isNotEmpty) return nombre!;
    if (apellidoPaterno != null && apellidoPaterno!.isNotEmpty) return apellidoPaterno!;
    return 'Pasajero';
  }

  String get iniciales {
    String i = '';
    if (nombre != null && nombre!.isNotEmpty) i += nombre![0];
    if (apellidoPaterno != null && apellidoPaterno!.isNotEmpty) i += apellidoPaterno![0];
    if (i.isEmpty) {
      final fallback = nombreUsuario;
      if (fallback.isNotEmpty) return fallback[0].toUpperCase();
      return '?';
    }
    return i.toUpperCase();
  }

  User copyWith({
    String? fotoPerfilUrl,
    String? estadoCuenta,
    bool? telefonoVerificado,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) {
    return User(
      idUsuario: idUsuario,
      telefono: telefono,
      correoElectronico: correoElectronico,
      rol: rol,
      estadoCuenta: estadoCuenta ?? this.estadoCuenta,
      telefonoVerificado: telefonoVerificado ?? this.telefonoVerificado,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      idMunicipio: idMunicipio,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      fechaRegistro: fechaRegistro,
    );
  }
}

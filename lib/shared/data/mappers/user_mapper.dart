import '../../domain/entities/user.dart';

class UserMapper {
  const UserMapper._();

  static User fromJson(Map<String, dynamic> json) {
    return User(
      idUsuario: _parseInt(json['idUsuario'] ?? json['id'] ?? 0),
      telefono: (json['telefono'] ?? json['phone'] ?? '').toString(),
      correoElectronico: json['correoElectronico'] as String? ?? json['correo'] as String?,
      rol: (json['rol'] ?? json['role'] ?? 'pasajero').toString(),
      estadoCuenta: (json['estadoCuenta'] ?? json['estado'] ?? 'activo').toString(),
      telefonoVerificado: json['telefonoVerificado'] as bool? ?? false,
      nombre: json['nombre'] as String? ?? json['name'] as String?,
      apellidoPaterno: json['apellidoPaterno'] as String?,
      apellidoMaterno: json['apellidoMaterno'] as String?,
      idMunicipio: _parseNullableInt(json['idMunicipio']),
      fotoPerfilUrl: json['fotoPerfilUrl'] as String? ?? json['foto'] as String?,
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.tryParse(json['fechaRegistro'].toString())
          : null,
    );
  }

  static Map<String, dynamic> toJson(User user) => <String, dynamic>{
        'idUsuario': user.idUsuario,
        'telefono': user.telefono,
        'correoElectronico': user.correoElectronico,
        'rol': user.rol,
        'estadoCuenta': user.estadoCuenta,
        'telefonoVerificado': user.telefonoVerificado,
        'nombre': user.nombre,
        'apellidoPaterno': user.apellidoPaterno,
        'apellidoMaterno': user.apellidoMaterno,
        'idMunicipio': user.idMunicipio,
        'fotoPerfilUrl': user.fotoPerfilUrl,
        'fechaRegistro': user.fechaRegistro?.toIso8601String(),
      };

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

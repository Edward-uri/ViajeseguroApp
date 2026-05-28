import '../../domain/entities/user.dart';


class UserMapper {
  const UserMapper._();

  static User fromJson(Map<String, dynamic> json) {
    return User(
      idUsuario: (json['idUsuario'] as num).toInt(),
      nombreUsuario: json['nombreUsuario'] as String,
      rol: json['rol'] as String,
      estadoCuenta: json['estadoCuenta'] as String,
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.tryParse(json['fechaRegistro'].toString())
          : null,
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
    );
  }

  static Map<String, dynamic> toJson(User user) => <String, dynamic>{
        'idUsuario': user.idUsuario,
        'nombreUsuario': user.nombreUsuario,
        'rol': user.rol,
        'estadoCuenta': user.estadoCuenta,
        'fechaRegistro': user.fechaRegistro?.toIso8601String(),
        'fotoPerfilUrl': user.fotoPerfilUrl,
      };
}

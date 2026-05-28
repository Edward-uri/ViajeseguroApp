import '../../domain/entities/register_params.dart';


class RegisterParamsMapper {
  const RegisterParamsMapper._();

  static Map<String, dynamic> toJson(RegisterParams p) => <String, dynamic>{
        'nombreUsuario': p.nombreUsuario,
        'password': p.password,
        'rol': p.rol,
        'nombre': p.nombre,
        'apellidoPaterno': p.apellidoPaterno,
        if (p.apellidoMaterno != null) 'apellidoMaterno': p.apellidoMaterno,
        if (p.idSexo != null) 'idSexo': p.idSexo,
        'correoElectronico': p.correoElectronico,
        if (p.telefono != null) 'telefono': p.telefono,
        if (p.fechaNacimiento != null) 'fechaNacimiento': p.fechaNacimiento,
      };
}

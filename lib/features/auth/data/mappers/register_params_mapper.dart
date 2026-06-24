import '../../domain/entities/register_params.dart';

class RegisterParamsMapper {
  const RegisterParamsMapper._();

  static Map<String, dynamic> toJson(RegisterParams p) => <String, dynamic>{
        'registrationToken': p.registrationToken,
        'nombre': p.nombre,
        'apellidoPaterno': p.apellidoPaterno,
        'password': p.contrasena,
        if (p.apellidoMaterno != null) 'apellidoMaterno': p.apellidoMaterno,
        if (p.telefono != null) 'telefono': p.telefono,
        if (p.idSexo != null) 'idSexo': p.idSexo,
        if (p.fechaNacimiento != null) 'fechaNacimiento': p.fechaNacimiento,
        if (p.idMunicipio != null) 'idMunicipio': p.idMunicipio,
        if (p.dispositivo != null) 'dispositivo': p.dispositivo,
      };
}

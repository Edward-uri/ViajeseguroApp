abstract class ApiRoutes {
  const ApiRoutes._();

  static const String authBase = '/api/auth';
  static const String registerStart = '$authBase/register/start';
  static const String registerVerify = '$authBase/register/verify';
  static const String registerComplete = '$authBase/register/complete';
  static const String loginPassword = '$authBase/login/password';
  static const String refresh = '$authBase/refresh';
  static const String logout = '$authBase/logout';

  static const String municipios = '/api/municipios';

  static const String viajesBase = '/api/viajes';
  static const String viajes = viajesBase;
  static const String viajesMios = '$viajesBase/mios';
  static const String viajeCancelar = '$viajesBase/{id}/cancelar';

  static const String dispositivos = '/api/dispositivos';

  static const String usersBase = '/api/users';
  static const String usersMe = '$usersBase/me';
  static const String usersMePhotoPresign = '$usersBase/me/photo/presign';
  static const String usersMePhotoConfirm = '$usersBase/me/photo/confirm';

  static const String tripsBase = viajesBase;
  static const String trips = viajes;
}

class RegisterParams {
  const RegisterParams({
    required this.registrationToken,
    required this.nombre,
    required this.apellidoPaterno,
    required this.contrasena,
    this.apellidoMaterno,
    this.telefono,
    this.idSexo,
    this.fechaNacimiento,
    this.idMunicipio,
    this.dispositivo,
  });

  final String registrationToken;
  final String nombre;
  final String apellidoPaterno;
  final String contrasena;
  final String? apellidoMaterno;
  final String? telefono;
  final int? idSexo;
  final String? fechaNacimiento;
  final int? idMunicipio;
  final String? dispositivo;
}

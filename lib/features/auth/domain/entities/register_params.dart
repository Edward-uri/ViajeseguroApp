class RegisterParams {
  const RegisterParams({
    required this.nombreUsuario,
    required this.password,
    required this.rol,
    required this.nombre,
    required this.apellidoPaterno,
    required this.correoElectronico,
    this.apellidoMaterno,
    this.idSexo,
    this.telefono,
    this.fechaNacimiento,
  });

  final String nombreUsuario;
  final String password;
  final String rol;
  final String nombre;
  final String apellidoPaterno;
  final String correoElectronico;
  final String? apellidoMaterno;
  final int? idSexo;
  final String? telefono;
  final String? fechaNacimiento;
}

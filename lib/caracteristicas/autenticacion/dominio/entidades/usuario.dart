class Usuario {
  final String id;
  final String seudonimo;
  final String? nombres;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? tipoDocumento;
  final String email;
  final String rol;
  final String? urlFotoPerfil;
  final String? dni;

  // Gestión de Guías
  final String? solicitudEstado;
  final String? solicitudExperiencia;
  final String? solicitudCertificadoUrl;

  final String token;

  // NUEVO: Aquí guardamos los IDs de las rutas donde está inscrito
  final List<String> rutasInscritas;

  Usuario({
    required this.id,
    required this.seudonimo,
    this.nombres,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.tipoDocumento,
    required this.email,
    required this.rol,
    this.urlFotoPerfil,
    this.dni,
    this.solicitudEstado,
    this.solicitudExperiencia,
    this.solicitudCertificadoUrl,
    required this.token,
    this.rutasInscritas = const [], // Por defecto inicia vacía
  });

  Usuario copyWith({
    String? id,
    String? seudonimo,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? tipoDocumento,
    String? email,
    String? rol,
    String? urlFotoPerfil,
    String? dni,
    String? solicitudEstado,
    String? solicitudExperiencia,
    String? solicitudCertificadoUrl,
    String? token,
    List<String>? rutasInscritas, // Para poder actualizar la lista
  }) {
    return Usuario(
      id: id ?? this.id,
      seudonimo: seudonimo ?? this.seudonimo,
      nombres: nombres ?? this.nombres,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      urlFotoPerfil: urlFotoPerfil ?? this.urlFotoPerfil,
      dni: dni ?? this.dni,
      solicitudEstado: solicitudEstado ?? this.solicitudEstado,
      solicitudExperiencia: solicitudExperiencia ?? this.solicitudExperiencia,
      solicitudCertificadoUrl: solicitudCertificadoUrl ?? this.solicitudCertificadoUrl,
      token: token ?? this.token,
      rutasInscritas: rutasInscritas ?? this.rutasInscritas,
    );
  }
}
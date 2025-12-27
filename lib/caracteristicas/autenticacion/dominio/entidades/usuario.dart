class Usuario {
  final String id;
  final String seudonimo; // Cambiado de 'nombre'
  final String? nombres; // NUEVO - se llenará con API RENIEC
  final String? apellidoPaterno; // NUEVO - se llenará con API RENIEC
  final String? apellidoMaterno; // NUEVO - se llenará con API RENIEC
  final String? tipoDocumento; // NUEVO - 'DNI' o 'CE'
  final String email;
  final String rol; // 'turista', 'guia_local', 'admin'
  final String? urlFotoPerfil;
  final String? dni; // Nuevo

  // Gestión de Guías
  final String? solicitudEstado; // 'pendiente', 'aprobado', 'rechazado'
  final String? solicitudExperiencia;
  final String? solicitudCertificadoUrl;

  final String token; // Token de sesión de Supabase

  Usuario({
    required this.id,
    required this.seudonimo, // Cambiado de 'nombre'
    this.nombres, // NUEVO
    this.apellidoPaterno, // NUEVO
    this.apellidoMaterno, // NUEVO
    this.tipoDocumento, // NUEVO
    required this.email,
    required this.rol,
    this.urlFotoPerfil,
    this.dni,
    this.solicitudEstado,
    this.solicitudExperiencia,
    this.solicitudCertificadoUrl,
    required this.token,
  });

  Usuario copyWith({
    String? id,
    String? seudonimo, // Cambiado de 'nombre'
    String? nombres, // NUEVO
    String? apellidoPaterno, // NUEVO
    String? apellidoMaterno, // NUEVO
    String? tipoDocumento, // NUEVO
    String? email,
    String? rol,
    String? urlFotoPerfil,
    String? dni,
    String? solicitudEstado,
    String? solicitudExperiencia,
    String? solicitudCertificadoUrl,
    String? token,
  }) {
    return Usuario(
      id: id ?? this.id,
      seudonimo: seudonimo ?? this.seudonimo, // Cambiado de 'nombre'
      nombres: nombres ?? this.nombres, // NUEVO
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno, // NUEVO
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno, // NUEVO
      tipoDocumento: tipoDocumento ?? this.tipoDocumento, // NUEVO
      email: email ?? this.email,
      rol: rol ?? this.rol,
      urlFotoPerfil: urlFotoPerfil ?? this.urlFotoPerfil,
      dni: dni ?? this.dni,
      solicitudEstado: solicitudEstado ?? this.solicitudEstado,
      solicitudExperiencia: solicitudExperiencia ?? this.solicitudExperiencia,
      solicitudCertificadoUrl:
          solicitudCertificadoUrl ?? this.solicitudCertificadoUrl,
      token: token ?? this.token,
    );
  }
}

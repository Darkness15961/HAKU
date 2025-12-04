class Usuario {
  final String id;
  final String nombre;
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
    required this.nombre,
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
    String? nombre,
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
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      urlFotoPerfil: urlFotoPerfil ?? this.urlFotoPerfil,
      dni: dni ?? this.dni,
      solicitudEstado: solicitudEstado ?? this.solicitudEstado,
      solicitudExperiencia: solicitudExperiencia ?? this.solicitudExperiencia,
      solicitudCertificadoUrl: solicitudCertificadoUrl ?? this.solicitudCertificadoUrl,
      token: token ?? this.token,
    );
  }
}
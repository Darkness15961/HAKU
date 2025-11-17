// --- lib/caracteristicas/autenticacion/dominio/entidades/usuario.dart ---
// (Versión con el campo de certificado AÑADIDO)

class Usuario {
  // --- Atributos (Ingredientes) ---
  final String id;
  final String nombre;
  final String email;
  final String rol; // (Ej: 'turista', 'guia_aprobado', 'admin')
  final String? urlFotoPerfil;
  final String? dni;

  // --- ¡CAMPOS PARA EL PANEL DE ADMIN! ---
  final String? solicitudEstado; // (Ej: 'pendiente', 'aprobado', 'rechazado')
  final String? solicitudExperiencia; // (Datos que envió el guía)

  // --- ¡NUEVO CAMPO AÑADIDO! ---
  final String? solicitudCertificadoUrl; // (La URL del certificado)
  // --- FIN DE NUEVO CAMPO ---

  final String token; // El "Pase" de seguridad

  // --- Constructor (El "Molde" Acoplado) ---
  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.urlFotoPerfil,
    this.dni,
    this.solicitudEstado,
    this.solicitudExperiencia,
    this.solicitudCertificadoUrl, // <-- ¡AÑADIDO!
    required this.token,
  });
}
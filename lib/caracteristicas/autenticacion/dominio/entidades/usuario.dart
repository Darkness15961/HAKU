// --- PIEDRA 1 (AUTENTICACIÓN): LA "RECETA" DE USUARIO (ACOMPLADA CON ADMIN) ---
//
// 1. (ACOMPLADO): Se añadieron campos de solicitud (estado, experiencia)
//    para que el Admin pueda leerlos.
// 2. (ACOMPLADO): 'urlFotoPerfil' y 'dni' ahora son nullables ('String?')
//    para ser compatibles con el registro y el mock.

class Usuario {
  // --- Atributos (Ingredientes) ---
  final String id;
  final String nombre;
  final String email;
  final String rol; // (Ej: 'turista', 'guia_aprobado', 'admin')
  final String? urlFotoPerfil; // <-- ACOMPLADO (puede ser nulo)
  final String? dni; // <-- ACOMPLADO (puede ser nulo)

  // --- ¡NUEVOS CAMPOS PARA EL PANEL DE ADMIN! ---
  final String? solicitudEstado; // (Ej: 'pendiente', 'aprobado', 'rechazado')
  final String? solicitudExperiencia; // (Datos que envió el guía)
  // --- FIN DE NUEVOS CAMPOS ---

  final String token; // El "Pase" de seguridad

  // --- Constructor (El "Molde" Acoplado) ---
  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.urlFotoPerfil, // <-- ACOMPLADO
    this.dni, // <-- ACOMPLADO
    this.solicitudEstado, // <-- ACOMPLADO
    this.solicitudExperiencia, // <-- ACOMPLADO
    required this.token,
  });
}
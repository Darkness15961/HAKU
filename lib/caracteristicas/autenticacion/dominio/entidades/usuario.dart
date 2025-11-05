// --- PIEDRA 1 (AUTENTICACIÓN): LA "RECETA" DE USUARIO ---
//
// Este es el "Molde" que le dice a tu app
// qué forma tienen los datos de un "Usuario"
// cuando los recibimos de la "Cocina" (API o Mock).
//
// Está basado 100% en tu MER FINAL.

class Usuario {
  // --- Atributos (Ingredientes) ---
  //
  // (Estos campos vienen de la tabla "Usuarios" en tu MER FINAL)
  final String id; // (Ej: '1', '2', etc.)
  final String nombre; // (Ej: 'Alex Gálvez')
  final String email;
  final String rol; // (Ej: 'turista', 'guia_aprobado', 'admin')
  final String urlFotoPerfil; // (La URL de la imagen que añadimos)
  final String dni;

  // --- Atributo del Backend ---
  // (Este no lo mostramos, pero lo necesitamos
  // para hablar con el "Guardia de Seguridad" (Backend))
  final String token; // El "Pase" de seguridad

  // --- Constructor (El "Molde") ---
  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.urlFotoPerfil,
    required this.dni,
    required this.token,
  });
}

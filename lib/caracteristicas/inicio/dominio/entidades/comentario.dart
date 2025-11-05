// --- PIEDRA 6.2: LA "RECETA" DE COMENTARIO ---
//
// Este es el "Molde" que le dice a tu app
// qué forma tienen los datos de un "Comentario"
// cuando los recibimos de la "Cocina" (API o Mock).

class Comentario {
  // --- Atributos (Ingredientes) ---

  final String id;
  final String texto;
  final double rating; // El rating (1 a 5 estrellas) que dio este usuario
  final String fecha; // La fecha (ya formateada como texto, ej: "hace 2 días")

  // --- Datos del Usuario que comentó ---
  // (Como hablamos, el Backend hará el "trabajo sucio"
  // de buscar en la tabla "Usuarios" y nos dará
  // estos datos ya listos).
  final String usuarioNombre;
  final String usuarioFotoUrl;

  // --- Constructor (El "Molde") ---
  //
  // Le dice a Dart: "No puedes 'cocinar' (crear) un Comentario
  // si no me das TODOS estos ingredientes".
  Comentario({
    required this.id,
    required this.texto,
    required this.rating,
    required this.fecha,
    required this.usuarioNombre,
    required this.usuarioFotoUrl,
  });
}

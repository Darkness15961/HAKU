// --- PIEDRA 6.2: LA "RECETA" DE COMENTARIO (ACOMPLADA) ---
//
// 1. (ACOMPLADO): Se añadió 'lugarId' (para saber a qué lugar pertenece).
// 2. (ACOMPLADO): Se añadió 'usuarioId' (para saber quién lo escribió).

class Comentario {
  // --- Atributos (Ingredientes) ---
  final String id;
  final String texto;
  final double rating;
  final String fecha;

  // --- ¡CAMPOS ACOMPLADOS! ---
  // (Necesarios para la lógica de la app y Firebase)
  final String lugarId;
  final String usuarioId;
  // --- FIN DE ACOMPLE ---

  // --- Datos del Usuario que comentó ---
  final String usuarioNombre;
  final String usuarioFotoUrl; // (Esta ya era 'String?' en el mock, así que la hacemos nullable)

  // --- Constructor (El "Molde") ---
  Comentario({
    required this.id,
    required this.texto,
    required this.rating,
    required this.fecha,

    // --- ¡ACOMPLADO! ---
    required this.lugarId,
    required this.usuarioId,
    // --- FIN ---

    required this.usuarioNombre,
    required this.usuarioFotoUrl,
  });
}
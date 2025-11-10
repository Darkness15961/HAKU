// --- CARACTERISTICAS/RUTAS/DOMINIO/ENTIDADES/RUTA.DART (Receta Final) ---
//
// 1. (SIMPLIFICADO): Se eliminó 'duracionHoras'.
// 2. 'dias' es la única fuente de verdad para la duración.

class Ruta {
  // --- Atributos de la "Receta" ---
  final String id;
  final String nombre;
  final String descripcion;
  final String urlImagenPrincipal;
  final double precio;
  final String dificultad;
  final int cuposTotales; // <-- Campo nuevo
  final int cuposDisponibles; // <-- Campo nuevo
  final bool visible;
  final int dias; // <-- Campo principal

  // Campos "Calculados"
  final String guiaId;
  final String guiaNombre;
  final String guiaFotoUrl;
  final double rating;
  final int reviewsCount;
  final int inscritosCount;
  final List<String> lugaresIncluidos; // Nombres (para UI)
  final List<String> lugaresIncluidosIds; // IDs (para BD)

  // Campos de Estado
  final bool esFavorita;
  final bool estaInscrito;

  // --- Constructor (Simplificado) ---
  Ruta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagenPrincipal,
    required this.precio,
    required this.dificultad,
    required this.cuposTotales,
    required this.cuposDisponibles,
    required this.visible,
    required this.dias,

    // Atributos Relacionados
    required this.guiaId,
    required this.guiaNombre,
    required this.guiaFotoUrl,
    required this.rating,
    required this.reviewsCount,
    required this.lugaresIncluidos,
    required this.lugaresIncluidosIds,
    required this.inscritosCount,

    // Campos de estado
    required this.esFavorita,
    required this.estaInscrito,
  });
}
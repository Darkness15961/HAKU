// --- PIEDRA 1 (RUTAS): LA "RECETA" DE RUTA ---
//
// Este es el "Molde" que le dice a tu app
// qué forma tienen los datos de una "Ruta"
// cuando los recibimos de la "Cocina" (API o Mock).
//
// Está basado 100% en tu MER FINAL.

class Ruta {
  // --- Atributos de la "Receta" ---

  // 1. Campos directos de la tabla "Rutas"
  final String id;
  final String nombre;
  final String descripcion;
  final String urlImagenPrincipal;
  final double precio; // El costo por persona
  final String dificultad; // (Ej: 'facil', 'medio', 'dificil')
  final int cupos; // Cupos totales disponibles
  final bool visible; // Si es pública o privada

  // 2. Campos "Calculados" o Relacionados

  // Datos del guía (Calculado de la tabla "Usuarios")
  final String guiaId; // Lo necesitamos para el filtro de Rutas Creadas
  final String guiaNombre;
  final String guiaFotoUrl;

  // Conteo y promedio (Calculado de "Comentarios")
  final double rating;
  final int reviewsCount; // Conteo de reseñas

  // Relación Muchos-a-Muchos (Calculado de "Lugar_Ruta")
  final List<String> lugaresIncluidos; // Lista simple con los nombres

  // Relación Muchos-a-Muchos (Calculado de "Inscripciones_Ruta")
  final int inscritosCount; // Conteo de turistas inscritos

  // --- Campos de Estado del Usuario Actual ---
  // (La "Cocina" revisará las tablas pivote y nos dirá el estado)

  // Calculado de "Favoritos_Ruta"
  final bool esFavorita;
  // Calculado de "Inscripciones_Ruta"
  final bool estaInscrito;

  // --- Constructor (El "Molde") ---
  Ruta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagenPrincipal,
    required this.precio,
    required this.dificultad,
    required this.cupos,
    required this.visible,

    // Atributos Relacionados
    required this.guiaId,
    required this.guiaNombre,
    required this.guiaFotoUrl,
    required this.rating,
    required this.reviewsCount,
    required this.lugaresIncluidos,
    required this.inscritosCount,

    // Campos de estado de la sesión actual
    required this.esFavorita,
    required this.estaInscrito,
  });
}


// --- CARACTERISTICAS/RUTAS/DOMINIO/ENTIDADES/RUTA.DART (Receta Final) ---
//
// 1. (SIMPLIFICADO): Se eliminó 'duracionHoras'.
// 2. 'dias' es la única fuente de verdad para la duración.

class Ruta {
  final String id;
  final String nombre;
  final String descripcion;
  final String urlImagenPrincipal;
  final double precio;
  final String categoria;
  final int cuposTotales;
  final int cuposDisponibles;
  final bool visible;
  final int dias;

  // --- NUEVOS CAMPOS FASE 2/3 ---
  final String estado; // 'convocatoria', 'en_curso', 'finalizada'
  final List<String> equipamiento; // Lista de cosas para llevar
  final DateTime? fechaCierre; // Para saber si aun se puede inscribir

  // --- NUEVOS CAMPOS FASE 4: INFORMACIÓN DEL EVENTO ---
  final DateTime? fechaEvento; // Fecha y hora del evento
  final String? puntoEncuentro; // Ubicación del punto de encuentro

  // Campos Calculados
  final String guiaId;
  final String guiaNombre;
  final String guiaFotoUrl;
  final double guiaRating; // Nuevo campo
  final double rating;
  final int reviewsCount;
  final int inscritosCount;
  final List<String> lugaresIncluidos;
  final List<String> lugaresIncluidosIds;
  final String? enlaceWhatsapp; // Nuevo

  final bool esFavorita;
  final bool estaInscrito;

  // --- NUEVO CAMPO DE ESTADO DEL USUARIO ---
  final bool asistio; // ¿El usuario logueado marcó asistencia?

  Ruta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagenPrincipal,
    required this.precio,
    required this.categoria,
    required this.cuposTotales,
    required this.cuposDisponibles,
    required this.visible,
    required this.dias,

    // Valores por defecto para evitar errores con datos viejos
    this.estado = 'convocatoria',
    this.equipamiento = const [],
    this.fechaCierre,
    this.asistio = false,
    this.fechaEvento,
    this.puntoEncuentro,

    required this.guiaId,
    required this.guiaNombre,
    required this.guiaFotoUrl,
    required this.guiaRating, // Nuevo campo
    required this.rating,
    required this.reviewsCount,
    required this.lugaresIncluidos,
    required this.lugaresIncluidosIds,
    this.enlaceWhatsapp,
    required this.inscritosCount,
    required this.esFavorita,
    required this.estaInscrito,
  });
}

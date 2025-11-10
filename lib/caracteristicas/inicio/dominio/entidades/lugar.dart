// --- PIEDRA 1.1: LA "RECETA" DE LUGAR (¡VERSIÓN FINAL CON ID DE PROVINCIA!) ---

class Lugar {
  // --- Atributos del Carrusel ---
  final String id;
  final String nombre;
  final String descripcion;
  final String urlImagen;
  final double rating;
  final String categoria;

  // --- Atributos de Detalle ---
  final int reviewsCount;
  final String horario;
  final String costoEntrada;
  final List<String> puntosInteres;

  // --- Atributos de Coordenadas ---
  final double latitud;
  final double longitud;

  // --- ¡ATRIBUTO FALTANTE CRÍTICO! ---
  final String provinciaId;
  // --- FIN ATRIBUTO FALTANTE ---

  // --- Constructor (El "Molde") ---
  Lugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagen,
    required this.rating,
    required this.categoria,

    // (Valores por defecto para que no den error)
    this.reviewsCount = 0,
    this.horario = 'No disponible',
    this.costoEntrada = 'Consultar',
    this.puntosInteres = const [],

    // Valores de Coordenadas (Usamos Cusco como fallback)
    this.latitud = -13.5319,
    this.longitud = -71.9675,

    // --- ¡PARÁMETRO FALTANTE CRÍTICO EN EL CONSTRUCTOR! ---
    required this.provinciaId,
    // --- FIN PARÁMETRO FALTANTE ---
  });
}
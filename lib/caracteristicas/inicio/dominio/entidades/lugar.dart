class Lugar {
  // --- Atributos Principales ---
  final String id;
  final String nombre;
  final String descripcion;
  final String urlImagen;
  final double rating;

  // --- Atributos de Detalle ---
  final int reviewsCount;
  final String horario;
  final List<String> puntosInteres;

  // --- Atributos de Coordenadas ---
  final double latitud;
  final double longitud;

  // --- Relaciones ---
  final String provinciaId;
  final String usuarioId;

  // --- Nuevo Campo ---
  final String? videoTiktokUrl;
  final String? fotoRecuerdoUrl;

  // --- Constructor ---
  Lugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagen,
    required this.rating,
    this.fotoRecuerdoUrl,
    this.reviewsCount = 0,
    this.horario = 'No disponible',
    this.puntosInteres = const [],

    this.latitud = -13.5319,
    this.longitud = -71.9675,

    required this.provinciaId,
    required this.usuarioId,

    this.videoTiktokUrl,
  });
}

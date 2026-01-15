class Hakuparada {
  // Identificadores
  final int id;            // Base de datos: bigint

  // Información Visual
  final String nombre;
  final String descripcion;
  final String fotoReferencia;
  final String categoria;  // Base de datos: text

  // Coordenadas
  final double latitud;
  final double longitud;

  // Relaciones (Sostenibilidad)
  final int provinciaId;   // Base de datos: bigint NOT NULL
  final int? lugarId;      // Base de datos: bigint (Puede ser nulo)

  // Lógica de Control (NUEVO: Agregado según tu Schema)
  final bool visible;      // Para saber si está activa
  final bool verificado;   // Para saber si ya la aprobaste

  Hakuparada({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fotoReferencia,
    required this.categoria,
    required this.latitud,
    required this.longitud,
    required this.provinciaId,
    this.lugarId,
    required this.visible,
    required this.verificado,
  });
}
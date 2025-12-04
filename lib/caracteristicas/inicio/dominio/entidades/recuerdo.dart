class Recuerdo {
  final String id;
  final String fotoUrl;
  final String? comentario;
  final double latitud;
  final double longitud;
  final DateTime fecha;
  final String nombreRuta; // Para mostrar "Recuerdo de: Valle Sagrado"

  Recuerdo({
    required this.id,
    required this.fotoUrl,
    this.comentario,
    required this.latitud,
    required this.longitud,
    required this.fecha,
    required this.nombreRuta,
  });
}

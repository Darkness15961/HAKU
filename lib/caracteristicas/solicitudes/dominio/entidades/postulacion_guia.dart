// ============================================
// Entidad: PostulacionGuia
// ============================================

class PostulacionGuia {
  final String id;
  final String solicitudId;
  final String guiaId;

  // Propuesta económica
  final double precioOfertado;
  final String moneda; // 'PEN' o 'USD'

  // Detalles de la propuesta
  final String descripcionPropuesta;
  final String? itinerarioDetallado;
  final List<String> serviciosIncluidos;

  // Estado: 'pendiente', 'aceptada', 'rechazada'
  final String estado;

  // Metadata
  final DateTime fechaPostulacion;
  final DateTime? fechaRespuesta;

  // Datos adicionales del guía (populados desde join)
  final String? guiaNombre;
  final String? guiaFotoUrl;
  final double? guiaRating;

  PostulacionGuia({
    required this.id,
    required this.solicitudId,
    required this.guiaId,
    required this.precioOfertado,
    this.moneda = 'PEN',
    required this.descripcionPropuesta,
    this.itinerarioDetallado,
    this.serviciosIncluidos = const [],
    required this.estado,
    required this.fechaPostulacion,
    this.fechaRespuesta,
    this.guiaNombre,
    this.guiaFotoUrl,
    this.guiaRating,
  });

  factory PostulacionGuia.fromJson(Map<String, dynamic> json) {
    return PostulacionGuia(
      id: json['id'].toString(),
      solicitudId: json['solicitud_id'].toString(),
      guiaId: json['guia_id'],
      precioOfertado: double.parse(json['precio_ofertado'].toString()),
      moneda: json['moneda'] ?? 'PEN',
      descripcionPropuesta: json['descripcion_propuesta'],
      itinerarioDetallado: json['itinerario_detallado'],
      serviciosIncluidos: json['servicios_incluidos'] != null
          ? List<String>.from(json['servicios_incluidos'])
          : [],
      estado: json['estado'],
      fechaPostulacion: DateTime.parse(json['fecha_postulacion']),
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'])
          : null,
      guiaNombre: json['guia_nombre'],
      guiaFotoUrl: json['guia_foto'],
      guiaRating: json['guia_rating'] != null
          ? double.parse(json['guia_rating'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'solicitud_id': int.parse(solicitudId),
      'guia_id': guiaId,
      'precio_ofertado': precioOfertado,
      'moneda': moneda,
      'descripcion_propuesta': descripcionPropuesta,
      'itinerario_detallado': itinerarioDetallado,
      'servicios_incluidos': serviciosIncluidos,
    };
  }

  // Getters útiles
  bool get esPendiente => estado == 'pendiente';
  bool get esAceptada => estado == 'aceptada';
  bool get esRechazada => estado == 'rechazada';

  String get precioFormateado {
    if (moneda == 'PEN') {
      return 'S/ ${precioOfertado.toStringAsFixed(2)}';
    } else {
      return '\$ ${precioOfertado.toStringAsFixed(2)}';
    }
  }

  String get estadoTexto {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      default:
        return estado;
    }
  }

  String get tiempoDesdePostulacion {
    final diferencia = DateTime.now().difference(fechaPostulacion);

    if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace un momento';
    }
  }
}

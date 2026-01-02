// ============================================
// Entidad: SolicitudRuta
// ============================================

class SolicitudRuta {
  final String id;
  final String turistaId;
  final String titulo;
  final String descripcion;
  final List<int> lugaresIds;
  final DateTime fechaDeseada;
  final int numeroPersonas;
  final double? presupuestoMaximo;

  // Estados: 'buscando_guia', 'guia_asignado', 'cancelada', 'completada'
  final String estado;

  // Relaciones
  final String? guiaAsignadoId;
  final int? postulacionAceptadaId;
  final int? rutaCreadaId;

  // Privacidad
  final String preferenciaPrivacidad; // 'publica' o 'privada'
  final String? grupoObjetivo;

  // Metadata
  final DateTime fechaCreacion;
  final DateTime? fechaCancelacion;
  final String? motivoCancelacion;

  // Referencias opcionales
  final String? enlaceVideoReferencia;
  final String? notasAdicionales;

  // Contadores
  final int numeroPostulaciones;

  SolicitudRuta({
    required this.id,
    required this.turistaId,
    required this.titulo,
    required this.descripcion,
    required this.lugaresIds,
    required this.fechaDeseada,
    required this.numeroPersonas,
    this.presupuestoMaximo,
    required this.estado,
    this.guiaAsignadoId,
    this.postulacionAceptadaId,
    this.rutaCreadaId,
    this.preferenciaPrivacidad = 'publica',
    this.grupoObjetivo,
    required this.fechaCreacion,
    this.fechaCancelacion,
    this.motivoCancelacion,
    this.enlaceVideoReferencia,
    this.notasAdicionales,
    this.numeroPostulaciones = 0,
  });

  factory SolicitudRuta.fromJson(Map<String, dynamic> json) {
    return SolicitudRuta(
      id: json['id'].toString(),
      turistaId: json['turista_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      lugaresIds: (json['lugares_ids'] as List).map((e) => e as int).toList(),
      fechaDeseada: DateTime.parse(json['fecha_deseada']),
      numeroPersonas: json['numero_personas'],
      presupuestoMaximo: json['presupuesto_maximo'] != null
          ? double.parse(json['presupuesto_maximo'].toString())
          : null,
      estado: json['estado'],
      guiaAsignadoId: json['guia_asignado_id'],
      postulacionAceptadaId: json['postulacion_aceptada_id'],
      rutaCreadaId: json['ruta_creada_id'],
      preferenciaPrivacidad: json['preferencia_privacidad'] ?? 'publica',
      grupoObjetivo: json['grupo_objetivo'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaCancelacion: json['fecha_cancelacion'] != null
          ? DateTime.parse(json['fecha_cancelacion'])
          : null,
      motivoCancelacion: json['motivo_cancelacion'],
      enlaceVideoReferencia: json['enlace_video_referencia'],
      notasAdicionales: json['notas_adicionales'],
      numeroPostulaciones: json['numero_postulaciones'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'turista_id': turistaId,
      'titulo': titulo,
      'descripcion': descripcion,
      'lugares_ids': lugaresIds,
      'fecha_deseada': fechaDeseada.toIso8601String(),
      'numero_personas': numeroPersonas,
      'presupuesto_maximo': presupuestoMaximo,
      'preferencia_privacidad': preferenciaPrivacidad,
      'grupo_objetivo': grupoObjetivo,
      'enlace_video_referencia': enlaceVideoReferencia,
      'notas_adicionales': notasAdicionales,
    };
  }

  // Getters útiles
  bool get esBuscandoGuia => estado == 'buscando_guia';
  bool get tieneGuiaAsignado => estado == 'guia_asignado';
  bool get estaCancelada => estado == 'cancelada';
  bool get estaCompletada => estado == 'completada';

  bool get puedeSerCancelada {
    if (estado != 'buscando_guia' && estado != 'guia_asignado') {
      return false;
    }
    final horasRestantes = fechaDeseada.difference(DateTime.now()).inHours;
    return horasRestantes >= 24;
  }

  bool get puedeSerModificada {
    return estado == 'buscando_guia';
  }

  bool get esPrivada => preferenciaPrivacidad == 'privada';

  String get estadoTexto {
    switch (estado) {
      case 'buscando_guia':
        return 'Buscando Guía';
      case 'guia_asignado':
        return 'Guía Asignado';
      case 'cancelada':
        return 'Cancelada';
      case 'completada':
        return 'Completada';
      default:
        return estado;
    }
  }
}

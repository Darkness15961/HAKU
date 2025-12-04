import '../../dominio/entidades/lugar.dart';

class LugarModelo {
  final int id;
  final String nombre;
  final String descripcion;
  final String urlImagen;
  final double rating;
  final double latitud;
  final double longitud;
  final int provinciaId;
  final String categoria;
  final String? videoTiktokUrl;
  final String usuarioId;
  final String horario;
  final String costoEntrada;
  final int reviewsCount;
  final String? fotoRecuerdoUrl;

  LugarModelo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagen,
    required this.rating,
    required this.latitud,
    required this.longitud,
    required this.provinciaId,
    required this.categoria,
    this.videoTiktokUrl,
    required this.usuarioId,
    required this.horario,
    required this.costoEntrada,
    required this.reviewsCount,
    this.fotoRecuerdoUrl,
  });

  factory LugarModelo.fromJson(Map<String, dynamic> json) {
    return LugarModelo(
      id: json['id'] ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      urlImagen: json['url_imagen']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      provinciaId: (json['provincia_id'] is int)
          ? json['provincia_id']
          : int.tryParse(json['provincia_id']?.toString() ?? '0') ?? 0,
      categoria: json['categoria_nombre']?.toString() ?? 'General',
      videoTiktokUrl: json['video_tiktok_url']?.toString(),
      fotoRecuerdoUrl: json['foto_recuerdo_url'],
      usuarioId: json['registrado_por']?.toString() ?? '',
      horario: json['horario']?.toString() ?? '',
      costoEntrada:
          json['costo_entrada_referencial']?.toString() ??
          json['costo_entrada']?.toString() ??
          '',
    );
  }

  Lugar toEntity() {
    return Lugar(
      id: id.toString(),
      nombre: nombre,
      descripcion: descripcion,
      urlImagen: urlImagen,
      rating: rating,
      reviewsCount: reviewsCount,
      categoria: categoria,
      horario: horario,
      costoEntrada: costoEntrada,
      latitud: latitud,
      longitud: longitud,
      provinciaId: provinciaId.toString(),
      usuarioId: usuarioId,
      videoTiktokUrl: videoTiktokUrl,
      fotoRecuerdoUrl: fotoRecuerdoUrl,
    );
  }
}

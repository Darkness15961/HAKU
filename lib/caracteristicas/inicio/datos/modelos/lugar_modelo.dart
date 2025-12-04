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
  final String? videoTiktokUrl;
  final String usuarioId;
  final String horario;
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
    this.videoTiktokUrl,
    required this.usuarioId,
    required this.horario,
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
      videoTiktokUrl: json['video_tiktok_url']?.toString(),
      fotoRecuerdoUrl: json['foto_recuerdo_url'],
      usuarioId: json['registrado_por']?.toString() ?? '',
      horario: json['horario']?.toString() ?? '',
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
      horario: horario,
      latitud: latitud,
      longitud: longitud,
      provinciaId: provinciaId.toString(),
      usuarioId: usuarioId,
      videoTiktokUrl: videoTiktokUrl,
      fotoRecuerdoUrl: fotoRecuerdoUrl,
    );
  }
}

import '../../dominio/entidades/provincia.dart';

class ProvinciaModelo extends Provincia {
  ProvinciaModelo({
    required super.id,
    required super.nombre,
    required super.urlImagen,
    required super.placesCount,
    required super.categories,
  });

  factory ProvinciaModelo.fromJson(Map<String, dynamic> json) {
    return ProvinciaModelo(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      urlImagen: json['url_imagen'] ?? '',
      placesCount: json['places_count'] ?? 
          (json['lugares'] is List && (json['lugares'] as List).isNotEmpty 
              ? (json['lugares'][0]['count'] ?? 0) 
              : 0),
      categories: (json['categorias'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  Provincia toEntity() {
    return Provincia(
      id: id,
      nombre: nombre,
      urlImagen: urlImagen,
      placesCount: placesCount,
      categories: categories,
    );
  }
}

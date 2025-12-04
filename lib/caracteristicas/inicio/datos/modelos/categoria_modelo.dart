import '../../dominio/entidades/categoria.dart';

class CategoriaModelo extends Categoria {
  CategoriaModelo({
    required super.id,
    required super.nombre,
    required super.urlImagen,
  });

  factory CategoriaModelo.fromJson(Map<String, dynamic> json) {
    return CategoriaModelo(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      urlImagen: json['url_imagen'] ?? '',
    );
  }

  Categoria toEntity() {
    return Categoria(
      id: id,
      nombre: nombre,
      urlImagen: urlImagen,
    );
  }
}

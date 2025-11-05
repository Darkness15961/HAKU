// lib/caracteristicas/inicio/datos/modelos/lugar_modelo.dart
class LugarModelo {
  final int id;
  final String nombre;
  final String descripcion;
  final String imagen;
  final double latitud;
  final double longitud;
  final String provincia;
  final String categoria;
  final double rating;

  LugarModelo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagen,
    required this.latitud,
    required this.longitud,
    required this.provincia,
    required this.categoria,
    required this.rating,
  });

  factory LugarModelo.fromJson(Map<String, dynamic> json) => LugarModelo(
    id: json['id'] as int,
    nombre: json['nombre'] ?? '',
    descripcion: json['descripcion'] ?? '',
    imagen: json['imagen'] ?? '',
    latitud: (json['latitud'] ?? 0).toDouble(),
    longitud: (json['longitud'] ?? 0).toDouble(),
    provincia: json['provincia'] ?? '',
    categoria: json['categoria'] ?? '',
    rating: (json['rating'] ?? 0).toDouble(),
  );
}

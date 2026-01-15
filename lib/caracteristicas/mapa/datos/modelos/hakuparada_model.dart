import '../../dominio/entidades/hakuparada.dart';

class HakuparadaModel extends Hakuparada {

  // 1. El Constructor: Recibe todo y se lo pasa al Padre (Entidad)
  HakuparadaModel({
    required int id,
    required String nombre,
    required String descripcion,
    required String fotoReferencia,
    required String categoria,
    required double latitud,
    required double longitud,
    required int provinciaId,
    int? lugarId,
    required bool visible,      // 👈 Nuevo campo
    required bool verificado,   // 👈 Nuevo campo
  }) : super(
    id: id,
    nombre: nombre,
    descripcion: descripcion,
    fotoReferencia: fotoReferencia,
    categoria: categoria,
    latitud: latitud,
    longitud: longitud,
    provinciaId: provinciaId,
    lugarId: lugarId,
    visible: visible,     // 👈 Pasamos al padre
    verificado: verificado, // 👈 Pasamos al padre
  );

  // 2. La Fábrica (Factory): El Traductor de JSON -> Objeto
  factory HakuparadaModel.fromJson(Map<String, dynamic> json) {
    return HakuparadaModel(
      // ID y Textos (Manejando nulos por seguridad)
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'] ?? '',
      fotoReferencia: json['foto_referencia'] ?? '',
      categoria: json['categoria'] ?? 'General',

      // Números (Supabase a veces manda int o double, esto lo arregla)
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,

      // Relaciones
      provinciaId: json['provincia_id'] ?? 0,
      lugarId: json['lugar_id'], // Puede ser null, así que lo dejamos pasar

      // 🛡️ Lógica de Control (NUEVO)
      // Usamos '??' para evitar errores si el campo no viene
      visible: json['visible'] ?? true,       // Si es nulo, asumimos visible
      verificado: json['verificado'] ?? false, // Si es nulo, asumimos NO verificado
    );
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';
import '../../dominio/entidades/comentario.dart';
import '../../dominio/entidades/recuerdo.dart';
import '../../dominio/repositorios/lugares_repositorio.dart';
import '../modelos/lugar_modelo.dart';

class LugaresRepositorioSupabase implements LugaresRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- LUGARES ---

  @override
  Future<List<Lugar>> obtenerTodosLosLugares() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Consulta con favoritos
      var query = _supabase.from('lugares').select('*, favoritos!left(id)');

      // Si hay usuario, filtramos favoritos para saber cuales son MIOS
      if (userId != null) {
        // Nota: Esto es un truco de Supabase para traer si existe relación
        // Pero para simplificar en Flutter sin complicar la query:
        // Traemos todos los lugares y aparte los IDs de mis favoritos
      }

      final data = await _supabase.from('lugares').select();
      final lugares = (data as List)
          .map((json) => LugarModelo.fromJson(json).toEntity())
          .toList();

      return lugares;
    } catch (e) {
      print('Error al obtener lugares: $e');
      return [];
    }
  }

  @override // <-- Ahora sí es oficial
  Future<List<String>> obtenerIdsFavoritos(String usuarioId) async {
    try {
      // Nota: Aunque pasemos usuarioId por parámetro,
      // por seguridad usamos el currentUser de Supabase o confiamos en el parámetro
      final data = await _supabase
          .from('favoritos')
          .select('lugar_id')
          .eq('usuario_id', usuarioId);

      return (data as List).map((e) => e['lugar_id'].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> marcarFavorito(String lugarId) async {
    try {
      final int id = int.parse(lugarId);
      await _supabase.rpc('toggle_favorito', params: {'lugar_id_param': id});
    } catch (e) {
      print('Error toggle favorito: $e');
      throw Exception('No se pudo actualizar favorito');
    }
  }

  @override
  Future<Lugar> crearLugar(Map<String, dynamic> datosLugar) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      // 1. Preparamos el mapa para Supabase (snake_case)
      // Mapeamos lo que viene de la UI (camelCase) a la BD (snake_case)
      final datosParaEnviar = {
        'nombre': datosLugar['nombre'],
        'descripcion': datosLugar['descripcion'],
        'url_imagen': datosLugar['url_imagen'] ?? datosLugar['urlImagen'],
        'provincia_id': datosLugar['provincia_id'] ?? datosLugar['provinciaId'],
        'horario': datosLugar['horario'],
        'latitud': datosLugar['latitud'],
        'longitud': datosLugar['longitud'],
        'video_tiktok_url':
            datosLugar['video_tiktok_url'] ?? datosLugar['videoTiktokUrl'],
        'registrado_por': userId, // Auditoría
        // 'puntos_interes' se omite si no creaste la columna en BD
      };

      // Limpieza de nulos
      datosParaEnviar.removeWhere((key, value) => value == null);

      final data = await _supabase
          .from('lugares')
          .insert(datosParaEnviar)
          .select()
          .single();

      return LugarModelo.fromJson(data).toEntity();
    } catch (e) {
      print('Error CRÍTICO al crear lugar: $e');
      rethrow;
    }
  }

  @override
  Future<Lugar> actualizarLugar(
    String lugarId,
    Map<String, dynamic> datosLugar,
  ) async {
    try {
      final datosParaEnviar = <String, dynamic>{
        'nombre': datosLugar['nombre'],
        'descripcion': datosLugar['descripcion'],
        'url_imagen': datosLugar['url_imagen'] ?? datosLugar['urlImagen'],
        'provincia_id': datosLugar['provincia_id'] ?? datosLugar['provinciaId'],
        'horario': datosLugar['horario'],
        'latitud': datosLugar['latitud'],
        'longitud': datosLugar['longitud'],
        'video_tiktok_url':
            datosLugar['video_tiktok_url'] ?? datosLugar['videoTiktokUrl'],
      };

      // Limpieza
      datosParaEnviar.removeWhere((key, value) => value == null);

      final data = await _supabase
          .from('lugares')
          .update(datosParaEnviar)
          .eq('id', lugarId)
          .select()
          .single();

      return LugarModelo.fromJson(data).toEntity();
    } catch (e) {
      print('Error al actualizar lugar: $e');
      rethrow;
    }
  }

  @override
  Future<void> eliminarLugar(String lugarId) async {
    await _supabase.from('lugares').delete().eq('id', lugarId);
  }

  @override
  Future<List<Lugar>> obtenerLugaresPorUsuario(String usuarioId) async {
    try {
      final data = await _supabase
          .from('lugares')
          .select()
          .eq('registrado_por', usuarioId);
      return (data as List)
          .map((json) => LugarModelo.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Lugar>> obtenerLugaresPopulares() async {
    try {
      final data = await _supabase
          .from('lugares')
          .select()
          // 1. Ordenar por Rating (Mejor puntuados arriba)
          .order('rating', ascending: false)
          // 2. Ordenar por Popularidad (Más reseñados arriba)
          .order('reviews_count', ascending: false)
          .limit(5); // Top 5

      return (data as List)
          .map((e) => LugarModelo.fromJson(e).toEntity())
          .toList();
    } catch (e) {
      print('Error populares: $e');
      return [];
    }
  }

  @override
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId, {int page = 0, int pageSize = 10}) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final data = await _supabase
          .from('lugares')
          .select()
          .eq('provincia_id', provinciaId)
          .range(from, to); // Paginación real
          
      return (data as List)
          .map((e) => LugarModelo.fromJson(e).toEntity())
          .toList();
    } catch (e) {
      return [];
    }
  }

  // --- PROVINCIAS ---

  @override
  Future<List<Provincia>> obtenerProvincias() async {
    try {
      // 1. CONSULTA INTELIGENTE:
      // '*, lugares(count)' le dice a Supabase: "Dame todas las columnas de provincias
      // Y ADEMÁS cuenta cuántas filas en la tabla 'lugares' coinciden con esta provincia".
      final data = await _supabase
          .from('provincias')
          .select('*, lugares(count)');

      // 2. MAPEO DEL CONTEO:
      return (data as List).map((json) {
        // Supabase devuelve el conteo en una estructura así: "lugares": [{"count": 3}]
        int conteoReal = 0;
        if (json['lugares'] != null && (json['lugares'] as List).isNotEmpty) {
          conteoReal = json['lugares'][0]['count'] as int;
        }

        return Provincia(
          id: json['id'].toString(),
          nombre: json['nombre'] ?? 'Sin nombre',
          urlImagen: json['url_imagen'] ?? '',
          // Si quieres categorías dinámicas, necesitarías otra consulta o lógica,
          // por ahora lo dejamos vacío o estático para no complicar.
          categories: [],
          placesCount: conteoReal, // <--- ¡AQUÍ SE ASIGNA EL VALOR REAL!
        );
      }).toList();
    } catch (e) {
      print('Error al obtener provincias: $e');
      return [];
    }
  }

  @override
  Future<void> crearProvincia(Map<String, dynamic> datosProvincia) async {
    await _supabase.from('provincias').insert({
      'nombre': datosProvincia['nombre'],
      'url_imagen': datosProvincia['urlImagen'],
      'descripcion': datosProvincia['descripcion'] ?? '',
    });
  }

  @override
  Future<void> actualizarProvincia(
    String provinciaId,
    Map<String, dynamic> datosProvincia,
  ) async {
    await _supabase
        .from('provincias')
        .update({
          'nombre': datosProvincia['nombre'],
          'url_imagen': datosProvincia['urlImagen'],
          'descripcion': datosProvincia['descripcion'] ?? '',
        })
        .eq('id', provinciaId);
  }

  @override
  Future<void> eliminarProvincia(String provinciaId) async {
    // Verificar dependencias antes de borrar
    final count = await _supabase
        .from('lugares')
        .count(CountOption.exact)
        .eq('provincia_id', provinciaId);

    if (count > 0) {
      throw Exception(
        'No se puede eliminar: Hay $count lugares en esta provincia.',
      );
    }
    await _supabase.from('provincias').delete().eq('id', provinciaId);
  }

  // --- CATEGORÍAS ---

  @override
  Future<List<Categoria>> obtenerCategorias() async {
    try {
      final data = await _supabase.from('categorias').select();
      // Mapeo manual
      final lista = (data as List).map((json) {
        return Categoria(
          id: json['id'].toString(),
          nombre: json['nombre'] ?? '',
          urlImagen: json['url_imagen'] ?? '',
        );
      }).toList();

      return [Categoria(id: '1', nombre: 'Todas', urlImagen: ''), ...lista];
    } catch (e) {
      return [];
    }
  }

  // --- COMENTARIOS (Tabla 'resenas') ---

  @override
  Future<List<Comentario>> obtenerComentarios(String lugarId) async {
    try {
      // Hacemos JOIN con la tabla perfiles para sacar foto y nombre
      final data = await _supabase
          .from('resenas')
          .select('*, perfiles(nombre, url_foto_perfil)')
          .eq('lugar_id', lugarId)
          .order('created_at', ascending: false);

      return (data as List).map((json) {
        final perfil = json['perfiles'] ?? {};

        // Formateo simple de fecha
        final fechaRaw =
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
        final fechaStr = "${fechaRaw.day}/${fechaRaw.month}/${fechaRaw.year}";

        return Comentario(
          id: json['id'].toString(),
          texto: json['comentario'] ?? '',
          rating: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
          fecha: fechaStr,
          lugarId: json['lugar_id'].toString(),
          usuarioId: json['usuario_id']?.toString() ?? '',
          usuarioNombre: perfil['nombre'] ?? 'Usuario',
          usuarioFotoUrl: perfil['url_foto_perfil'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error comentarios: $e');
      return [];
    }
  }

  @override
  Future<void> enviarComentario(
    String lugarId,
    String texto,
    double rating,
    String usuarioNombre,
    String? urlFotoUsuario,
    String usuarioId,
  ) async {
    // Insertamos en la tabla correcta: 'resenas'
    await _supabase.from('resenas').insert({
      'lugar_id': int.tryParse(lugarId),
      'usuario_id': usuarioId,
      'comentario': texto,
      'calificacion': rating.toInt(),
    });
  }

  // --- RECUERDOS (FASE 4) ---

  @override
  Future<void> crearRecuerdo({
    required String rutaId,
    required String fotoUrl,
    required double latitud,
    required double longitud,
    String? comentario,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase.from('recuerdos').insert({
      'usuario_id': userId,
      'ruta_id': int.parse(rutaId),
      'foto_url': fotoUrl,
      'latitud': latitud,
      'longitud': longitud,
      'comentario': comentario,
    });
  }

  @override
  Future<List<Recuerdo>> obtenerMisRecuerdos() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Traemos el recuerdo y el título de la ruta asociada
      final data = await _supabase
          .from('recuerdos')
          .select('*, rutas(titulo)')
          .eq('usuario_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((json) {
        return Recuerdo(
          id: json['id'].toString(),
          fotoUrl: json['foto_url'],
          comentario: json['comentario'],
          latitud: (json['latitud'] as num).toDouble(),
          longitud: (json['longitud'] as num).toDouble(),
          fecha: DateTime.parse(json['created_at']),
          nombreRuta: json['rutas']?['titulo'] ?? 'Aventura Haku',
        );
      }).toList();
    } catch (e) {
      print('Error obteniendo recuerdos: $e');
      return [];
    }
  }
}

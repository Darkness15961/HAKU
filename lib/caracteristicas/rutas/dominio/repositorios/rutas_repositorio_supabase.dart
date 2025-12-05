import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dominio/entidades/ruta.dart';
import '../../dominio/repositorios/rutas_repositorio.dart';

class RutasRepositorioSupabase implements RutasRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<Ruta>> obtenerRutas(String tipoFiltro) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // 1. CONSULTA AVANZADA: Traemos la Ruta + Datos del Guía + Detalles de Lugares
      // Usamos la sintaxis de Supabase para relaciones (!)
      var query = _supabase.from('rutas').select('''
        *,
        perfiles!guia_id (nombre, url_foto_perfil, rating),
        ruta_detalles (
          orden_visita,
          lugares (id, nombre)
        )
      ''');

      // 2. APLICAR FILTROS
      if (tipoFiltro == 'creadas_por_mi') {
        if (userId == null) return [];
        query = query.eq('guia_id', userId);
      } else {
        // Recomendadas y Guardadas (por ahora mostramos las visibles públicas)
        query = query.eq('visible', true);
      }

      final List<dynamic> data = await query;

      // 3. MAPEO DE DATOS (JSON -> OBJETO RUTA)
      // Usamos Future.wait por si necesitamos hacer llamadas asíncronas extra
      return await Future.wait(
        data.map((json) async {
          return _mapJsonToRuta(json, userId);
        }),
      );
    } catch (e) {
      print('Error al obtener rutas: $e');
      return [];
    }
  }

  // --- MAPEO MANUAL (Traductor BD -> App) ---
  Future<Ruta> _mapJsonToRuta(
    Map<String, dynamic> json,
    String? currentUserId,
  ) async {
    // A. Datos del Guía (Vienen anidados gracias al select)
    final perfilGuia = json['perfiles'];
    final String nombreGuia = perfilGuia != null
        ? perfilGuia['nombre'] ?? 'Guía Haku'
        : 'Desconocido';
    final String fotoGuia = perfilGuia != null
        ? perfilGuia['url_foto_perfil'] ?? ''
        : '';

    // B. Lugares Incluidos (Vienen anidados en ruta_detalles)
    List<String> nombresLugares = [];
    List<String> idsLugares = [];

    if (json['ruta_detalles'] != null) {
      final detalles = List<dynamic>.from(json['ruta_detalles']);
      // Ordenamos por orden de visita
      detalles.sort(
        (a, b) =>
            (a['orden_visita'] as int).compareTo(b['orden_visita'] as int),
      );

      for (var d in detalles) {
        if (d['lugares'] != null) {
          idsLugares.add(d['lugares']['id'].toString());
          nombresLugares.add(d['lugares']['nombre'] ?? 'Lugar');
        }
      }
    }

    // C. Verificar Inscripción (Hacemos una consulta rápida)
    bool estaInscrito = false;
    if (currentUserId != null) {
      final count = await _supabase
          .from('inscripciones')
          .count(CountOption.exact)
          .eq('ruta_id', json['id'])
          .eq('usuario_id', currentUserId);
      estaInscrito = count > 0;
    }

    // D. Contar inscritos totales reales
    final inscritosTotal = await _supabase
        .from('inscripciones')
        .count(CountOption.exact)
        .eq('ruta_id', json['id']);

    return Ruta(
      id: json['id'].toString(),
      nombre:
          json['titulo'] ?? '', // OJO: En BD es 'titulo', en App es 'nombre'
      descripcion: json['descripcion'] ?? '',
      // AQUI ESTA LA CLAVE DE LA IMAGEN:
      urlImagenPrincipal: json['url_imagen_principal'] ?? '',

      precio: (json['precio'] as num).toDouble(),
      categoria: json['categoria'] ?? 'medio',
      cuposTotales: json['cupos_totales'] ?? 10,
      cuposDisponibles: (json['cupos_totales'] ?? 10) - inscritosTotal,
      visible: json['visible'] ?? false,
      dias: json['dias'] ?? 1,

      guiaId: json['guia_id'] ?? '',
      guiaNombre: nombreGuia,
      guiaFotoUrl: fotoGuia,
      guiaRating: (perfilGuia != null && perfilGuia['rating'] != null)
          ? (perfilGuia['rating'] as num).toDouble()
          : 0.0,

      rating: 0.0, // Pendiente implementar rating real
      reviewsCount: 0,

      inscritosCount: inscritosTotal,

      lugaresIncluidos: nombresLugares,
      lugaresIncluidosIds: idsLugares,

      esFavorita: false, // Pendiente
      estaInscrito: estaInscrito,
    );
  }

  // --- MÉTODOS DE ESCRITURA (CRUD) ---

  @override
  Future<void> crearRuta(Map<String, dynamic> datosRuta) async {
    try {
      // Insertamos la cabecera de la ruta
      final rutaData = {
        'titulo': datosRuta['nombre'],
        'descripcion': datosRuta['descripcion'],
        'precio': datosRuta['precio'],
        'cupos_totales': datosRuta['cupos'],
        'dias': datosRuta['dias'],
        'categoria': datosRuta['categoria'],
        'visible': datosRuta['visible'],
        'guia_id': datosRuta['guiaId'],
        'url_imagen_principal': datosRuta['url_imagen_principal'], // Imagen
        'enlace_grupo_whatsapp': datosRuta['enlace_grupo_whatsapp'], // WhatsApp
        'estado': 'abierto',
      };

      final response = await _supabase
          .from('rutas')
          .insert(rutaData)
          .select('id')
          .single();

      final newRutaId = response['id'];

      // Insertamos los detalles (lugares)
      if (datosRuta['lugaresIds'] != null) {
        final ids = datosRuta['lugaresIds'] as List;
        for (int i = 0; i < ids.length; i++) {
          await _supabase.from('ruta_detalles').insert({
            'ruta_id': newRutaId,
            'lugar_id': int.parse(ids[i].toString()),
            'orden_visita': i + 1,
          });
        }
      }
    } catch (e) {
      print('Error creando ruta: $e');
      rethrow;
    }
  }

  @override
  Future<void> actualizarRuta(
    String rutaId,
    Map<String, dynamic> datosRuta,
  ) async {
    try {
      // Actualizar cabecera
      await _supabase
          .from('rutas')
          .update({
            'titulo': datosRuta['nombre'],
            'descripcion': datosRuta['descripcion'],
            'precio': datosRuta['precio'],
            'cupos_totales': datosRuta['cupos'],
            'dias': datosRuta['dias'],
            'categoria': datosRuta['categoria'],
            'visible': datosRuta['visible'],
            'url_imagen_principal': datosRuta['url_imagen_principal'],
            'enlace_grupo_whatsapp': datosRuta['enlace_grupo_whatsapp'],
          })
          .eq('id', rutaId);

      // Actualizar lugares (Borrar y re-insertar es lo más fácil)
      await _supabase.from('ruta_detalles').delete().eq('ruta_id', rutaId);

      if (datosRuta['lugaresIds'] != null) {
        final ids = datosRuta['lugaresIds'] as List;
        for (int i = 0; i < ids.length; i++) {
          await _supabase.from('ruta_detalles').insert({
            'ruta_id': rutaId,
            'lugar_id': int.parse(ids[i].toString()),
            'orden_visita': i + 1,
          });
        }
      }
    } catch (e) {
      print('Error actualizando ruta: $e');
      rethrow;
    }
  }

  @override
  Future<void> eliminarRuta(String rutaId) async {
    await _supabase.from('rutas').delete().eq('id', rutaId);
  }

  @override
  Future<void> inscribirseEnRuta(String rutaId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('inscripciones').insert({
      'ruta_id': rutaId,
      'usuario_id': userId,
      'estado_pago': 'pendiente',
    });
  }

  @override
  Future<void> salirDeRuta(String rutaId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('inscripciones')
        .delete()
        .eq('ruta_id', rutaId)
        .eq('usuario_id', userId);
  }

  @override
  Future<void> cancelarRuta(String rutaId, String mensaje) async {
    // Lógica: Poner estado cancelado y visible false
    await _supabase
        .from('rutas')
        .update({'visible': false, 'estado': 'cancelado'})
        .eq('id', rutaId);
    // Aquí se podría integrar lógica de notificaciones real
  }

  @override
  Future<void> toggleFavoritoRuta(String rutaId) async {
    // Pendiente: Implementar tabla favoritos_rutas
  }
}

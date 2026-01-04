import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../dominio/entidades/ruta.dart';
import '../../dominio/repositorios/rutas_repositorio.dart';

class RutasRepositorioSupabase implements RutasRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<Ruta>> obtenerRutas(String tipoFiltro) async {
    try {
      print('🔍 [RUTAS] Iniciando obtenerRutas con filtro: $tipoFiltro');
      final userId = _supabase.auth.currentUser?.id;

      // Consulta base: Usamos el alias !guia_id para traer los datos del perfil
      var query = _supabase.from('rutas').select('''
            *,
            perfiles!guia_id (seudonimo, url_foto_perfil, rating),
            ruta_detalles (
              orden_visita,
              lugares (id, nombre)
            )
          ''');

      // --- FILTROS ---
      if (tipoFiltro == 'creadas_por_mi') {
        if (userId == null) return [];

        // CORRECCIÓN DEL ERROR "AMBIGUOUS":
        // Usamos 'rutas.guia_id' para decirle explícitamente que filtre por la COLUMNA,
        // no por la relación.
        query = query.eq('rutas.guia_id', userId);

      } else if (tipoFiltro == 'inscritas') {
        if (userId == null) return [];

        final inscripciones = await _supabase
            .from('inscripciones')
            .select('ruta_id')
            .eq('usuario_id', userId);

        print('🔍 [RUTAS] Inscripciones encontradas: ${inscripciones.length}');

        final List<dynamic> ids = inscripciones
            .map((e) => e['ruta_id'])
            .toList();

        if (ids.isEmpty) return [];
        query = query.inFilter('id', ids);
      } else {
        // 'Recomendadas' (Públicas)
        query = query.eq('visible', true);
      }

      print('🔍 [RUTAS] Ejecutando query...');
      final List<dynamic> data = await query.order(
        'created_at',
        ascending: false,
      );
      print('✅ [RUTAS] Datos recibidos: ${data.length} rutas');

      if (data.isEmpty) return [];

      final rutas = await Future.wait(
        data.map((json) => _mapJsonToRuta(json, userId)),
      );
      return rutas;
    } catch (e, stackTrace) {
      print('❌ [RUTAS] Error obtenerRutas: $e');
      print('❌ [RUTAS] Stack trace: $stackTrace');
      return [];
    }
  }

  // --- MAPEO DE DATOS ---
  Future<Ruta> _mapJsonToRuta(
      Map<String, dynamic> json,
      String? currentUserId,
      ) async {
    try {
      final perfilData = json['perfiles'];
      final guiaNombre = perfilData != null
          ? (perfilData['seudonimo'] ?? perfilData['nombres'] ?? 'Guía')
          : 'Desconocido';
      final guiaFoto = perfilData != null
          ? (perfilData['url_foto_perfil'] ?? '')
          : '';

      List<String> nombres = [];
      List<String> ids = [];
      if (json['ruta_detalles'] != null) {
        final detalles = List<dynamic>.from(json['ruta_detalles']);
        detalles.sort(
              (a, b) =>
              (a['orden_visita'] as int).compareTo(b['orden_visita'] as int),
        );
        for (var d in detalles) {
          if (d['lugares'] != null) {
            ids.add(d['lugares']['id'].toString());
            nombres.add(d['lugares']['nombre'] ?? '');
          }
        }
      }

      final inscritosCount = await _supabase
          .from('inscripciones')
          .count(CountOption.exact)
          .eq('ruta_id', json['id']);

      bool estaInscrito = false;
      bool asistio = false;
      if (currentUserId != null) {
        final inscripcionData = await _supabase
            .from('inscripciones')
            .select()
            .eq('ruta_id', json['id'])
            .eq('usuario_id', currentUserId)
            .limit(1);

        if (inscripcionData.isNotEmpty) {
          estaInscrito = true;
          asistio = inscripcionData.first['asistio'] ?? false;
        }
      }

      // --- CORRECCIÓN OSRM: Usar 'geometria_json' ---
      // Tu base de datos tiene la columna 'geometria_json', no 'polyline'.
      List<LatLng> polilineaDecodificada = [];
      if (json['geometria_json'] != null) {
        final List<dynamic> rawPoints = json['geometria_json'];
        polilineaDecodificada = rawPoints.map((p) {
          return LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble());
        }).toList();
      }
      // ----------------------------------------------

      final ruta = Ruta(
        id: json['id'].toString(),
        nombre: json['titulo'] ?? '',
        descripcion: json['descripcion'] ?? '',
        urlImagenPrincipal: json['url_imagen_principal'] ?? '',
        precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
        categoria: json['categoria'] ?? 'familiar',
        cuposTotales: json['cupos_totales'] ?? 10,
        cuposDisponibles: (json['cupos_totales'] ?? 10) - inscritosCount,
        visible: json['visible'] ?? false,
        dias: json['dias'] ?? 1,

        // Asignamos los datos OSRM corregidos
        polilinea: polilineaDecodificada,
        distanciaMetros: (json['distancia_metros'] as num?)?.toDouble() ?? 0.0,
        duracionSegundos: (json['duracion_segundos'] as num?)?.toDouble() ?? 0.0,

        estado: json['estado'] ?? 'convocatoria',
        equipamiento: List<String>.from(json['equipamiento_ruta'] ?? []),
        fechaCierre: json['fecha_cierre_inscripcion'] != null
            ? DateTime.parse(json['fecha_cierre_inscripcion'])
            : null,
        fechaEvento: json['fecha_evento'] != null
            ? DateTime.parse(json['fecha_evento'])
            : null,
        puntoEncuentro: json['punto_encuentro'],
        enlaceWhatsapp: json['enlace_grupo_whatsapp'],
        asistio: asistio,
        guiaId: json['guia_id']?.toString() ?? '',
        guiaNombre: guiaNombre,
        guiaFotoUrl: guiaFoto,
        guiaRating: (perfilData != null && perfilData['rating'] != null)
            ? (perfilData['rating'] as num).toDouble()
            : 0.0,
        rating: 0.0,
        reviewsCount: 0,
        inscritosCount: inscritosCount,
        lugaresIncluidos: nombres,
        lugaresIncluidosIds: ids,
        esFavorita: false,
        estaInscrito: estaInscrito,
        esPrivada: json['es_privada'] ?? false,
        codigoAcceso: json['codigo_acceso'],
      );

      return ruta;
    } catch (e, stackTrace) {
      print('❌ [MAP] Error mapeando ruta: $e');
      print('❌ [MAP] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // --- CREAR RUTA (CORREGIDO) ---
  @override
  Future<void> crearRuta(Map<String, dynamic> datosRuta) async {
    try {
      final rutaData = {
        'titulo': datosRuta['nombre'],
        'descripcion': datosRuta['descripcion'],
        'precio': datosRuta['precio'],
        'cupos_totales': datosRuta['cupos'],
        'dias': datosRuta['dias'],
        'categoria': datosRuta['categoria'],
        'visible': datosRuta['visible'] ?? true,
        'es_privada': datosRuta['es_privada'] ?? false,
        'guia_id': datosRuta['guia_id'] ?? datosRuta['guiaId'],
        'url_imagen_principal': datosRuta['url_imagen_principal'],
        'enlace_grupo_whatsapp': datosRuta['enlace_grupo_whatsapp'],
        'estado': 'convocatoria',
        'fecha_cierre_inscripcion': datosRuta['fechaCierreInscripcion'],
        'equipamiento_ruta': datosRuta['equipamientoRuta'],
        'fecha_evento': datosRuta['fecha_evento'] ?? datosRuta['fechaEvento'],
        'punto_encuentro': datosRuta['punto_encuentro'] ?? datosRuta['puntoEncuentro'],
        'codigo_acceso': datosRuta['codigo_acceso'],

        // --- CORRECCIÓN DE NOMBRE DE COLUMNA ---
        // Usamos 'geometria_json' que es lo que tienes en tu Base de Datos
        'geometria_json': datosRuta['geometria_json'],
        'distancia_metros': datosRuta['distancia_metros'],
        'duracion_segundos': datosRuta['duracion_segundos'],
        // ---------------------------------------
      };

      final response = await _supabase
          .from('rutas')
          .insert(rutaData)
          .select('id')
          .single();
      final rutaId = response['id'];
      await _insertarDetalles(rutaId, datosRuta['lugaresIds']);
    } catch (e) {
      print('Error creando ruta: $e');
      rethrow;
    }
  }

  // --- ACTUALIZAR RUTA (CORREGIDO) ---
  @override
  Future<void> actualizarRuta(
      String rutaId,
      Map<String, dynamic> datosRuta,
      ) async {
    try {
      final datosUpdate = {
        'titulo': datosRuta['nombre'],
        'descripcion': datosRuta['descripcion'],
        'precio': datosRuta['precio'],
        'cupos_totales': datosRuta['cupos'],
        'dias': datosRuta['dias'],
        'categoria': datosRuta['categoria'],
        'visible': datosRuta['visible'],
        'es_privada': datosRuta['es_privada'],
        'codigo_acceso': datosRuta['codigo_acceso'],
        'url_imagen_principal': datosRuta['url_imagen_principal'],
        'enlace_grupo_whatsapp': datosRuta['enlace_grupo_whatsapp'],
        'fecha_cierre_inscripcion': datosRuta['fechaCierreInscripcion'],
        'equipamiento_ruta': datosRuta['equipamientoRuta'],
        'fecha_evento': datosRuta['fechaEvento'],
        'punto_encuentro': datosRuta['puntoEncuentro'],
      };

      // Si hay nueva geometría, actualizamos usando el nombre correcto
      if (datosRuta['geometria_json'] != null) {
        datosUpdate['geometria_json'] = datosRuta['geometria_json'];
        datosUpdate['distancia_metros'] = datosRuta['distancia_metros'];
        datosUpdate['duracion_segundos'] = datosRuta['duracion_segundos'];
      }

      await _supabase.from('rutas').update(datosUpdate).eq('id', rutaId);

      if (datosRuta['lugaresIds'] != null) {
        await _supabase.from('ruta_detalles').delete().eq('ruta_id', rutaId);
        await _insertarDetalles(int.parse(rutaId), datosRuta['lugaresIds']);
      }
    } catch (e) {
      print('Error actualizando ruta: $e');
      rethrow;
    }
  }

  // --- ELIMINAR RUTA ---
  @override
  Future<void> eliminarRuta(String rutaId) async {
    try {
      final inscritos = await _supabase
          .from('inscripciones')
          .count(CountOption.exact)
          .eq('ruta_id', rutaId);

      if (inscritos > 0) {
        throw Exception(
          'No se puede eliminar: Hay $inscritos personas inscritas.',
        );
      }
      await _supabase.from('rutas').delete().eq('id', rutaId);
    } catch (e) {
      print('Error eliminando: $e');
      rethrow;
    }
  }

  // Helper para insertar detalles
  Future<void> _insertarDetalles(dynamic rutaId, dynamic lugaresIds) async {
    if (lugaresIds != null && (lugaresIds as List).isNotEmpty) {
      final List ids = lugaresIds;
      for (int i = 0; i < ids.length; i++) {
        await _supabase.from('ruta_detalles').insert({
          'ruta_id': rutaId,
          'lugar_id': int.parse(ids[i].toString()),
          'orden_visita': i + 1,
        });
      }
    }
  }

  @override
  Future<void> inscribirseEnRuta(String rutaId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final ruta = await _supabase
        .from('rutas')
        .select('cupos_totales')
        .eq('id', rutaId)
        .single();
    final inscritos = await _supabase
        .from('inscripciones')
        .count(CountOption.exact)
        .eq('ruta_id', rutaId);

    if (inscritos >= (ruta['cupos_totales'] as int)) {
      throw Exception('Ruta llena');
    }

    await _supabase.from('inscripciones').insert({
      'ruta_id': rutaId,
      'usuario_id': userId,
      'estado_pago': 'pendiente',
    });
  }

  @override
  Future<void> unirseARutaPorCodigo(String codigo) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Debes iniciar sesión');

    final rutaResponse = await _supabase
        .from('rutas')
        .select('id, cupos_totales')
        .eq('codigo_acceso', codigo)
        .maybeSingle();

    if (rutaResponse == null) {
      throw Exception('Código de ruta inválido');
    }

    final rutaId = rutaResponse['id'];
    final cuposTotales = rutaResponse['cupos_totales'] as int;

    final inscripciones = await _supabase
        .from('inscripciones')
        .count(CountOption.exact)
        .eq('ruta_id', rutaId)
        .eq('usuario_id', userId);

    if (inscripciones > 0) {
      throw Exception('Ya estás inscrito en esta ruta');
    }

    final totalInscritos = await _supabase
        .from('inscripciones')
        .count(CountOption.exact)
        .eq('ruta_id', rutaId);

    if (totalInscritos >= cuposTotales) {
      throw Exception('La ruta está llena');
    }

    await _supabase.from('inscripciones').insert({
      'ruta_id': rutaId,
      'usuario_id': userId,
      'estado_pago': 'pendiente',
      'asistio': false,
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
    await _supabase
        .from('rutas')
        .update({'visible': false, 'estado': 'cancelado'})
        .eq('id', rutaId);
    await _supabase.from('inscripciones').delete().eq('ruta_id', rutaId);
  }

  @override
  Future<void> toggleFavoritoRuta(String rutaId) async {}

  Future<void> marcarAsistencia(String rutaId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('inscripciones')
        .update({
      'asistio': true,
      'fecha_asistencia': DateTime.now().toIso8601String(),
    })
        .eq('ruta_id', rutaId)
        .eq('usuario_id', userId);
  }

  Future<void> cambiarEstadoRuta(String rutaId, String nuevoEstado) async {
    await _supabase
        .from('rutas')
        .update({'estado': nuevoEstado})
        .eq('id', rutaId);
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dominio/entidades/ruta.dart';
import '../../dominio/repositorios/rutas_repositorio.dart';

class RutasRepositorioSupabase implements RutasRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<Ruta>> obtenerRutas(String tipoFiltro) async {
    try {
      print('🔍 [RUTAS] Iniciando obtenerRutas con filtro: $tipoFiltro');
      final userId = _supabase.auth.currentUser?.id;
      print('🔍 [RUTAS] Usuario ID: $userId');

      // Consulta base
      var query = _supabase.from('rutas').select('''
            *,
            perfiles!guia_id (nombres, url_foto_perfil, rating),
            ruta_detalles (
              orden_visita,
              lugares (id, nombre)
            )
          ''');

      // --- FILTROS ---
      if (tipoFiltro == 'creadas_por_mi') {
        if (userId == null) {
          print('⚠️ [RUTAS] Usuario no logueado para creadas_por_mi');
          return [];
        }
        query = query.eq('guia_id', userId);
      } else if (tipoFiltro == 'inscritas') {
        // ¡NUEVO! Filtro para ver mis reservas
        if (userId == null) {
          print('⚠️ [RUTAS] Usuario no logueado para inscritas');
          return [];
        }

        // 1. Obtenemos los IDs de las rutas donde estoy inscrito
        final inscripciones = await _supabase
            .from('inscripciones')
            .select('ruta_id')
            .eq('usuario_id', userId);

        print('🔍 [RUTAS] Inscripciones encontradas: ${inscripciones.length}');

        final List<dynamic> ids = inscripciones
            .map((e) => e['ruta_id'])
            .toList();

        // 2. Filtramos las rutas que coincidan con esos IDs
        if (ids.isEmpty) {
          print('⚠️ [RUTAS] No hay inscripciones');
          return [];
        }
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

      if (data.isEmpty) {
        print('⚠️ [RUTAS] No se encontraron rutas en la base de datos');
        return [];
      }

      print('🔍 [RUTAS] Mapeando rutas...');
      final rutas = await Future.wait(
        data.map((json) => _mapJsonToRuta(json, userId)),
      );
      print('✅ [RUTAS] Rutas mapeadas exitosamente: ${rutas.length}');
      return rutas;
    } catch (e, stackTrace) {
      print('❌ [RUTAS] Error obtenerRutas: $e');
      print('❌ [RUTAS] Stack trace: $stackTrace');
      return [];
    }
  }

  // --- 1. ACTUALIZAR EL MAPEO ---
  Future<Ruta> _mapJsonToRuta(
    Map<String, dynamic> json,
    String? currentUserId,
  ) async {
    try {
      print('🔍 [MAP] Mapeando ruta ID: ${json['id']}');

      // ... (código previo de guía y lugares igual) ...
      final perfilData = json['perfiles'];
      final guiaNombre = perfilData != null
          ? (perfilData['nombres'] ?? perfilData['nombre'] ?? 'Guía')
          : 'Desconocido';
      final guiaFoto = perfilData != null
          ? (perfilData['url_foto_perfil'] ?? '')
          : '';

      // Lugares
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

      // Conteo real de inscritos
      final inscritosCount = await _supabase
          .from('inscripciones')
          .count(CountOption.exact)
          .eq('ruta_id', json['id']);

      // Verificar inscripción y ASISTENCIA
      bool estaInscrito = false;
      bool asistio = false;
      if (currentUserId != null) {
        final inscripcionData = await _supabase
            .from('inscripciones')
            .select()
            .eq('ruta_id', json['id'])
            .eq('usuario_id', currentUserId)
            .limit(
              1,
            ); // ← FIX: Limitar a 1 resultado para evitar error de múltiples filas

        if (inscripcionData.isNotEmpty) {
          final inscripcion = inscripcionData.first;
          estaInscrito = true;
          asistio =
              inscripcion['asistio'] ?? false; // Leemos si ya marcó asistencia
        }
      }

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

        // --- NUEVOS CAMPOS ---
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
      );

      print('✅ [MAP] Ruta mapeada: ${ruta.nombre}');
      return ruta;
    } catch (e, stackTrace) {
      print('❌ [MAP] Error mapeando ruta: $e');
      print('❌ [MAP] Stack trace: $stackTrace');
      print('❌ [MAP] JSON recibido: $json');
      rethrow;
    }
  }

  // --- CREAR ---
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
        'visible': datosRuta['visible'],
        'guia_id': datosRuta['guiaId'],
        'url_imagen_principal': datosRuta['url_imagen_principal'],
        'enlace_grupo_whatsapp': datosRuta['enlace_grupo_whatsapp'],
        'estado': 'convocatoria', // Por defecto al crear
        // ¡NUEVO!
        'fecha_cierre_inscripcion':
            datosRuta['fechaCierreInscripcion'], // Debe venir como String ISO8601
        'equipamiento_ruta': datosRuta['equipamientoRuta'], // List<String>
        'fecha_evento':
            datosRuta['fechaEvento'], // DateTime como String ISO8601
        'punto_encuentro': datosRuta['puntoEncuentro'], // String
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

  // --- ACTUALIZAR (¡CORREGIDO!) ---
  @override
  Future<void> actualizarRuta(
    String rutaId,
    Map<String, dynamic> datosRuta,
  ) async {
    try {
      // Actualizamos los datos básicos
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

            // ¡NUEVO!
            'fecha_cierre_inscripcion': datosRuta['fechaCierreInscripcion'],
            'equipamiento_ruta': datosRuta['equipamientoRuta'],
            'fecha_evento': datosRuta['fechaEvento'],
            'punto_encuentro': datosRuta['puntoEncuentro'],
          })
          .eq('id', rutaId);

      // Actualizamos los lugares (Borrar anteriores e insertar nuevos)
      if (datosRuta['lugaresIds'] != null) {
        await _supabase.from('ruta_detalles').delete().eq('ruta_id', rutaId);
        await _insertarDetalles(int.parse(rutaId), datosRuta['lugaresIds']);
      }
    } catch (e) {
      print('Error actualizando ruta: $e');
      rethrow;
    }
  }

  // --- ELIMINAR (¡CORREGIDO!) ---
  @override
  Future<void> eliminarRuta(String rutaId) async {
    try {
      // 1. Verificamos inscritos contando en la tabla 'inscripciones'
      // (NO buscando una columna inscritos_count que no existe)
      final inscritos = await _supabase
          .from('inscripciones')
          .count(CountOption.exact)
          .eq('ruta_id', rutaId);

      if (inscritos > 0) {
        throw Exception(
          'No se puede eliminar: Hay $inscritos personas inscritas.',
        );
      }

      // 2. Si no hay inscritos, eliminamos
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

    // Validar cupos antes
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
    // Lógica de negocio: Ocultar ruta y borrar inscripciones (o marcarlas canceladas)
    await _supabase
        .from('rutas')
        .update({'visible': false, 'estado': 'cancelado'})
        .eq('id', rutaId);

    // Aquí podrías borrar inscripciones o notificar
    // Por simplicidad, borramos para liberar a los usuarios
    await _supabase.from('inscripciones').delete().eq('ruta_id', rutaId);
  }

  @override
  Future<void> toggleFavoritoRuta(String rutaId) async {}

  // --- 2. NUEVOS MÉTODOS DE GESTIÓN (Agregalos al final) ---

  // Para el Turista: Marcar "Estoy Aquí"
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

  // Para el Guía: Cambiar estado (Iniciar/Finalizar)
  Future<void> cambiarEstadoRuta(String rutaId, String nuevoEstado) async {
    await _supabase
        .from('rutas')
        .update({'estado': nuevoEstado})
        .eq('id', rutaId);
  }
}

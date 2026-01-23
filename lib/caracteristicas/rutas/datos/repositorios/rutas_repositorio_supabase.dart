import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import '../../dominio/entidades/ruta.dart';
import '../../dominio/entidades/participante_ruta.dart';
import '../../dominio/repositorios/rutas_repositorio.dart';

class RutasRepositorioSupabase implements RutasRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<Ruta>> obtenerRutas(String tipoFiltro, {int page = 0, int pageSize = 6}) async {
    try {
      print('🔍 [RUTAS] Iniciando obtenerRutas con filtro: $tipoFiltro, page: $page');
      final userId = _supabase.auth.currentUser?.id;

      // Consulta base
      var query = _supabase.from('rutas').select('''
            *,
            perfiles!guia_id (seudonimo, url_foto_perfil, rating, nombres, apellido_paterno, apellido_materno, dni),
            ruta_detalles (
              orden_visita,
              lugares (id, nombre, latitud, longitud)
            )
          ''');

      // --- FILTROS ---
      if (tipoFiltro == 'creadas_por_mi') {
        if (userId == null) return [];
        query = query.eq('guia_id', userId).neq('estado', 'finalizada');
      } else if (tipoFiltro == 'inscritas') {
         if (userId == null) return [];
         // ... (Lógica inscritas puede requerir 2 queries, mantenemos igual)
         // Nota: Paginación en 'inscritas' es compleja si filtramos IDs primero.
         // Para simplificar, aplicaremos range SOLO si no es 'inscritas' o si 'inscritas' query returns paginated IDs.
         // Pero para MVP, paginemos 'recomendadas' y 'creadas_por_mi' que son directas.
         
         final inscripciones = await _supabase
            .from('inscripciones')
            .select('ruta_id')
            .eq('usuario_id', userId);

         final List<dynamic> ids = inscripciones.map((e) => e['ruta_id']).toList();
         if (ids.isEmpty) return [];
         query = query.inFilter('id', ids).neq('estado', 'finalizada');

      } else {
        // 'Recomendadas' (Públicas)
        query = query.eq('visible', true).neq('estado', 'finalizada');
      }

      // --- PAGINACIÓN (La Magia) ---
      // Calculamos el rango de filas a pedir
      final from = page * pageSize;
      final to = from + pageSize - 1;
      
      print('📄 [RUTAS] Paginando de $from a $to');

      List<dynamic> data;
      try {
         data = await query
            .order('created_at', ascending: false)
            .range(from, to);
      } catch (e) {
         print('⚠️ [RUTAS] Falló sort por created_at ($e). Usando fallback ID.');
         data = await query
            .order('id', ascending: false)
            .range(from, to);
      }

      print('✅ [RUTAS] Datos recibidos: ${data.length} rutas');

      if (data.isEmpty) return [];

      // Mapeo Resiliente: Si una falla, no matamos toda la lista
      final List<Ruta> rutas = [];
      for (var json in data) {
        try {
          final r = await _mapJsonToRuta(json, userId);
          rutas.add(r);
        } catch (e) {
          print('⚠️ [RUTAS] Omitiendo ruta corrupta (ID: ${json['id']}): $e');
        }
      }
      
      return rutas;
    } catch (e, stackTrace) {
      print('❌ [RUTAS] Error Fatal obtenerRutas: $e');
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
      final guiaSeudonimo = perfilData != null 
          ? (perfilData['seudonimo'] ?? 'Guía') 
          : 'Desconocido';
          
      final guiaNombreReal = perfilData != null 
          ? ('${perfilData['nombres'] ?? ''} ${perfilData['apellido_paterno'] ?? ''} ${perfilData['apellido_materno'] ?? ''}'.trim()) 
          : '';
          
      // LÓGICA DE VALIDACIÓN (Actualizada):
      // Si tiene DNI y Nombre Real registrado, lo consideramos "Validado" 
      // (ya que la columna dni_validado aun no existe).
      final String? dni = perfilData != null ? perfilData['dni']?.toString() : null;
      final bool tieneDni = dni != null && dni.isNotEmpty;
      final bool tieneNombre = guiaNombreReal.isNotEmpty;

      final guiaDniValidado = tieneDni && tieneNombre;

      final guiaNombre = guiaSeudonimo; // Por defecto usamos el seudónimo en la variable principal

      final guiaFoto = perfilData != null
          ? (perfilData['url_foto_perfil'] ?? '')
          : '';

      List<String> nombres = [];
      List<String> ids = [];
      List<LatLng> coords = []; // Lista para las coordenadas
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
            
            // Mapeo de coordenadas para el mapa
            if (d['lugares']['latitud'] != null && d['lugares']['longitud'] != null) {
               coords.add(LatLng(
                 (d['lugares']['latitud'] as num).toDouble(),
                 (d['lugares']['longitud'] as num).toDouble(),
               ));
            } else {
               // Fallback si faltan coords (no debería pasar si la BD está bien)
               coords.add(LatLng(0, 0)); 
            }
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
        categoriaId: json['categoria_id'], // <--- NUEVO
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
        guiaNombreReal: guiaNombreReal.isEmpty ? null : guiaNombreReal,
        guiaDniValidado: guiaDniValidado,
        lugaresIncluidosCoords: coords, // Asignamos la lista parseada
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final rutaData = {
        'titulo': datosRuta['nombre'],
        'descripcion': datosRuta['descripcion'],
        'precio': datosRuta['precio'],
        'cupos_totales': datosRuta['cupos'],
        'dias': datosRuta['dias'],
        'categoria': datosRuta['categoria'],
        'categoria_id': datosRuta['categoriaId'], // <--- NUEVO
        'visible': datosRuta['visible'] ?? true,
        'es_privada': datosRuta['es_privada'] ?? false,
        'guia_id': userId, // 🔥 SEGURIDAD: Forzamos el ID real del usuario
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
        'cupos_totales': datosRuta['cupos'], // <--- CORRECCIÓN CRÍTICA: Faltaba este campo
        'dias': datosRuta['dias'],
        'categoria': datosRuta['categoria'],
        'categoria_id': datosRuta['categoriaId'], // <--- NUEVO
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
  Future<void> toggleFavoritoRuta(String rutaId) async {}

  @override
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

  @override
  Future<void> cambiarEstadoRuta(String rutaId, String nuevoEstado) async {
    await _supabase
        .from('rutas')
        .update({'estado': nuevoEstado})
        .eq('id', rutaId);
  }

  // --- MÓDULO PARTICIPANTES ---
  @override
  Future<List<ParticipanteRuta>> obtenerParticipantes(String rutaId) async {
    final myId = _supabase.auth.currentUser?.id;

    try {
      print('👥 [Participantes] Cargando para ruta: $rutaId usando JOIN');

      // 1. Query con JOIN eficiente
      // Traemos inscripciones y anidamos los datos del perfil
      final response = await _supabase
          .from('inscripciones')
          .select('''
            usuario_id, 
            mostrar_nombre_real, 
            asistio,
            perfiles (
              id, 
              seudonimo, 
              nombres, 
              apellido_paterno, 
              apellido_materno, 
              dni, 
              url_foto_perfil
            )
          ''')
          .eq('ruta_id', rutaId);
      
      final List<dynamic> data = response as List<dynamic>;
      print('👥 [Participantes] Registros encontrados: ${data.length}');

      return data.map((json) {
        final perfil = json['perfiles'];
        // Manejo defensivo por si el JOIN retorna null (caso RLS en perfiles)
        final String uid = json['usuario_id'].toString();
        
        if (perfil != null) {
           return ParticipanteRuta(
            usuarioId: perfil['id'].toString(),
            seudonimo: perfil['seudonimo'] ?? 'Usuario',
            nombres: perfil['nombres'] ?? '',
            apellidoPaterno: perfil['apellido_paterno'] ?? '',
            apellidoMaterno: perfil['apellido_materno'] ?? '',
            dni: perfil['dni']?.toString() ?? '',
            urlFotoPerfil: perfil['url_foto_perfil'] ?? '',
            mostrarNombreReal: json['mostrar_nombre_real'] ?? false,
            asistio: json['asistio'] ?? false,
            soyYo: myId == perfil['id'].toString(),
          );
        } else {
           // Fallback si el perfil no es visible
           return ParticipanteRuta(
            usuarioId: uid,
            seudonimo: 'Usuario (Privado)',
            nombres: '',
            apellidoPaterno: '',
            apellidoMaterno: '',
            dni: '',
            urlFotoPerfil: '',
            mostrarNombreReal: false,
            asistio: json['asistio'] ?? false,
            soyYo: myId == uid,
          );
        }
      }).toList();

    } catch (e) {
      debugPrint('❌ [Participantes] ERROR JOIN: $e');
      return [];
    }
  }

  @override
  Future<void> cambiarPrivacidad(String rutaId, bool mostrarNombreReal) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase
          .from('inscripciones')
          .update({'mostrar_nombre_real': mostrarNombreReal})
          .eq('ruta_id', rutaId)
          .eq('usuario_id', myId);
    } catch (e) {
      debugPrint('Error changing privacy: $e');
      rethrow;
    }
  }
  @override
  Future<List<Ruta>> obtenerHistorial(String userId) async {
    try {
      print('📜 [HISTORIAL] 🚀 Iniciando carga optimizada para: $userId');

      const selectQuery = '''
            *,
            perfiles!guia_id (seudonimo, url_foto_perfil, rating, nombres, apellido_paterno, apellido_materno, dni),
            ruta_detalles (
              orden_visita,
              lugares (id, nombre, latitud, longitud)
            )
          ''';

      // 1. LANZAR CONSULTAS BASES (Con Fallback de Sort)
      Future<List<dynamic>> fetchGuiadas() async {
        try {
          return await _supabase
              .from('rutas')
              .select(selectQuery)
              .eq('guia_id', userId)
              .eq('estado', 'finalizada')
              .order('created_at', ascending: false);
        } catch (e) {
           return await _supabase
              .from('rutas')
              .select(selectQuery)
              .eq('guia_id', userId)
              .eq('estado', 'finalizada')
              .order('id', ascending: false);
        }
      }

      final guiadasFuture = fetchGuiadas();

      final inscripcionesFuture = _supabase
          .from('inscripciones')
          .select('ruta_id')
          .eq('usuario_id', userId);

      final results = await Future.wait([
        guiadasFuture,
        inscripcionesFuture,
      ]);

      final guiadasResponse = results[0] as List<dynamic>;
      final inscripciones = results[1] as List<dynamic>;

      // 2. TRAER DETALLES DE RUTAS ASISTIDAS
      List<dynamic> asistidasResponse = [];
      final idsInscritas = inscripciones.map((e) => e['ruta_id']).toList();
      
      if (idsInscritas.isNotEmpty) {
         try {
           asistidasResponse = await _supabase
              .from('rutas')
              .select(selectQuery)
              .inFilter('id', idsInscritas)
              .eq('estado', 'finalizada')
              .order('created_at', ascending: false);
         } catch (e) {
           asistidasResponse = await _supabase
              .from('rutas')
              .select(selectQuery)
              .inFilter('id', idsInscritas)
              .eq('estado', 'finalizada')
              .order('id', ascending: false);
         }
      }

      // 3. MAPEO SEGURO (Aceleración masiva pero tolerante a fallos)
      // Unificamos JSONs para evitar mapear dos veces si hay duplicados
      final Map<String, dynamic> jsonUnicos = {};
      
      // Prioridad a Guiadas
      for (var json in guiadasResponse) {
        jsonUnicos[json['id'].toString()] = json;
      }
      for (var json in asistidasResponse) {
        if (!jsonUnicos.containsKey(json['id'].toString())) {
          jsonUnicos[json['id'].toString()] = json;
        }
      }

      final List<Ruta> listaRutas = [];
      for (var json in jsonUnicos.values) {
        try {
           final r = await _mapJsonToRuta(json, userId);
           listaRutas.add(r);
        } catch (e) {
           print('⚠️ [HISTORIAL] Omitiendo ruta corrupta: $e');
        }
      }

      return listaRutas;

    } catch (e) {
      print('❌ [HISTORIAL] Error Fatal: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      final response = await _supabase
          .from('categorias')
          .select('id, nombre, descripcion')
          .order('nombre');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error obteniendo categorías: $e');
      return [];
    }
  }

}
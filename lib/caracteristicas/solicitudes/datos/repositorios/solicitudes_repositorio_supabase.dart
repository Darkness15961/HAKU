// ============================================
// Implementación: SolicitudesRepositorioSupabase
// ============================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dominio/entidades/solicitud_ruta.dart';
import '../../dominio/entidades/postulacion_guia.dart';
import '../../dominio/repositorios/solicitudes_repositorio.dart';

class SolicitudesRepositorioSupabase implements SolicitudesRepositorio {
  final SupabaseClient _supabase;

  SolicitudesRepositorioSupabase({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ============================================
  // SOLICITUDES - TURISTA
  // ============================================

  @override
  Future<SolicitudRuta> crearSolicitud(SolicitudRuta solicitud) async {
    try {
      final response = await _supabase
          .from('solicitudes_rutas')
          .insert(solicitud.toJson())
          .select()
          .single();

      return SolicitudRuta.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear solicitud: $e');
    }
  }

  @override
  Future<List<SolicitudRuta>> obtenerMisSolicitudes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Usar la función RPC para obtener datos completos
      final response =
          await _supabase.rpc(
                'obtener_mis_solicitudes',
                params: {'p_turista_id': userId},
              )
              as List;

      return response.map((json) => SolicitudRuta.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener mis solicitudes: $e');
    }
  }

  @override
  Future<SolicitudRuta?> obtenerSolicitudPorId(String solicitudId) async {
    try {
      final response = await _supabase
          .from('solicitudes_rutas')
          .select()
          .eq('id', solicitudId)
          .maybeSingle();

      if (response == null) return null;
      return SolicitudRuta.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener solicitud: $e');
    }
  }

  @override
  Future<bool> modificarSolicitud(
    String solicitudId,
    Map<String, dynamic> cambios,
  ) async {
    try {
      await _supabase
          .from('solicitudes_rutas')
          .update(cambios)
          .eq('id', solicitudId);

      return true;
    } catch (e) {
      throw Exception('Error al modificar solicitud: $e');
    }
  }

  @override
  Future<bool> cancelarSolicitud(String solicitudId, String motivo) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Llamar a la función que valida las 24 horas
      await _supabase.rpc(
        'cancelar_solicitud',
        params: {
          'p_solicitud_id': int.parse(solicitudId),
          'p_turista_id': userId,
          'p_motivo': motivo,
        },
      );

      return true;
    } catch (e) {
      // El error puede contener el mensaje de validación de 24h
      throw Exception('Error al cancelar solicitud: $e');
    }
  }

  @override
  Future<int> aceptarPostulacion(String postulacionId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Llamar a la función que crea la ruta automáticamente
      final rutaId =
          await _supabase.rpc(
                'aceptar_postulacion',
                params: {
                  'p_postulacion_id': int.parse(postulacionId),
                  'p_turista_id': userId,
                },
              )
              as int;

      return rutaId;
    } catch (e) {
      throw Exception('Error al aceptar postulación: $e');
    }
  }

  // ============================================
  // SOLICITUDES - GUÍA
  // ============================================

  @override
  Future<List<SolicitudRuta>> obtenerSolicitudesDisponibles({
    int limite = 20,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Usar la función RPC que incluye el flag "ya_postule"
      final response =
          await _supabase.rpc(
                'obtener_solicitudes_disponibles',
                params: {
                  'p_guia_id': userId,
                  'p_limite': limite,
                  'p_offset': offset,
                },
              )
              as List;

      return response.map((json) => SolicitudRuta.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener solicitudes disponibles: $e');
    }
  }

  // ============================================
  // POSTULACIONES - GUÍA
  // ============================================

  @override
  Future<PostulacionGuia> crearPostulacion(PostulacionGuia postulacion) async {
    try {
      final response = await _supabase
          .from('postulaciones_guias')
          .insert(postulacion.toJson())
          .select()
          .single();

      return PostulacionGuia.fromJson(response);
    } catch (e) {
      // Puede fallar si ya postuló (constraint unique_guia_solicitud)
      throw Exception('Error al crear postulación: $e');
    }
  }

  @override
  Future<List<PostulacionGuia>> obtenerMisPostulaciones() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Usar la función RPC para obtener datos completos
      final response =
          await _supabase.rpc(
                'obtener_mis_postulaciones',
                params: {'p_guia_id': userId},
              )
              as List;

      return response.map((json) => PostulacionGuia.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener mis postulaciones: $e');
    }
  }

  @override
  Future<List<PostulacionGuia>> obtenerPostulacionesDeSolicitud(
    String solicitudId,
  ) async {
    try {
      final response = await _supabase
          .from('postulaciones_guias')
          .select('''
            *,
            guia_nombre:perfiles!guia_id(seudonimo),
            guia_foto:perfiles!guia_id(url_foto_perfil),
            guia_rating:perfiles!guia_id(rating)
          ''')
          .eq('solicitud_id', solicitudId)
          .order('fecha_postulacion', ascending: false);

      return (response as List).map((json) {
        // Aplanar los datos del join
        final flatJson = {
          ...json,
          'guia_nombre': json['guia_nombre']?['seudonimo'],
          'guia_foto': json['guia_foto']?['url_foto_perfil'],
          'guia_rating': json['guia_rating']?['rating'],
        };
        return PostulacionGuia.fromJson(Map<String, dynamic>.from(flatJson));
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener postulaciones de solicitud: $e');
    }
  }

  // ============================================
  // RUTAS PRIVADAS
  // ============================================

  @override
  Future<bool> validarCodigoRuta(String rutaId, String codigo) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final resultado =
          await _supabase.rpc(
                'validar_codigo_ruta',
                params: {
                  'p_ruta_id': int.parse(rutaId),
                  'p_codigo': codigo,
                  'p_usuario_id': userId, // Puede ser null si no está logueado
                },
              )
              as bool;

      return resultado;
    } catch (e) {
      throw Exception('Error al validar código: $e');
    }
  }

  // ============================================
  // UTILIDADES
  // ============================================

  @override
  Future<bool> yaPostule(String solicitudId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('postulaciones_guias')
          .select('id')
          .eq('solicitud_id', solicitudId)
          .eq('guia_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}

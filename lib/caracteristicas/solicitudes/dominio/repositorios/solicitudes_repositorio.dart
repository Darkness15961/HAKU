// ============================================
// Repositorio: SolicitudesRepositorio (Interfaz)
// ============================================

import '../entidades/solicitud_ruta.dart';
import '../entidades/postulacion_guia.dart';

abstract class SolicitudesRepositorio {
  // ============================================
  // SOLICITUDES - TURISTA
  // ============================================

  /// Crear una nueva solicitud de ruta
  Future<SolicitudRuta> crearSolicitud(SolicitudRuta solicitud);

  /// Obtener todas las solicitudes del turista actual
  Future<List<SolicitudRuta>> obtenerMisSolicitudes();

  /// Obtener una solicitud por ID
  Future<SolicitudRuta?> obtenerSolicitudPorId(String solicitudId);

  /// Modificar una solicitud existente (solo si está buscando guía)
  Future<bool> modificarSolicitud(
    String solicitudId,
    Map<String, dynamic> cambios,
  );

  /// Cancelar una solicitud (validación 24h en backend)
  Future<bool> cancelarSolicitud(String solicitudId, String motivo);

  /// Aceptar una postulación (crea ruta automáticamente)
  Future<int> aceptarPostulacion(String postulacionId);

  // ============================================
  // SOLICITUDES - GUÍA
  // ============================================

  /// Obtener solicitudes disponibles para postular
  Future<List<SolicitudRuta>> obtenerSolicitudesDisponibles({
    int limite = 20,
    int offset = 0,
  });

  // ============================================
  // POSTULACIONES - GUÍA
  // ============================================

  /// Crear una postulación a una solicitud
  Future<PostulacionGuia> crearPostulacion(PostulacionGuia postulacion);

  /// Obtener todas las postulaciones del guía actual
  Future<List<PostulacionGuia>> obtenerMisPostulaciones();

  /// Obtener postulaciones de una solicitud específica
  Future<List<PostulacionGuia>> obtenerPostulacionesDeSolicitud(
    String solicitudId,
  );

  // ============================================
  // RUTAS PRIVADAS
  // ============================================

  /// Validar código de acceso a ruta privada
  Future<bool> validarCodigoRuta(String rutaId, String codigo);

  // ============================================
  // UTILIDADES
  // ============================================

  /// Verificar si el usuario ya postuló a una solicitud
  Future<bool> yaPostule(String solicitudId);
}

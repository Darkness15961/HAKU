// ============================================
// ViewModel: SolicitudesVM
// ============================================

import 'package:flutter/material.dart';
import '../../dominio/entidades/solicitud_ruta.dart';
import '../../dominio/entidades/postulacion_guia.dart';
import '../../dominio/repositorios/solicitudes_repositorio.dart';
import '../../datos/repositorios/solicitudes_repositorio_supabase.dart';

class SolicitudesVM extends ChangeNotifier {
  final SolicitudesRepositorio _repositorio;

  SolicitudesVM({SolicitudesRepositorio? repositorio})
    : _repositorio = repositorio ?? SolicitudesRepositorioSupabase();

  // ============================================
  // ESTADO - TURISTA
  // ============================================

  List<SolicitudRuta> _misSolicitudes = [];
  bool _cargandoMisSolicitudes = false;
  String? _errorMisSolicitudes;

  List<SolicitudRuta> get misSolicitudes => _misSolicitudes;
  bool get cargandoMisSolicitudes => _cargandoMisSolicitudes;
  String? get errorMisSolicitudes => _errorMisSolicitudes;

  // Filtros para mis solicitudes
  List<SolicitudRuta> get solicitudesBuscandoGuia =>
      _misSolicitudes.where((s) => s.estado == 'buscando_guia').toList();

  List<SolicitudRuta> get solicitudesConGuia =>
      _misSolicitudes.where((s) => s.estado == 'guia_asignado').toList();

  List<SolicitudRuta> get solicitudesCanceladas =>
      _misSolicitudes.where((s) => s.estado == 'cancelada').toList();

  List<SolicitudRuta> get solicitudesCompletadas =>
      _misSolicitudes.where((s) => s.estado == 'completada').toList();

  // ============================================
  // ESTADO - GUÍA
  // ============================================

  List<SolicitudRuta> _solicitudesDisponibles = [];
  bool _cargandoSolicitudesDisponibles = false;
  String? _errorSolicitudesDisponibles;

  List<SolicitudRuta> get solicitudesDisponibles => _solicitudesDisponibles;
  bool get cargandoSolicitudesDisponibles => _cargandoSolicitudesDisponibles;
  String? get errorSolicitudesDisponibles => _errorSolicitudesDisponibles;

  List<PostulacionGuia> _misPostulaciones = [];
  bool _cargandoMisPostulaciones = false;
  String? _errorMisPostulaciones;

  List<PostulacionGuia> get misPostulaciones => _misPostulaciones;
  bool get cargandoMisPostulaciones => _cargandoMisPostulaciones;
  String? get errorMisPostulaciones => _errorMisPostulaciones;

  // Filtros para postulaciones
  List<PostulacionGuia> get postulacionesPendientes =>
      _misPostulaciones.where((p) => p.estado == 'pendiente').toList();

  List<PostulacionGuia> get postulacionesAceptadas =>
      _misPostulaciones.where((p) => p.estado == 'aceptada').toList();

  List<PostulacionGuia> get postulacionesRechazadas =>
      _misPostulaciones.where((p) => p.estado == 'rechazada').toList();

  // ============================================
  // ESTADO - DETALLE DE SOLICITUD
  // ============================================

  SolicitudRuta? _solicitudActual;
  List<PostulacionGuia> _postulacionesSolicitudActual = [];
  bool _cargandoDetalleSolicitud = false;

  SolicitudRuta? get solicitudActual => _solicitudActual;
  List<PostulacionGuia> get postulacionesSolicitudActual =>
      _postulacionesSolicitudActual;
  bool get cargandoDetalleSolicitud => _cargandoDetalleSolicitud;

  // ============================================
  // MÉTODOS - TURISTA
  // ============================================

  /// Crear una nueva solicitud de ruta
  Future<bool> crearSolicitud(SolicitudRuta solicitud) async {
    try {
      final nuevaSolicitud = await _repositorio.crearSolicitud(solicitud);
      _misSolicitudes.insert(0, nuevaSolicitud);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al crear solicitud: $e');
      return false;
    }
  }

  /// Cargar todas las solicitudes del turista
  Future<void> cargarMisSolicitudes() async {
    _cargandoMisSolicitudes = true;
    _errorMisSolicitudes = null;
    notifyListeners();

    try {
      _misSolicitudes = await _repositorio.obtenerMisSolicitudes();
      _errorMisSolicitudes = null;
    } catch (e) {
      _errorMisSolicitudes = e.toString();
      debugPrint('Error al cargar mis solicitudes: $e');
    } finally {
      _cargandoMisSolicitudes = false;
      notifyListeners();
    }
  }

  /// Modificar una solicitud existente
  Future<bool> modificarSolicitud(
    String solicitudId,
    Map<String, dynamic> cambios,
  ) async {
    try {
      final exito = await _repositorio.modificarSolicitud(solicitudId, cambios);
      if (exito) {
        // Actualizar en la lista local
        final index = _misSolicitudes.indexWhere((s) => s.id == solicitudId);
        if (index != -1) {
          await cargarMisSolicitudes(); // Recargar para obtener datos actualizados
        }
      }
      return exito;
    } catch (e) {
      debugPrint('Error al modificar solicitud: $e');
      return false;
    }
  }

  /// Cancelar una solicitud (validación 24h en backend)
  Future<String?> cancelarSolicitud(String solicitudId, String motivo) async {
    try {
      await _repositorio.cancelarSolicitud(solicitudId, motivo);
      await cargarMisSolicitudes(); // Recargar lista
      return null; // Sin error
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint('Error al cancelar solicitud: $errorMsg');

      // Extraer mensaje de error específico
      if (errorMsg.contains('24 horas')) {
        return 'No se puede cancelar con menos de 24 horas de anticipación';
      }
      return 'Error al cancelar la solicitud';
    }
  }

  /// Aceptar una postulación (crea ruta automáticamente)
  Future<int?> aceptarPostulacion(String postulacionId) async {
    try {
      final rutaId = await _repositorio.aceptarPostulacion(postulacionId);
      await cargarMisSolicitudes(); // Recargar para ver cambio de estado
      return rutaId;
    } catch (e) {
      debugPrint('Error al aceptar postulación: $e');
      return null;
    }
  }

  /// Cargar detalle de una solicitud con sus postulaciones
  Future<void> cargarDetalleSolicitud(String solicitudId) async {
    _cargandoDetalleSolicitud = true;
    notifyListeners();

    try {
      _solicitudActual = await _repositorio.obtenerSolicitudPorId(solicitudId);
      _postulacionesSolicitudActual = await _repositorio
          .obtenerPostulacionesDeSolicitud(solicitudId);
    } catch (e) {
      debugPrint('Error al cargar detalle de solicitud: $e');
    } finally {
      _cargandoDetalleSolicitud = false;
      notifyListeners();
    }
  }

  // ============================================
  // MÉTODOS - GUÍA
  // ============================================

  /// Cargar solicitudes disponibles para postular
  Future<void> cargarSolicitudesDisponibles({
    int limite = 20,
    int offset = 0,
  }) async {
    _cargandoSolicitudesDisponibles = true;
    _errorSolicitudesDisponibles = null;
    notifyListeners();

    try {
      _solicitudesDisponibles = await _repositorio
          .obtenerSolicitudesDisponibles(limite: limite, offset: offset);
      _errorSolicitudesDisponibles = null;
    } catch (e) {
      _errorSolicitudesDisponibles = e.toString();
      debugPrint('Error al cargar solicitudes disponibles: $e');
    } finally {
      _cargandoSolicitudesDisponibles = false;
      notifyListeners();
    }
  }

  /// Crear una postulación a una solicitud
  Future<bool> crearPostulacion(PostulacionGuia postulacion) async {
    try {
      final nuevaPostulacion = await _repositorio.crearPostulacion(postulacion);
      _misPostulaciones.insert(0, nuevaPostulacion);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al crear postulación: $e');

      // Verificar si es error de postulación duplicada
      if (e.toString().contains('unique_guia_solicitud')) {
        throw Exception('Ya has postulado a esta solicitud');
      }
      return false;
    }
  }

  /// Cargar todas las postulaciones del guía
  Future<void> cargarMisPostulaciones() async {
    _cargandoMisPostulaciones = true;
    _errorMisPostulaciones = null;
    notifyListeners();

    try {
      _misPostulaciones = await _repositorio.obtenerMisPostulaciones();
      _errorMisPostulaciones = null;
    } catch (e) {
      _errorMisPostulaciones = e.toString();
      debugPrint('Error al cargar mis postulaciones: $e');
    } finally {
      _cargandoMisPostulaciones = false;
      notifyListeners();
    }
  }

  /// Verificar si el guía ya postuló a una solicitud
  Future<bool> yaPostule(String solicitudId) async {
    try {
      return await _repositorio.yaPostule(solicitudId);
    } catch (e) {
      debugPrint('Error al verificar postulación: $e');
      return false;
    }
  }

  // ============================================
  // MÉTODOS - RUTAS PRIVADAS
  // ============================================

  /// Validar código de acceso a ruta privada
  Future<bool> validarCodigoRuta(String rutaId, String codigo) async {
    try {
      return await _repositorio.validarCodigoRuta(rutaId, codigo);
    } catch (e) {
      debugPrint('Error al validar código: $e');
      return false;
    }
  }

  // ============================================
  // UTILIDADES
  // ============================================

  /// Limpiar estado
  void limpiar() {
    _misSolicitudes = [];
    _solicitudesDisponibles = [];
    _misPostulaciones = [];
    _solicitudActual = null;
    _postulacionesSolicitudActual = [];
    _errorMisSolicitudes = null;
    _errorSolicitudesDisponibles = null;
    _errorMisPostulaciones = null;
    notifyListeners();
  }

  /// Refrescar todo (útil para pull-to-refresh)
  Future<void> refrescarTodo({required bool esGuia}) async {
    if (esGuia) {
      await Future.wait([
        cargarSolicitudesDisponibles(),
        cargarMisPostulaciones(),
      ]);
    } else {
      await cargarMisSolicitudes();
    }
  }
}

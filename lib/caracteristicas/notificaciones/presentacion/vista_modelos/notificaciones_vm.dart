// lib/features/notificaciones/presentacion/vista_modelos/notificaciones_vm.dart

import 'package:flutter/material.dart';
import '../../dominio/entidades/notificacion.dart';
import '../../dominio/casos_uso/obtener_notificaciones.dart';
import '../../dominio/casos_uso/marcar_notificacion_leida.dart';

class NotificacionesVM extends ChangeNotifier {
  final ObtenerNotificaciones _obtenerNotificaciones;
  final MarcarNotificacionLeida _marcarNotificacionLeida;

  NotificacionesVM({
    required ObtenerNotificaciones obtenerNotificaciones,
    required MarcarNotificacionLeida marcarNotificacionLeida,
  })  : _obtenerNotificaciones = obtenerNotificaciones,
        _marcarNotificacionLeida = marcarNotificacionLeida;

  List<Notificacion> _notificaciones = [];
  List<Notificacion> get notificaciones => _notificaciones;

  // Getter para la campana 🔔
  int get unreadCount => _notificaciones.where((n) => !n.leido).length;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  // Método para cargar los datos
  Future<void> cargarNotificaciones() async {
    _estaCargando = true;
    notifyListeners();

    // Llama al Caso de Uso, que a su vez llama al Mock
    _notificaciones = await _obtenerNotificaciones();

    _estaCargando = false;
    notifyListeners();
  }

  // Método para actualizar el estado
  Future<void> marcarComoLeida(String notificacionId) async {
    // Llama al Caso de Uso
    await _marcarNotificacionLeida(notificacionId);

    // Actualiza el estado localmente para que la UI cambie al instante
    final index = _notificaciones.indexWhere((n) => n.id == notificacionId);
    if (index != -1) {
      _notificaciones[index].leido = true;
      notifyListeners(); // Actualiza la lista y el contador 'unreadCount'
    }
  }
}
// lib/features/notificaciones/dominio/casos_uso/marcar_notificacion_leida.dart

import '../repositorios/notificacion_repositorio.dart';

class MarcarNotificacionLeida {
  final NotificacionRepositorio repositorio;

  MarcarNotificacionLeida(this.repositorio);

  Future<void> call(String notificacionId) async {
    return await repositorio.marcarComoLeida(notificacionId);
  }
}
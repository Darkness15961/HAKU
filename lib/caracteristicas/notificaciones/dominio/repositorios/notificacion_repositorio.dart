// lib/features/notificaciones/dominio/repositorios/notificacion_repositorio.dart

import '../entidades/notificacion.dart';

// El contrato que el ViewModel espera
abstract class NotificacionRepositorio {
  Future<List<Notificacion>> getNotificaciones();
  Future<void> marcarComoLeida(String notificacionId);
}
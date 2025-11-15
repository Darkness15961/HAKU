// lib/features/notificaciones/dominio/casos_uso/obtener_notificaciones.dart

import '../entidades/notificacion.dart';
import '../repositorios/notificacion_repositorio.dart';

class ObtenerNotificaciones {
  final NotificacionRepositorio repositorio;

  ObtenerNotificaciones(this.repositorio);

  Future<List<Notificacion>> call() async {
    // Aquí podrías agregar lógica de negocio (como ordenar por fecha)
    final notificaciones = await repositorio.getNotificaciones();
    notificaciones.sort((a, b) => b.fecha.compareTo(a.fecha)); // Ordena más nuevas primero
    return notificaciones;
  }
}
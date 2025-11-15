// lib/caracteristicas/notificaciones/data/repositorios/notificacion_repositorio_mock.dart

// --- ¡CORREGIDO! ---
import '../../dominio/entidades/notificacion.dart';
import '../../dominio/repositorios/notificacion_repositorio.dart';
// --- FIN DE LA CORRECCIÓN ---

// Esta clase implementa el contrato y simula ser la base de datos
class NotificacionRepositorioMock implements NotificacionRepositorio {

  // --- LOS DATOS FALSOS VIVEN AQUÍ ---
  final List<Notificacion> _listaDeNotificaciones = [
    Notificacion(
      id: '1',
      titulo: 'Ruta Cancelada: Aventura en la Montaña',
      cuerpo: 'Lamentablemente, la carretera está bloqueada por mal tiempo y no podremos realizar el tour. Disculpen las molestias.',
      leido: false, // <-- No leída
      fecha: DateTime.now().subtract(const Duration(minutes: 10)),
      tipo: 'cancelacion',
    ),
    Notificacion(
      id: '2',
      titulo: '¡Inscripción Exitosa!',
      cuerpo: 'Te has inscrito correctamente al "Tour Gastronómico". ¡Nos vemos el viernes!',
      leido: false, // <-- No leída
      fecha: DateTime.now().subtract(const Duration(hours: 2)),
      tipo: 'confirmacion',
    ),
    Notificacion(
      id: '3',
      titulo: 'Recordatorio de Ruta',
      cuerpo: 'Tu ruta "Amanecer en el Templo" es mañana a las 5:00 AM.',
      leido: true, // <-- Leída
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      tipo: 'aviso',
    ),
  ];
  // --- FIN DE LOS DATOS FALSOS ---


  @override
  Future<List<Notificacion>> getNotificaciones() async {
    // Simula una llamada de red
    await Future.delayed(const Duration(seconds: 1));
    return _listaDeNotificaciones;
  }

  @override
  Future<void> marcarComoLeida(String notificacionId) async {
    // Simula una llamada a la base de datos
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _listaDeNotificaciones.indexWhere((n) => n.id == notificacionId);
    if (index != -1) {
      _listaDeNotificaciones[index].leido = true;
    }
  }

  // --- ¡AÑADIDO! ---
  // Este método simula al "Cartero" entregando una nueva notificación
  Future<void> simularEnvioDeNotificacion({
    required String titulo,
    required String cuerpo,
  }) async {
    // Simula el tiempo que tarda el servidor en procesar
    await Future.delayed(const Duration(milliseconds: 500));

    // Crea la nueva notificación
    final nuevaNotificacion = Notificacion(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID único
      titulo: titulo,
      cuerpo: cuerpo,
      leido: false, // Obviamente no está leída
      fecha: DateTime.now(),
      tipo: 'cancelacion', // Asumimos que es una cancelación
    );

    // Añade la nueva notificación al principio de la lista
    _listaDeNotificaciones.insert(0, nuevaNotificacion);
  }
// --- FIN DE LO AÑADIDO ---
}
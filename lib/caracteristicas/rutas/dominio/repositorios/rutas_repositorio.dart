// --- PIEDRA 2 (RUTAS): EL "ENCHUFE" (REPOSITORIO) ---
//
// 1. (CRUD IMPLEMENTADO): Se añadieron las funciones 'actualizarRuta',
//    'cancelarRuta(String mensaje)' y 'eliminarRuta' al contrato.

// 1. Importamos la "Receta" (Entidad) que este "Enchufe"
//    va a manejar (la que creamos en la Piedra 1).
import '../../dominio/entidades/ruta.dart';
import '../../dominio/entidades/participante_ruta.dart';

// 2. Definimos el "Contrato" (la clase abstracta)
abstract class RutasRepositorio {
  // --- ÓRDENES (Las funciones del contrato) ---

  // ORDEN 1: "Traer la lista de rutas" (Con Paginación)
  Future<List<Ruta>> obtenerRutas(String tipoFiltro, {int page = 0, int pageSize = 6});

  // ORDEN 2: "Inscribirse a una ruta"
  Future<void> inscribirseEnRuta(String rutaId);

  // ORDEN 3: "Salir de una ruta"
  Future<void> salirDeRuta(String rutaId);

  // ORDEN 4: "Marcar/Desmarcar como favorita"
  Future<void> toggleFavoritoRuta(String rutaId);

  // ORDEN 5: "Crear una nueva ruta"
  Future<void> crearRuta(Map<String, dynamic> datosRuta);

  // --- ¡NUEVAS ÓRDENES AÑADIDAS! ---

  // ORDEN 6: "Actualizar una ruta existente"
  Future<void> actualizarRuta(String rutaId, Map<String, dynamic> datosRuta);

  // ORDEN 7: "Cancelar una ruta" (Pone inscritos a 0 y la oculta)
  Future<void> cambiarEstadoRuta(String rutaId, String nuevoEstado);
  
  // --- MÓDULO PARTICIPANTES ---
  Future<List<ParticipanteRuta>> obtenerParticipantes(String rutaId);
  Future<void> cambiarPrivacidad(String rutaId, bool mostrarNombreReal);

  // ORDEN 8: "Eliminar una ruta" (Solo si no tiene inscritos)
  Future<void> eliminarRuta(String rutaId);

  // ORDEN 9: "Unirse por código"
  Future<void> unirseARutaPorCodigo(String codigo);

  // --- EXTRAS ---
  Future<void> marcarAsistencia(String rutaId);
  
  // ORDEN 10: "Obtener historial de rutas finalizadas"
  Future<List<Ruta>> obtenerHistorial(String userId);
}

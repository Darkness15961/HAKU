// --- PIEDRA 2 (AUTENTICACIÓN): EL "ENCHUFE" (ACOMPLADO CON ADMIN) ---
//
// 1. (ACOMPLADO): Se añadieron las 3 "órdenes" para el Admin:
//    obtenerSolicitudesPendientes, aprobarGuia, rechazarGuia.

// 1. Importamos la "Receta" (Entidad)
import '../entidades/usuario.dart';

// 2. Definimos el "Contrato" (la clase abstracta)
abstract class AutenticacionRepositorio {
  // --- ÓRDENES EXISTENTES ---

  // ORDEN 1: "Intentar iniciar sesión"
  Future<Usuario> iniciarSesion(String email, String password);

  // ORDEN 2: "Intentar registrar un nuevo usuario"
  Future<Usuario> registrarUsuario(
      String nombre,
      String email,
      String password,
      String dni,
      );

  // ORDEN 3: "Cerrar la sesión actual"
  Future<void> cerrarSesion();

  // ORDEN 4: "Verificar si ya hay una sesión guardada"
  Future<Usuario?> verificarEstadoSesion();

  // ORDEN 5: "Enviar la solicitud para ser guía"
  Future<void> solicitarSerGuia(String experiencia, String rutaCertificado);

  // --- ¡NUEVAS ÓRDENES PARA EL ADMIN! (ACOMPLADO) ---

  // ORDEN 6: "Traer la lista de usuarios que están 'guia_pendiente'"
  Future<List<Usuario>> obtenerSolicitudesPendientes();

  // ORDEN 7: "Aprobar a un guía" (cambiar rol a 'guia_aprobado')
  Future<void> aprobarGuia(String usuarioId);

  // ORDEN 8: "Rechazar a un guía" (cambiar rol a 'turista' o 'guia_rechazado')
  Future<void> rechazarGuia(String usuarioId);

// --- FIN DE NUEVAS ÓRDENES ---
}
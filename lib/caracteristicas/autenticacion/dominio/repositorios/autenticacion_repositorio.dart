import '../entidades/usuario.dart';

abstract class AutenticacionRepositorio {
  // --- ÓRDENES EXISTENTES ---

  // ORDEN 1: "Intentar iniciar sesión"
  Future<Usuario> iniciarSesion(String email, String password);

  // ORDEN 2: "Intentar registrar un nuevo usuario"
  Future<Usuario> registrarUsuario(
    String seudonimo,
    String email,
    String password,
    String documentoIdentidad,
    String tipoDocumento,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
  );

  // ORDEN 3: "Cerrar la sesión actual"
  Future<void> cerrarSesion();

  // ORDEN 4: "Verificar si ya hay una sesión guardada"
  Future<Usuario?> verificarEstadoSesion();

  // ORDEN 5: "Enviar la solicitud para ser guía"
  Future<void> solicitarSerGuia(String experiencia, String rutaCertificado);

  // --- ¡NUEVAS ÓRDENES PARA EL ADMIN! (Gestión de Guías) ---

  // ORDEN 6: "Traer la lista de usuarios que están 'guia_pendiente'"
  Future<List<Usuario>> obtenerSolicitudesPendientes();

  // ORDEN 7: "Aprobar a un guía" (cambiar rol a 'guia_aprobado')
  Future<void> aprobarGuia(String usuarioId);

  // ORDEN 8: "Rechazar a un guía" (cambiar rol a 'turista' o 'guia_rechazado')
  Future<void> rechazarGuia(String usuarioId);

  // --- ¡AÑADIDO! ÓRDENES PARA GESTIÓN DE CUENTAS ---

  // ORDEN 9: "Traer la lista de TODOS los usuarios"
  Future<List<Usuario>> obtenerTodosLosUsuarios();

  // ORDEN 10: "Eliminar un usuario de la base de datos"
  Future<void> eliminarUsuario(String usuarioId);

  // --- ¡NUEVO! GESTIÓN DE PERFIL ---

  // ORDEN 11: "Actualizar foto de perfil"
  Future<void> actualizarFotoPerfil(String usuarioId, String nuevaFotoUrl);

  // ORDEN 12: "Cambiar contraseña"
  Future<void> cambiarPassword(String newPassword);

  // ORDEN 13: "Iniciar sesión con Google"
  Future<Usuario> iniciarSesionConGoogle();
}

// --- PIEDRA 2 (AUTENTICACIÓN): EL "ENCHUFE" (ACTUALIZADO) ---
//
// Esta es la versión ACTUALIZADA de nuestro "Enchufe" de Seguridad.
// Le hemos añadido la nueva "ORDEN 5: solicitarSerGuia"
// que el "Mesero de Seguridad" (VM) necesitará.

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

  // --- ¡NUEVA ORDEN! (Paso 1 - Bloque 5) ---
  //
  // ORDEN 5: "Enviar la solicitud para ser guía"
  // (Le enviamos la experiencia y el certificado.
  // No necesita devolver nada, solo confirmar).
  // (Esto viene de tu MER FINAL, tabla "Solicitudes_Guia")
  Future<void> solicitarSerGuia(String experiencia, String rutaCertificado);
//
// --- FIN DE LA NUEVA ORDEN ---
}


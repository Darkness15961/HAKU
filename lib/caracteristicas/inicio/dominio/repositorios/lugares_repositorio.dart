// --- PIEDRA 1.4: EL "ENCHUFE" (ACOMPLADO PARA COMENTARIOS) ---
//
// 1. (ACOMPLADO): La 'ORDEN 5: enviarComentario' ahora requiere
//    los datos del usuario (nombre, foto) para la simulación.
// 2. (ACOMPLADO): 'urlFotoUsuario' es 'String?' (opcional),
//    tal como lo pediste.

import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';
import '../../dominio/entidades/comentario.dart';

// (La importación duplicada de 'comentario.dart' se puede eliminar,
// pero no causa error, así que la dejamos para no modificar tu código de más)
import '../entidades/comentario.dart';

// 2. Definimos el "Contrato" (la clase abstracta)
abstract class LugaresRepositorio {
  // --- Órdenes para InicioPagina ---

  Future<List<Lugar>> obtenerLugaresPopulares();
  Future<List<Provincia>> obtenerProvincias();
  Future<List<Categoria>> obtenerCategorias();
  Future<List<Lugar>> obtenerTodosLosLugares();

  // --- Órdenes para ProvinciaLugaresPagina ---

  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId);


  // --- ¡ÓRDENES DE DETALLE (ACOMPLADAS)! ---

  // --- ¡ORDEN 5 ACOMPLADA! ---
  // Ahora requiere los datos del usuario para simular
  // el envío de forma realista.
  Future<void> enviarComentario(
      String lugarId,
      String texto,
      double rating,
      // --- ¡NUEVOS CAMPOS ACOMPLADOS! ---
      String usuarioNombre,
      String? urlFotoUsuario, // <-- Opcional (String?)
      String usuarioId
      // --- FIN DE CAMPOS ---
      );
  // --- FIN DE ORDEN 5 ---

  // ORDEN 6: "Marcar/Desmarcar como favorito"
  Future<void> marcarFavorito(String lugarId);
  // (Esta orden en realidad ya no se usa, porque la lógica
  // se movió al "Cerebro" (AuthVM), pero no la borramos
  // para no "romper" nada en la "Cocina Falsa" todavía)

  // ORDEN 7: "Traer los comentarios de un lugar"
  Future<List<Comentario>> obtenerComentarios(String lugarId);
}
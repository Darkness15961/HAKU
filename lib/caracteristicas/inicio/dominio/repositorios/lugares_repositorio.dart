// --- PIEDRA 1.4: EL "ENCHUFE" (ACOMPLADO PARA COMENTARIOS Y GESTIÓN) ---
//
// (...)
// 3. (¡NUEVO!): Añadidas las órdenes de Admin para gestionar lugares.
// 4. (¡NUEVO!): Añadidas las órdenes de Admin para gestionar provincias.

import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';
import '../../dominio/entidades/comentario.dart';

import '../entidades/comentario.dart';

abstract class LugaresRepositorio {
  // --- Órdenes para InicioPagina ---
  Future<List<Lugar>> obtenerLugaresPopulares();
  Future<List<Provincia>> obtenerProvincias();
  Future<List<Categoria>> obtenerCategorias();
  Future<List<Lugar>> obtenerTodosLosLugares();

  // --- Órdenes para ProvinciaLugaresPagina ---
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId);

  // --- ¡ÓRDENES DE DETALLE (ACOMPLADAS)! ---
  Future<void> enviarComentario(
      String lugarId,
      String texto,
      double rating,
      String usuarioNombre,
      String? urlFotoUsuario,
      String usuarioId
      );
  Future<void> marcarFavorito(String lugarId);
  Future<List<Comentario>> obtenerComentarios(String lugarId);

  // --- ÓRDENES PARA GESTIÓN DE LUGARES ---
  Future<void> crearLugar(Map<String, dynamic> datosLugar);
  Future<void> actualizarLugar(String lugarId, Map<String, dynamic> datosLugar);
  Future<void> eliminarLugar(String lugarId);

  // --- ¡AÑADIDO! ÓRDENES PARA GESTIÓN DE PROVINCIAS ---

  // ORDEN 11 (Admin): "Crear una nueva provincia"
  Future<void> crearProvincia(Map<String, dynamic> datosProvincia);

  // ORDEN 12 (Admin): "Actualizar una provincia existente"
  Future<void> actualizarProvincia(String provinciaId, Map<String, dynamic> datosProvincia);

  // ORDEN 13 (Admin): "Eliminar una provincia"
  Future<void> eliminarProvincia(String provinciaId);

// --- FIN DE LO AÑADIDO ---
}
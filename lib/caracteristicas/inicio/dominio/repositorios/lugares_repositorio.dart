// --- lib/caracteristicas/inicio/dominio/repositorios/lugares_repositorio.dart ---
// (Este es el "Contrato" o "Enchufe" que define las órdenes)

import '../entidades/lugar.dart';
import '../entidades/provincia.dart';
import '../entidades/categoria.dart';
import '../entidades/comentario.dart';

abstract class LugaresRepositorio {
  // --- Métodos de Lectura (Turista) ---
  Future<List<Lugar>> obtenerLugaresPopulares();
  Future<List<Lugar>> obtenerTodosLosLugares();
  Future<List<Provincia>> obtenerProvincias();
  Future<List<Categoria>> obtenerCategorias();
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId);

  // --- Métodos de Comentarios y Favoritos ---
  Future<List<Comentario>> obtenerComentarios(String lugarId);
  Future<void> enviarComentario( String lugarId, String texto, double rating, String usuarioNombre, String? urlFotoUsuario, String usuarioId);
  Future<void> marcarFavorito(String lugarId);

  // --- MétDos de Gestión (Admin) ---

  // ¡CAMBIO AQUÍ! (Era Future<void>)
  Future<Lugar> crearLugar(Map<String, dynamic> datosLugar);

  // ¡CAMBIO AQUÍ! (Era Future<void>)
  Future<Lugar> actualizarLugar(String lugarId, Map<String, dynamic> datosLugar);

  Future<void> eliminarLugar(String lugarId);

  // --- Métodos de Gestión de Provincias ---
  Future<void> crearProvincia(Map<String, dynamic> datosProvincia);
  Future<void> actualizarProvincia(String provinciaId, Map<String, dynamic> datosProvincia);
  Future<void> eliminarProvincia(String provinciaId);
}
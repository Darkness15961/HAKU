import '../entidades/lugar.dart';
import '../entidades/provincia.dart';
import '../entidades/categoria.dart';
import '../entidades/comentario.dart';
import '../entidades/recuerdo.dart';

abstract class LugaresRepositorio {
  Future<List<Lugar>> obtenerTodosLosLugares();
  Future<List<Lugar>> obtenerLugaresPopulares();
  Future<List<Lugar>> obtenerLugaresRecientes({int page = 0, int pageSize = 10});
  Future<List<Provincia>> obtenerProvincias();
  Future<List<Categoria>> obtenerCategorias();
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId, {int page = 0, int pageSize = 10});
  Future<List<Lugar>> obtenerLugaresPorUsuario(String usuarioId);

  Future<List<Comentario>> obtenerComentarios(String lugarId);
  Future<void> enviarComentario(
    String lugarId,
    String texto,
    double rating,
    String usuarioNombre,
    String? urlFotoUsuario,
    String usuarioId,
  );
  Future<void> marcarFavorito(String lugarId);

  Future<Lugar> crearLugar(Map<String, dynamic> datosLugar);
  Future<Lugar> actualizarLugar(
    String lugarId,
    Map<String, dynamic> datosLugar,
  );
  Future<void> eliminarLugar(String lugarId);

  Future<void> crearProvincia(Map<String, dynamic> datosProvincia);
  Future<void> actualizarProvincia(
    String provinciaId,
    Map<String, dynamic> datosProvincia,
  );
  Future<void> eliminarProvincia(String provinciaId);
  Future<List<String>> obtenerIdsFavoritos(String usuarioId);

  // Memories
  Future<void> crearRecuerdo({
    required String rutaId,
    required String fotoUrl,
    required double latitud,
    required double longitud,
    String? comentario,
  });
  Future<List<Recuerdo>> obtenerMisRecuerdos();
}

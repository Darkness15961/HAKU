// --- PIEDRA 1.4: EL "ENCHUFE" (REPOSITORIO/CONTRATO) ---
//
// Esta es la versión ACTUALIZADA de nuestro "Enchufe".
// Le hemos añadido las nuevas "órdenes" que
// la página de detalle (DetalleLugarPagina) necesitará.

// 1. Importamos todas las "Recetas" (Entidades)
//    que este "Enchufe" va a manejar.
import '../entidades/lugar.dart';
import '../entidades/provincia.dart';
import '../entidades/categoria.dart';

// --- ¡NUEVA IMPORTACIÓN! ---
// Importamos la "Receta" de Comentario que acabamos de crear.
import '../entidades/comentario.dart';

// 2. Definimos el "Contrato" (la clase abstracta)
//    Esta es la lista de TODAS las "órdenes" que el "Mesero" (VM)
//    puede pedirle a la "Cocina" (Mock o API Real).
abstract class LugaresRepositorio {
  // --- Órdenes para InicioPagina ---

  // ORDEN 1: "Traer la lista de lugares populares"
  // (Devuelve una lista de "Recetas" Lugar)
  Future<List<Lugar>> obtenerLugaresPopulares();

  // ORDEN 2: "Traer la lista de provincias"
  // (Devuelve una lista de "Recetas" Provincia)
  Future<List<Provincia>> obtenerProvincias();

  // ORDEN 3: "Traer la lista de categorías"
  // (Devuelve una lista de "Recetas" Categoria)
  Future<List<Categoria>> obtenerCategorias();

  // --- Órdenes para ProvinciaLugaresPagina ---

  // ORDEN 4: "Traer los lugares filtrados por provincia"
  // (Le enviamos un "provinciaId" y devuelve una lista de "Recetas" Lugar)
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId);

  // --- ¡NUEVAS ÓRDENES! (Para DetalleLugarPagina - Paso 6.3) ---

  // ORDEN 5: "Enviar un nuevo comentario"
  // (Le enviamos el ID del lugar, el texto y el rating.
  // No necesita devolver nada, solo confirmar que se envió).
  Future<void> enviarComentario(
      String lugarId, String texto, double rating);

  // ORDEN 6: "Marcar/Desmarcar como favorito"
  // (Le enviamos el ID del lugar. No necesita devolver nada).
  Future<void> marcarFavorito(String lugarId);

  // ORDEN 7: "Traer los comentarios de un lugar"
  // (Le enviamos el ID del lugar y esperamos que devuelva
  // una lista de "Recetas" Comentario).
  Future<List<Comentario>> obtenerComentarios(String lugarId);
}


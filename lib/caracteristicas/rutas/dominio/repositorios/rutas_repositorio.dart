// --- PIEDRA 2 (RUTAS): EL "ENCHUFE" (REPOSITORIO) ---
//
// Este es el "Contrato" que define todas las "órdenes"
// relacionadas con las Rutas que el "Mesero de Rutas" (RutasVM)
// puede "pedirle" a la "Cocina" (Mock o API Real).

// 1. Importamos la "Receta" (Entidad) que este "Enchufe"
//    va a manejar (la que creamos en la Piedra 1).
import '../entidades/ruta.dart';

// 2. Definimos el "Contrato" (la clase abstracta)
abstract class RutasRepositorio {
  // --- ÓRDENES (Las funciones del contrato) ---

  // ORDEN 1: "Traer la lista de rutas"
  // (Le pasaremos el "tipo" de filtro que el usuario
  // seleccionó en las pestañas de tu diseño:
  // 'recomendadas', 'guardadas', o 'creadas_por_mi')
  Future<List<Ruta>> obtenerRutas(String tipoFiltro);

  // ORDEN 2: "Inscribirse a una ruta"
  // (Llamada desde la página de detalle.
  // Le enviamos el ID de la ruta a la que el Turista
  // se quiere inscribir).
  Future<void> inscribirseEnRuta(String rutaId);

  // ORDEN 3: "Salir de una ruta"
  // (Llamada desde la página de detalle.
  // El Turista quiere cancelar su inscripción).
  Future<void> salirDeRuta(String rutaId);

  // ORDEN 4: "Marcar/Desmarcar como favorita"
  // (Llamada desde la página de detalle o la lista.
  // (El Backend se encargará de revisar la tabla pivote
  // "Favoritos_Ruta" y añadir o quitar el ID del usuario).
  Future<void> toggleFavoritoRuta(String rutaId);

  // ORDEN 5: "Crear una nueva ruta"
  // (Llamada por el Guía desde el formulario "Crear Ruta".
  // Le enviaremos un "mapa" (como un JSON) con todos
  // los datos del formulario).
  Future<void> crearRuta(Map<String, dynamic> datosRuta);

// (Más adelante, si es necesario, añadiremos
// "actualizarRuta" y "eliminarRuta" para los Guías)
}


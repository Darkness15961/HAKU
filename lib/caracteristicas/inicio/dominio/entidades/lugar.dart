// --- PIEDRA 1.1: LA "RECETA" DE LUGAR (¡VERSIÓN FINAL ARREGLADA!) ---
//
// Esta es la "Receta" o "Molde" definitiva.
// Incluye TODOS los campos que tu diseño de detalle necesita.
//
// --- ¡ARREGLO! ---
// Añadimos "latitud" y "longitud" que faltaban
// y que el "Mesero de Mapa" (mapa_vm.dart) necesita.
// (Estos datos SÍ están en tu MER FINAL)

class Lugar {
  // --- Atributos del Carrusel ---
  final String id;
  final String nombre;
  final String descripcion;
  final String urlImagen;
  final double rating;
  final String categoria;

  // --- Atributos de Detalle ---
  final int reviewsCount;
  final String horario;
  final String costoEntrada;
  final List<String> puntosInteres;

  // --- ¡NUEVOS ATRIBUTOS! (El Arreglo) ---
  // (Estos vienen de tu MER FINAL)
  final double latitud;
  final double longitud;
  // --- FIN DEL ARREGLO ---

  // --- Constructor (El "Molde") ---
  Lugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagen,
    required this.rating,
    required this.categoria,

    // (Valores por defecto para que no den error)
    this.reviewsCount = 0,
    this.horario = 'No disponible',
    this.costoEntrada = 'Consultar',
    this.puntosInteres = const [],

    // --- ¡ARREGLO! ---
    // (Añadimos los nuevos campos al constructor.
    // Usamos las coordenadas de Cusco como valor por defecto
    // por si la "Cocina Falsa" (Mock) no los envía)
    this.latitud = -13.5319,
    this.longitud = -71.9675,
    // --- FIN DEL ARREGLO ---
  });
}
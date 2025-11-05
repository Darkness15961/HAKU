// --- PASO 1.3: LA "RECETA" DE PROVINCIA ---
//
// Este archivo es la "Receta" o "Molde" (Modelo) para la
// "lista bonita" de Provincias que tú diseñaste.
//
class Provincia {
  // --- Atributos que el Backend (Cocina) nos enviará ---

  // 1. Atributos DIRECTOS de la tabla "Provincias" (del MER):
  final String id; // El ID único (ej: '1', '2')
  final String nombre; // El nombre (ej: "Cusco", "Urubamba")
  final String urlImagen; // La URL de la foto que TÚ vas a añadir en el backend

  // 2. Atributos CALCULADOS (que la "Cocina" (Backend) prepara para nosotros):

  // Este campo NO es una columna en la base de datos.
  // Es un CÁLCULO que el Backend hará por nosotros.
  // (Contará cuántos "Lugares_Turisticos" tienen este "provincia_id")
  final int placesCount; // Ej: 124 (para "124 lugares")

  // Este campo TAMPOCO es una columna.
  // Es un CÁLCULO que el Backend hará.
  // (Buscará las categorías más comunes de los lugares en esta provincia)
  final List<String> categories; // Ej: ["Arqueología", "Cultural"]

  // --- El Constructor ---
  // Esto es lo que "crea" el objeto Provincia cuando recibimos los datos.
  Provincia({
    required this.id,
    required this.nombre,
    required this.urlImagen,
    required this.placesCount,
    required this.categories,
  });
}


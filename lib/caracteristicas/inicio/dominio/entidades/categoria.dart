// --- PASO 1.2: LA "RECETA" DE CATEGORÍA ---
//
// Este archivo es la "Receta" o "Molde" (Modelo) para los "Chips de Filtro"
// (ej: "Arqueología", "Naturaleza", "Aventura", etc.)
//
class Categoria {
  // --- Atributos que el Backend (Cocina) nos enviará ---
  // (Basado en la tabla "Categorias" de tu MER)

  final String id; // El ID único (ej: '1', '2')
  final String nombre; // El nombre (ej: "Arqueología")

  // (Como definimos en el MER, el Backend también nos enviará la imagen)
  final String urlImagen; // La URL de la foto/icono para el chip

  // --- El Constructor ---
  // Esto es lo que "crea" el objeto Categoria cuando recibimos los datos.
  Categoria({
    required this.id,
    required this.nombre,
    required this.urlImagen,
  });
}


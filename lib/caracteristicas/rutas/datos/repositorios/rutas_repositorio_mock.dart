// --- CARACTERISTICAS/RUTAS/DATOS/REPOSITORIOS/RUTAS_REPOSITORIO_MOCK.DART (¡Corregido!) ---
//
// 1. (ACOMPLADO): _rutasFalsasDB usa la "Receta" (Ruta) simplificada.
// 2. (BUG CORREGIDO): El método 'crearRuta' AHORA SÍ AÑADE la nueva ruta
//    a la lista '_rutasFalsasDB', solucionando el bug de "desaparición".

import '../../dominio/entidades/ruta.dart';
import '../../dominio/repositorios/rutas_repositorio.dart';

// --- Simulación de "Base de Datos Falsa" de Rutas ---
// ¡ACOMPLADO! Ahora usa la "Receta" (ruta.dart) simplificada
final List<Ruta> _rutasFalsasDB = [
  Ruta(
    id: 'r1',
    nombre: 'Aventura en el Valle Sagrado (1 Día)',
    descripcion: 'Disfruta de la experiencia completa del Valle Sagrado...',
    urlImagenPrincipal:
    'https://placehold.co/1000x600/0D47A1/FFFFFF?text=Valle+Sagrado',
    precio: 80.00,
    dificultad: 'facil',
    cuposTotales: 30, // <-- Acoplado
    cuposDisponibles: 25, // <-- Acoplado
    visible: true,
    dias: 1, // <-- Acoplado
    guiaId: 'g1',
    guiaNombre: 'Alejandro Quispe',
    guiaFotoUrl: 'https://placehold.co/100x100/333333/FFFFFF?text=AQ',
    rating: 4.8,
    reviewsCount: 120,
    lugaresIncluidos: ['Pisac', 'Ollantaytambo', 'Chinchero'],
    lugaresIncluidosIds: ['l_pisac', 'l_ollanta', 'l_chinchero'],
    inscritosCount: 12,
    esFavorita: false,
    estaInscrito: false,
  ),
  Ruta(
    id: 'r2',
    nombre: 'Trekking Salkantay (5 Días)',
    descripcion: 'Una ruta alternativa increíble a Machu Picchu...',
    urlImagenPrincipal:
    'https://placehold.co/1000x600/00897B/FFFFFF?text=Salkantay',
    precio: 900.00,
    dificultad: 'dificil',
    cuposTotales: 40, // <-- Acoplado
    cuposDisponibles: 10, // <-- Acoplado
    visible: true,
    dias: 5, // <-- Acoplado
    guiaId: 'g2',
    guiaNombre: 'Maria Fernanda',
    guiaFotoUrl: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
    rating: 4.9,
    reviewsCount: 350,
    lugaresIncluidos: ['Mollepata', 'Salkantay', 'Aguas Calientes'],
    lugaresIncluidosIds: ['l_molle', 'l_salkan', 'l_aguas'],
    inscritosCount: 20,
    esFavorita: false,
    estaInscrito: false,
  ),
  Ruta(
    id: 'r3',
    nombre: 'Explorando la Montaña de 7 Colores',
    descripcion: 'Un tour de día completo a Vinicunca...',
    urlImagenPrincipal:
    'https://placehold.co/1000x600/8B4513/FFFFFF?text=Vinicunca',
    precio: 60.00,
    dificultad: 'medio',
    cuposTotales: 25, // <-- Acoplado
    cuposDisponibles: 0, // <-- Acoplado
    visible: false,
    dias: 1, // <-- Acoplado
    guiaId: 'g_usuario_actual',
    guiaNombre: 'Mi Propia Ruta (Guía)',
    guiaFotoUrl: 'https://placehold.co/100x100/AAAAAA/FFFFFF?text=YO',
    rating: 0.0,
    reviewsCount: 0,
    lugaresIncluidos: ['Vinicunca'],
    lugaresIncluidosIds: ['l_vinicunca'],
    inscritosCount: 0,
    esFavorita: false,
    estaInscrito: false,
  ),
];

// 3. Creamos la "Cocina Falsa"
class RutasRepositorioMock implements RutasRepositorio {

  // --- ORDEN 1: "Traer la lista de rutas" ---
  @override
  Future<List<Ruta>> obtenerRutas(String tipoFiltro) async {
    await Future.delayed(const Duration(milliseconds: 900));
    switch (tipoFiltro) {
      case 'creadas_por_mi':
        return _rutasFalsasDB
            .where((ruta) => ruta.guiaId == 'g_usuario_actual')
            .toList();
      case 'guardadas':
      case 'recomendadas':
      default:
        return _rutasFalsasDB.where((ruta) => ruta.visible).toList();
    }
  }

  // --- ORDEN 2: "Crear una nueva ruta" (¡ACOMPLADO Y CORREGIDO!) ---
  @override
  Future<void> crearRuta(Map<String, dynamic> datosRuta) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print(datosRuta);

    // "Cocinamos" la nueva ruta (sin duracionHoras)
    final nuevaRuta = Ruta(
      id: 'ruta_mock_${DateTime.now().millisecondsSinceEpoch}',
      nombre: datosRuta['nombre'],
      descripcion: datosRuta['descripcion'],
      urlImagenPrincipal: 'https://placehold.co/1000x600/0288D1/FFFFFF?text=${Uri.encodeComponent(datosRuta['nombre'])}',
      precio: datosRuta['precio'],
      dificultad: datosRuta['dificultad'],
      cuposTotales: datosRuta['cupos'],
      cuposDisponibles: datosRuta['cupos'],
      visible: datosRuta['visible'],
      dias: datosRuta['dias'],

      guiaId: 'g_usuario_actual', // ¡Asignamos el ID correcto!
      guiaNombre: 'Mi Propia Ruta (Guía)',
      guiaFotoUrl: 'https://placehold.co/100x100/AAAAAA/FFFFFF?text=YO',

      rating: 0.0,
      reviewsCount: 0,
      inscritosCount: 0,

      lugaresIncluidos: datosRuta['lugaresNombres'],
      lugaresIncluidosIds: datosRuta['lugaresIds'],

      esFavorita: false,
      estaInscrito: false,
    );

    // --- ¡AQUÍ ESTÁ LA SOLUCIÓN AL BUG! ---
    // AHORA SÍ la añadimos a la "Base de Datos Falsa" (la RAM)
    _rutasFalsasDB.insert(0, nuevaRuta);
    print('----------------------------------');
  }

  // --- MÉTODOS ELIMINADOS (La lógica se movió al "Cerebro" AuthVM) ---
  @override
  Future<void> inscribirseEnRuta(String rutaId) async {}
  @override
  Future<void> salirDeRuta(String rutaId) async {}
  @override
  Future<void> toggleFavoritoRuta(String rutaId) async {}
}
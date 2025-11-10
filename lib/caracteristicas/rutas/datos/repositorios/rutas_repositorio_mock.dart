// --- CARACTERISTICAS/RUTAS/DATOS/REPOSITORIOS/RUTAS_REPOSITORIO_MOCK.DART (¡Corregido!) ---
//
// 1. (BUG DE IMAGEN CORREGIDO): Se reemplazaron las URLs 'unsplash.com'
//    por URLs fiables de 'picsum.photos' para evitar el bloqueo de red.
// 2. (ESTABLE): Mantiene la lógica de IDs de lugares ('l3', 'l4', 'l6').

import '../../dominio/entidades/ruta.dart';
import '../../dominio/repositorios/rutas_repositorio.dart';

// --- Simulación de "Base de Datos Falsa" de Rutas ---
final List<Ruta> _rutasFalsasDB = [
  Ruta(
    id: 'r1',
    nombre: 'Aventura en el Valle Sagrado (1 Día)',
    descripcion: 'Disfruta de la experiencia completa del Valle Sagrado...',
    // --- ¡IMAGEN FIABLE! ---
    urlImagenPrincipal:
    'https://picsum.photos/seed/valle_sagrado/1000/600',
    // --------------------
    precio: 80.00,
    dificultad: 'facil',
    cuposTotales: 30,
    cuposDisponibles: 25,
    visible: true,
    dias: 1,
    guiaId: 'g1',
    guiaNombre: 'Alejandro Quispe',
    guiaFotoUrl: 'https://placehold.co/100x100/333333/FFFFFF?text=AQ',
    rating: 4.8,
    reviewsCount: 120,
    lugaresIncluidos: ['Plaza de Armas', 'Salineras de Maras'],
    lugaresIncluidosIds: ['l6', 'l3'], // IDs Reales
    inscritosCount: 12,
    esFavorita: false,
    estaInscrito: false,
  ),
  Ruta(
    id: 'r2',
    nombre: 'Maras, Moray y Chinchero',
    descripcion: 'Un tour cultural por las salineras, el laboratorio inca y el pueblo textil.',
    // --- ¡IMAGEN FIABLE! ---
    urlImagenPrincipal:
    'https://picsum.photos/seed/maras_moray/1000/600',
    // --------------------
    precio: 900.00,
    dificultad: 'dificil',
    cuposTotales: 40,
    cuposDisponibles: 10,
    visible: true,
    dias: 5,
    guiaId: 'g2',
    guiaNombre: 'Maria Fernanda',
    guiaFotoUrl: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
    rating: 4.9,
    reviewsCount: 350,
    lugaresIncluidos: ['Salineras de Maras', 'Mercado de Chinchero'],
    lugaresIncluidosIds: ['l3', 'l4'], // IDs Reales
    inscritosCount: 20,
    esFavorita: false,
    estaInscrito: false,
  ),
  Ruta(
    id: 'r3',
    nombre: 'Explorando la Montaña de 7 Colores',
    descripcion: 'Un tour de día completo a Vinicunca...',
    // --- ¡IMAGEN FIABLE! ---
    urlImagenPrincipal:
    'https://picsum.photos/seed/vinicunca_ruta/1000/600',
    // --------------------
    precio: 60.00,
    dificultad: 'medio',
    cuposTotales: 25,
    cuposDisponibles: 0,
    visible: false,
    dias: 1,
    guiaId: 'g_usuario_actual',
    guiaNombre: 'Mi Propia Ruta (Guía)',
    guiaFotoUrl: 'https://placehold.co/100x100/AAAAAA/FFFFFF?text=YO',
    rating: 0.0,
    reviewsCount: 0,
    lugaresIncluidos: ['Montaña de 7 Colores'],
    lugaresIncluidosIds: ['l5'], // IDs Reales
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
      // --- ¡IMAGEN FIABLE! ---
      urlImagenPrincipal: 'https://picsum.photos/seed/${datosRuta['nombre']}/1000/600',
      // ---------------------
      precio: datosRuta['precio'],
      dificultad: datosRuta['dificultad'],
      cuposTotales: datosRuta['cupos'],
      cuposDisponibles: datosRuta['cupos'],
      visible: datosRuta['visible'],
      dias: datosRuta['dias'],

      guiaId: 'g_usuario_actual',
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
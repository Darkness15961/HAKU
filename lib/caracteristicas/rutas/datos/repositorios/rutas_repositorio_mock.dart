// --- CARACTERISTICAS/RUTAS/DATOS/REPOSITORIOS/RUTAS_REPOSITORIO_MOCK.DART (¡Corregido!) ---
//
// 1. (BUG LÓGICA CORREGIDO): 'inscribirseEnRuta' y 'salirDeRuta'
//    ahora SÍ modifican el 'inscritosCount' en la base de datos
//    falsa (_rutasFalsasDB), arreglando el bug de cupos.

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
    visible: true,
    dias: 1,
    guiaId: 'g1',
    guiaNombre: 'Alejandro Quispe',
    guiaFotoUrl: 'https://placehold.co/100x100/333333/FFFFFF?text=AQ',
    rating: 4.8,
    reviewsCount: 120,
    lugaresIncluidos: ['Plaza de Armas', 'Salineras de Maras'],
    lugaresIncluidosIds: ['l6', 'l3'], // IDs Reales
    inscritosCount: 12, // <-- ¡Tiene inscritos!
    esFavorita: false,
    estaInscrito: false,
    cuposDisponibles: 18, // (Calculado: 30 - 12)
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
    visible: true,
    dias: 5,
    guiaId: 'g2',
    guiaNombre: 'Maria Fernanda',
    guiaFotoUrl: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
    rating: 4.9,
    reviewsCount: 350,
    lugaresIncluidos: ['Salineras de Maras', 'Mercado de Chinchero'],
    lugaresIncluidosIds: ['l3', 'l4'], // IDs Reales
    inscritosCount: 20, // <-- ¡Tiene inscritos!
    esFavorita: false,
    estaInscrito: false,
    cuposDisponibles: 20, // (Calculado: 40 - 20)
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
    visible: false,
    dias: 1,
    guiaId: 'g_usuario_actual_falso', // <-- ID Falso para pruebas
    guiaNombre: 'Guía de Prueba Falso',
    guiaFotoUrl: 'https://placehold.co/100x100/AAAAAA/FFFFFF?text=YO',
    rating: 0.0,
    reviewsCount: 0,
    lugaresIncluidos: ['Montaña de 7 Colores'],
    lugaresIncluidosIds: ['l5'], // IDs Reales
    inscritosCount: 0, // <-- ¡No tiene inscritos!
    esFavorita: false,
    estaInscrito: false,
    cuposDisponibles: 25, // (Calculado: 25 - 0)
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
      // --- NOTA ---
      // Esta lógica de filtrado es temporal.
      // Cuando conectes tu AuthVM al repositorio,
      // deberás pasar el ID del guía real aquí.
      // --- FIN NOTA ---
        return _rutasFalsasDB
            .where((ruta) => ruta.guiaId != 'g1' && ruta.guiaId != 'g2')
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
      visible: datosRuta['visible'],
      dias: datosRuta['dias'],

      // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
      // Usamos los datos REALES del guía que vienen del formulario
      guiaId: datosRuta['guiaId'],
      guiaNombre: datosRuta['guiaNombre'],
      guiaFotoUrl: datosRuta['guiaFotoUrl'],
      // --- FIN DE CORRECCIÓN ---

      rating: 0.0,
      reviewsCount: 0,
      inscritosCount: 0,

      lugaresIncluidos: datosRuta['lugaresNombres'],
      lugaresIncluidosIds: datosRuta['lugaresIds'],

      esFavorita: false,
      estaInscrito: false,
      cuposDisponibles: datosRuta['cupos'], // (Calculado)
    );

    _rutasFalsasDB.insert(0, nuevaRuta);
    print('----------------------------------');
  }

  // --- ¡MÉTODOS CORREGIDOS! ---
  // Ahora SÍ actualizan la base de datos falsa
  @override
  Future<void> inscribirseEnRuta(String rutaId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('MOCK: Inscribiendo usuario a $rutaId');
    final int index = _rutasFalsasDB.indexWhere((r) => r.id == rutaId);
    if (index != -1) {
      final rutaVieja = _rutasFalsasDB[index];
      // Creamos una copia actualizada (inmutabilidad)
      _rutasFalsasDB[index] = Ruta(
        id: rutaVieja.id,
        nombre: rutaVieja.nombre,
        descripcion: rutaVieja.descripcion,
        urlImagenPrincipal: rutaVieja.urlImagenPrincipal,
        precio: rutaVieja.precio,
        dificultad: rutaVieja.dificultad,
        cuposTotales: rutaVieja.cuposTotales,
        visible: rutaVieja.visible,
        dias: rutaVieja.dias,
        guiaId: rutaVieja.guiaId,
        guiaNombre: rutaVieja.guiaNombre,
        guiaFotoUrl: rutaVieja.guiaFotoUrl,
        rating: rutaVieja.rating,
        reviewsCount: rutaVieja.reviewsCount,
        lugaresIncluidos: rutaVieja.lugaresIncluidos,
        lugaresIncluidosIds: rutaVieja.lugaresIncluidosIds,
        esFavorita: rutaVieja.esFavorita,
        estaInscrito: true, // ¡Actualizado!
        inscritosCount: rutaVieja.inscritosCount + 1, // ¡Actualizado!
        cuposDisponibles: rutaVieja.cuposDisponibles - 1, // ¡Actualizado!
      );
    }
  }
  @override
  Future<void> salirDeRuta(String rutaId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('MOCK: Saliendo de usuario de $rutaId');
    final int index = _rutasFalsasDB.indexWhere((r) => r.id == rutaId);
    if (index != -1) {
      final rutaVieja = _rutasFalsasDB[index];
      // Creamos una copia actualizada (inmutabilidad)
      _rutasFalsasDB[index] = Ruta(
        id: rutaVieja.id,
        nombre: rutaVieja.nombre,
        descripcion: rutaVieja.descripcion,
        urlImagenPrincipal: rutaVieja.urlImagenPrincipal,
        precio: rutaVieja.precio,
        dificultad: rutaVieja.dificultad,
        cuposTotales: rutaVieja.cuposTotales,
        visible: rutaVieja.visible,
        dias: rutaVieja.dias,
        guiaId: rutaVieja.guiaId,
        guiaNombre: rutaVieja.guiaNombre,
        guiaFotoUrl: rutaVieja.guiaFotoUrl,
        rating: rutaVieja.rating,
        reviewsCount: rutaVieja.reviewsCount,
        lugaresIncluidos: rutaVieja.lugaresIncluidos,
        lugaresIncluidosIds: rutaVieja.lugaresIncluidosIds,
        esFavorita: rutaVieja.esFavorita,
        estaInscrito: false, // ¡Actualizado!
        inscritosCount: rutaVieja.inscritosCount - 1, // ¡Actualizado!
        cuposDisponibles: rutaVieja.cuposDisponibles + 1, // ¡Actualizado!
      );
    }
  }
  @override
  Future<void> toggleFavoritoRuta(String rutaId) async {} // Sigue en AuthVM

  // --- ¡NUEVAS ÓRDENES IMPLEMENTADAS (MOCK)! ---

  @override
  Future<void> actualizarRuta(String rutaId, Map<String, dynamic> datosRuta) async {
    await Future.delayed(const Duration(milliseconds: 800));
    print('--- ¡ORDEN ACTUALIZAR RECIBIDA POR EL MOCK! ---');
    print(datosRuta);

    // Encontrar el índice de la ruta vieja
    final int index = _rutasFalsasDB.indexWhere((r) => r.id == rutaId);
    if (index == -1) return; // No se encontró, no hacer nada

    final Ruta rutaVieja = _rutasFalsasDB[index];

    // "Cocinamos" la ruta actualizada
    final rutaActualizada = Ruta(
      id: rutaId, // Mantenemos el ID original
      nombre: datosRuta['nombre'],
      descripcion: datosRuta['descripcion'],
      urlImagenPrincipal: 'https://picsum.photos/seed/${datosRuta['nombre']}/1000/600',
      precio: datosRuta['precio'],
      dificultad: datosRuta['dificultad'],
      cuposTotales: datosRuta['cupos'],
      visible: datosRuta['visible'],
      dias: datosRuta['dias'],

      // --- ¡CORREGIDO! ---
      // Usamos los datos del guía que vienen del formulario
      guiaId: datosRuta['guiaId'],
      guiaNombre: datosRuta['guiaNombre'],
      guiaFotoUrl: datosRuta['guiaFotoUrl'],
      // --- FIN DE CORRECCIÓN ---

      rating: rutaVieja.rating,
      reviewsCount: rutaVieja.reviewsCount,
      inscritosCount: rutaVieja.inscritosCount, // (La lógica real de cupos sería más compleja)

      lugaresIncluidos: datosRuta['lugaresNombres'],
      lugaresIncluidosIds: datosRuta['lugaresIds'],

      esFavorita: rutaVieja.esFavorita,
      estaInscrito: rutaVieja.estaInscrito,
      cuposDisponibles: (datosRuta['cupos'] - rutaVieja.inscritosCount), // (Calculado)
    );

    // Reemplazamos la ruta en la "DB"
    _rutasFalsasDB[index] = rutaActualizada;
    print('----------------------------------');
  }

  @override
  Future<void> cancelarRuta(String rutaId, String mensaje) async { // <-- ¡ACTUALIZADO!
    await Future.delayed(const Duration(milliseconds: 500));
    print('--- ¡ORDEN CANCELAR RECIBIDA POR EL MOCK! ---');
    print('MENSAJE DE DISCULPA: $mensaje'); // <-- ¡Simulación!

    final int index = _rutasFalsasDB.indexWhere((r) => r.id == rutaId);
    if (index == -1) return;

    final Ruta rutaVieja = _rutasFalsasDB[index];

    // Creamos una copia con los campos actualizados (simulando inmutabilidad)
    final rutaCancelada = Ruta(
      id: rutaVieja.id,
      nombre: rutaVieja.nombre,
      descripcion: rutaVieja.descripcion,
      urlImagenPrincipal: rutaVieja.urlImagenPrincipal,
      precio: rutaVieja.precio,
      dificultad: rutaVieja.dificultad,
      cuposTotales: rutaVieja.cuposTotales,
      cuposDisponibles: rutaVieja.cuposTotales, // Resetea cupos
      visible: false,      // <-- Lógica de negocio: la oculta
      dias: rutaVieja.dias,
      guiaId: rutaVieja.guiaId,
      guiaNombre: rutaVieja.guiaNombre,
      guiaFotoUrl: rutaVieja.guiaFotoUrl,
      rating: rutaVieja.rating,
      reviewsCount: rutaVieja.reviewsCount,
      inscritosCount: 0, // <-- Lógica de negocio: bota a los inscritos
      lugaresIncluidos: rutaVieja.lugaresIncluidos,
      lugaresIncluidosIds: rutaVieja.lugaresIncluidosIds,
      esFavorita: rutaVieja.esFavorita,
      estaInscrito: rutaVieja.estaInscrito, // El estado de inscripción del *guía* no cambia
    );

    _rutasFalsasDB[index] = rutaCancelada;
    print('Ruta $rutaId cancelada. Inscritos a 0 y no visible.');
    print('----------------------------------');
  }

  @override
  Future<void> eliminarRuta(String rutaId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('--- ¡ORDEN ELIMINAR RECIBIDA POR EL MOCK! ---');
    _rutasFalsasDB.removeWhere((ruta) => ruta.id == rutaId);
    print('Ruta $rutaId eliminada.');
    print('----------------------------------');
  }
}
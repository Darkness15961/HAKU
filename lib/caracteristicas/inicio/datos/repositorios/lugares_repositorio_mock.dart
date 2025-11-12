// --- PIEDRA 3 (INICIO): LA "COCina FALSA" (VERSIÓN FINAL ESTABLE) ---
//
// 1. (ACOMPLADO): Usa las URLs fiables de 'picsum.photos'.
// 2. (ACOMPLADO): Usa la lógica de 'enviarComentario' que guarda en RAM.
// 3. (ACOMPLADO): Usa la "Receta" de Comentario con 'lugarId' y 'usuarioId'.

import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/categoria.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/comentario.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/repositorios/lugares_repositorio.dart';


// --- Base de Datos Falsa MAESTRA de Lugares (Con Fotos Fiables) ---
final List<Lugar> _allLugaresDB = [
  // L1: Machu Picchu (Urubamba)
  Lugar(
    id: 'l1',
    nombre: 'Machu Picchu',
    descripcion: 'Antigua ciudadela inca en lo alto de los Andes. Maravilla del mundo.',
    // --- ¡URL FIABLE! ---
    urlImagen: 'https://picsum.photos/seed/mp/1000/600',
    // ----------------------
    rating: 4.9,
    categoria: 'Arqueología',
    reviewsCount: 1500,
    horario: '6:00 - 17:00',
    costoEntrada: 'S/ 152.00',
    puntosInteres: ['Intihuatana', 'Templo del Sol', 'Huayna Picchu'],
    latitud: -13.1631,
    longitud: -72.5450,
    provinciaId: 'p2', // Urubamba
  ),
  // L2: Sacsayhuamán (Cusco)
  Lugar(
    id: 'l2',
    nombre: 'Sacsayhuamán',
    descripcion: 'Impresionante fortaleza ceremonial inca con bloques ciclópeos.',
    // --- ¡URL FIABLE! ---
    urlImagen: 'https://picsum.photos/seed/sxy/1000/600',
    // ----------------------
    rating: 4.7,
    categoria: 'Arqueología',
    reviewsCount: 800,
    horario: '7:00 - 18:00',
    costoEntrada: 'S/ 70.00',
    puntosInteres: ['Torreones', 'Rodadero'],
    latitud: -13.5076,
    longitud: -71.9839,
    provinciaId: 'p1', // Cusco
  ),
  // L3: Salineras de Maras (Urubamba)
  Lugar(
    id: 'l3',
    nombre: 'Salineras de Maras',
    descripcion: 'Pozos de sal preincas que crean un paisaje espectacular.',
    // --- ¡URL FIABLE! ---
    urlImagen: 'https://picsum.photos/seed/maras/1000/600',
    // ----------------------
    rating: 4.6,
    categoria: 'Naturaleza',
    reviewsCount: 400,
    horario: '9:00 - 17:00',
    costoEntrada: 'S/ 10.00',
    puntosInteres: ['Mirador', 'Pozos'],
    latitud: -13.3039,
    longitud: -72.1557,
    provinciaId: 'p2', // Urubamba
  ),
  // L4: Mercado de Chinchero (Urubamba)
  Lugar(
    id: 'l4',
    nombre: 'Mercado de Chinchero',
    descripcion: 'Famoso mercado de artesanías y textiles de la zona andina.',
    // --- ¡URL FIABLE! ---
    urlImagen: 'https://picsum.photos/seed/chinchero/1000/600',
    // ----------------------
    rating: 4.5,
    categoria: 'Cultural',
    reviewsCount: 250,
    horario: 'Domingos',
    costoEntrada: 'Gratuito',
    puntosInteres: ['Textiles', 'Plaza'],
    latitud: -13.4357,
    longitud: -72.0460,
    provinciaId: 'p2', // Urubamba
  ),
  // L5: Montaña 7 Colores (Quispicanchi)
  Lugar(
    id: 'l5',
    nombre: 'Montaña de Siete Colores',
    descripcion: 'La majestuosa montaña Vinicunca.',
    // --- ¡URL FIABLE! ---
    urlImagen: 'https://picsum.photos/seed/vinicunca/1000/600',
    // ----------------------
    rating: 4.8,
    categoria: 'Naturaleza',
    reviewsCount: 1000,
    horario: '5:00 - 15:00',
    costoEntrada: 'S/ 20.00',
    puntosInteres: ['Mirador'],
    latitud: -13.8722,
    longitud: -71.2985,
    provinciaId: 'p4', // Quispicanchi
  ),
  // L6: Plaza de Armas (Cusco)
  Lugar(
    id: 'l6',
    nombre: 'Plaza de Armas',
    descripcion: 'Centro neurálgico de Cusco, con catedrales y arquitectura colonial.',
    // --- ¡URL FIABLE! ---
    urlImagen: 'https://picsum.photos/seed/plaza/1000/600',
    // ----------------------
    rating: 4.8,
    categoria: 'Cultural',
    reviewsCount: 1200,
    horario: 'Todo el día',
    costoEntrada: 'Gratuito',
    puntosInteres: ['Catedral', 'Piletas'],
    latitud: -13.5167,
    longitud: -71.9785,
    provinciaId: 'p1', // Cusco
  ),
];

// --- Base de Datos Falsa de Provincias (¡Con Imágenes Fiables!) ---
final List<Provincia> _provinciasDB = [
  Provincia(
    id: 'p1',
    nombre: 'Cusco',
    urlImagen: 'https://picsum.photos/seed/cusco_plaza/800/600',
    categories: ['Arqueología', 'Cultural'],
    placesCount: 2,
  ),
  Provincia(
    id: 'p2',
    nombre: 'Urubamba',
    urlImagen: 'https://picsum.photos/seed/urubamba_valle/800/600',
    categories: ['Naturaleza', 'Aventura', 'Cultural'],
    placesCount: 3,
  ),
  Provincia(
    id: 'p4',
    nombre: 'Quispicanchi',
    urlImagen: 'https://picsum.photos/seed/quispicanchi_montana/800/600',
    placesCount: 1,
    categories: ['Naturaleza'],
  ),
];

// --- ¡BASE DE DATOS FALSA DE COMENTARIOS (ACOMPLADA)! ---
final Map<String, List<Comentario>> _comentariosFalsosDB = {
  'l1': [
    Comentario(
      id: 'c1',
      texto: '¡Un lugar absolutamente increíble! La energía es única.',
      rating: 5.0,
      fecha: 'hace 2 días',
      lugarId: 'l1',
      usuarioId: '1',
      usuarioNombre: 'Alex Gálvez',
      usuarioFotoUrl: 'https://placehold.co/100x100/333333/FFFFFF?text=AG',
    ),
    Comentario(
      id: 'c2',
      texto:
      'Recomiendo ir muy temprano para evitar las multitudes. Llev... ',
      rating: 4.0,
      fecha: 'hace 1 semana',
      lugarId: 'l1',
      usuarioId: '2',
      usuarioNombre: 'Maria Fernanda',
      usuarioFotoUrl: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
    ),
  ],
};
// --- FIN DE NUEVA BASE DE DATOS ---


// --- Implementación del Repositorio (La "Cocina") ---
class LugaresRepositorioMock implements LugaresRepositorio {

  // (obtenerLugaresPopulares, obtenerTodosLosLugares, obtenerProvincias,
  // obtenerCategorias, obtenerLugaresPorProvincia se mantienen igual)
  @override
  Future<List<Lugar>> obtenerLugaresPopulares() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _allLugaresDB.where((l) => ['l1', 'l2', 'l5'].contains(l.id)).toList();
  }
  @override
  Future<List<Lugar>> obtenerTodosLosLugares() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _allLugaresDB;
  }
  @override
  Future<List<Provincia>> obtenerProvincias() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _provinciasDB;
  }
  @override
  Future<List<Categoria>> obtenerCategorias() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      Categoria(id: '1', nombre: 'Todas', urlImagen: ''),
      Categoria(
          id: '2',
          nombre: 'Arqueología',
          urlImagen: 'https://placehold.co/100/A52A2A/FFFFFF?text=Icon'),
      Categoria(
          id: '3',
          nombre: 'Naturaleza',
          urlImagen: 'https://placehold.co/100/228B22/FFFFFF?text=Icon'),
      Categoria(
          id: '4',
          nombre: 'Aventura',
          urlImagen: 'https://placehold.co/100/FF4500/FFFFFF?text=Icon'),
      Categoria(
          id: '5',
          nombre: 'Gastronomía',
          urlImagen: 'https://placehold.co/100/FFD700/FFFFFF?text=Icon'),
      Categoria(
          id: '6',
          nombre: 'Cultural',
          urlImagen: 'https://placehold.co/100/800080/FFFFFF?text=Icon'),
    ];
  }
  @override
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _allLugaresDB.where((l) => l.provinciaId == provinciaId).toList();
  }

  // --- ÓRDENES PARA DETALLE (ACOMPLADAS) ---

  // --- ORDEN 5: "Enviar un nuevo comentario" (¡ACOMPLADO!) ---
  @override
  Future<void> enviarComentario(
      String lugarId,
      String texto,
      double rating,
      String usuarioNombre,
      String? urlFotoUsuario, // Opcional
      String usuarioId
      ) async {

    await Future.delayed(const Duration(milliseconds: 500));
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');

    // 1. "Cocinamos" la "Receta" del nuevo comentario
    final nuevoComentario = Comentario(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}', // ID Falso
      texto: texto,
      rating: rating,
      fecha: 'justo ahora',
      lugarId: lugarId,
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre,
      usuarioFotoUrl: urlFotoUsuario ?? 'https://placehold.co/100x100/808080/FFFFFF?text=${usuarioNombre.substring(0,1)}', // Placeholder
    );

    // 2. Verificamos si ya existe una lista para ese lugarId
    if (!_comentariosFalsosDB.containsKey(lugarId)) {
      _comentariosFalsosDB[lugarId] = []; // Si no, creamos la lista
    }

    // 3. ¡AÑADIMOS EL COMENTARIO A LA "BASE DE DATOS FALSA"!
    _comentariosFalsosDB[lugarId]!.insert(0, nuevoComentario);

    print('Comentario para $lugarId AÑADIDO a la BD Falsa.');
    print('----------------------------------');
  }

  // (ORDEN 6 se mantiene)
  @override
  Future<void> marcarFavorito(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('Favorito toggle para lugar ID: $lugarId');
  }

  // --- ORDEN 7: "Traer los comentarios de un lugar" (¡ACOMPLADO!) ---
  @override
  Future<List<Comentario>> obtenerComentarios(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // Ahora lee de la "Base de Datos Falsa" (RAM)
    return _comentariosFalsosDB[lugarId] ?? []; // Devuelve la lista o una lista vacía
  }
}
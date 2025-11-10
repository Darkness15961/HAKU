// --- PIEDRA 3 (INICIO): LA "COCINA FALSA" (VERSIÓN CORREGIDA) ---
//
// 1. Incluye la lista maestra _allLugaresDB con TODAS las coordenadas.
// 2. Implementa el método CRÍTICO 'obtenerTodosLosLugares' (la lista maestra).
// 3. ¡CORREGIDO! Los strings de 'categoria' ahora coinciden
//    con la lista de Categorías ('Naturaleza', 'Cultural').

import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/categoria.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/comentario.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/repositorios/lugares_repositorio.dart';


// --- Base de Datos Falsa MAESTRA de Lugares (Con Coordenadas) ---
final List<Lugar> _allLugaresDB = [
  // L1: Cusco (Popular)
  Lugar(
    id: 'l1',
    nombre: 'Machu Picchu',
    descripcion: 'Antigua ciudad inca en las alturas de los Andes. Maravilla del mundo.',
    urlImagen: 'https://placehold.co/1000x600/0D47A1/FFFFFF?text=Machu+Picchu',
    rating: 4.9,
    categoria: 'Arqueología', // Coincide con el chip
    reviewsCount: 1500,
    horario: '6:00 - 17:00',
    costoEntrada: 'S/ 152.00',
    puntosInteres: ['Intihuatana', 'Templo del Sol', 'Huayna Picchu'],
    latitud: -13.1631,
    longitud: -72.5450,
    provinciaId: 'p2', // Urubamba (Corregido para ser preciso)
  ),
  // L2: Cusco (Popular y Favorito, para pruebas)
  Lugar(
    id: 'l2',
    nombre: 'Sacsayhuamán',
    descripcion: 'Impresionante fortaleza ceremonial inca con bloques ciclópeos.',
    urlImagen: 'https://placehold.co/1000x600/FF5722/FFFFFF?text=SXY',
    rating: 4.7,
    categoria: 'Arqueología', // Coincide con el chip
    reviewsCount: 800,
    horario: '7:00 - 18:00',
    costoEntrada: 'S/ 70.00',
    puntosInteres: ['Torreones', 'Rodadero'],
    latitud: -13.5076,
    longitud: -71.9839,
    provinciaId: 'p1', // Cusco
  ),
  // L3: Urubamba (Ruta 1 y 2)
  Lugar(
    id: 'l3',
    nombre: 'Salineras de Maras',
    descripcion: 'Pozos de sal preincas que crean un paisaje espectacular.',
    urlImagen: 'https://placehold.co/1000x600/4CAF50/FFFFFF?text=SLS',
    rating: 4.6,
    // --- ¡CORREGIDO! ---
    categoria: 'Naturaleza', // Antes 'Natural'
    reviewsCount: 400,
    horario: '9:00 - 17:00',
    costoEntrada: 'S/ 10.00',
    puntosInteres: ['Mirador', 'Pozos'],
    latitud: -13.3039,
    longitud: -72.1557,
    provinciaId: 'p2', // Urubamba
  ),
  // L4: Urubamba (Ruta 2)
  Lugar(
    id: 'l4',
    nombre: 'Mercado de Chinchero',
    descripcion: 'Famoso mercado de artesanías y textiles de la zona andina.',
    urlImagen: 'https://placehold.co/1000x600/795548/FFFFFF?text=CHINCHERO',
    rating: 4.5,
    // --- ¡CORREGIDO! ---
    categoria: 'Cultural', // Antes 'Cultura'
    reviewsCount: 250,
    horario: 'Domingos',
    costoEntrada: 'Gratuito',
    puntosInteres: ['Textiles', 'Plaza'],
    latitud: -13.4357,
    longitud: -72.0460,
    provinciaId: 'p2', // Urubamba
  ),
  // L5: Quispicanchi (Ruta 3)
  Lugar(
    id: 'l5',
    nombre: 'Montaña de 7 Colores',
    descripcion: 'La majestuosa montaña Vinicunca.',
    urlImagen: 'https://placehold.co/1000x600/A52A2A/FFFFFF?text=VIN',
    rating: 4.8,
    // --- ¡CORREGIDO! ---
    categoria: 'Naturaleza', // Antes 'Natural'
    reviewsCount: 1000,
    horario: '5:00 - 15:00',
    costoEntrada: 'S/ 20.00',
    puntosInteres: ['Mirador'],
    latitud: -13.8722,
    longitud: -71.2985,
    provinciaId: 'p4', // Quispicanchi
  ),
  // L6: Cusco (Ruta 1)
  Lugar(
    id: 'l6',
    nombre: 'Plaza de Armas',
    descripcion: 'Centro neurálgico de Cusco, con catedrales y arquitectura colonial.',
    urlImagen: 'https://placehold.co/1000x600/1E88E5/FFFFFF?text=PLAZA',
    rating: 4.8,
    // --- ¡CORREGIDO! ---
    categoria: 'Cultural', // Antes 'Cultura'
    reviewsCount: 1200,
    horario: 'Todo el día',
    costoEntrada: 'Gratuito',
    puntosInteres: ['Catedral', 'Piletas'],
    latitud: -13.5167,
    longitud: -71.9785,
    provinciaId: 'p1', // Cusco
  ),
];

// --- Base de Datos Falsa de Provincias ---
final List<Provincia> _provinciasDB = [
  Provincia(
    id: 'p1',
    nombre: 'Cusco',
    urlImagen: 'https://placehold.co/300x200/F06292/FFFFFF?text=Cusco',
    categories: ['Arqueología', 'Cultural'],
    placesCount: 2,
  ),
  Provincia(
    id: 'p2',
    nombre: 'Urubamba',
    urlImagen: 'https://placehold.co/300x200/7CB342/FFFFFF?text=Urubamba',
    categories: ['Naturaleza', 'Aventura', 'Cultural'], // Añadido Cultural
    placesCount: 3,
  ),
  Provincia(
    id: 'p4',
    nombre: 'Quispicanchi',
    urlImagen:
    'https://placehold.co/300x200/283593/FFFFFF?text=Quispicanchi',
    placesCount: 1,
    categories: ['Naturaleza'],
  ),
];

// --- Implementación del Repositorio (La "Cocina") ---
class LugaresRepositorioMock implements LugaresRepositorio {

  @override
  Future<List<Lugar>> obtenerLugaresPopulares() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Devuelve una sub-lista de populares (para el carrusel)
    return _allLugaresDB.where((l) => ['l1', 'l2', 'l5'].contains(l.id)).toList();
  }

  // --- ¡MÉTODO CRÍTICO IMPLEMENTADO! ---
  // Este método es requerido por el nuevo contrato y lo usa LugaresVM
  @override
  Future<List<Lugar>> obtenerTodosLosLugares() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Devuelve la lista MAESTRA completa
    return _allLugaresDB;
  }
  // --- FIN DE MÉTODO CRÍTICO ---

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

  // Este método es parte del contrato y lo implementamos (aunque LugaresVM ya no lo use directamente)
  @override
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _allLugaresDB.where((l) => l.provinciaId == provinciaId).toList();
  }

  // --- ÓRDENES PARA DETALLE ---

  @override
  Future<List<Comentario>> obtenerComentarios(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return [
      Comentario(
        id: 'c1',
        texto: '¡Un lugar absolutamente increíble! La energía es única.',
        rating: 5.0,
        fecha: 'hace 2 días',
        usuarioNombre: 'Alex Gálvez',
        usuarioFotoUrl:
        'https://placehold.co/100x100/333333/FFFFFF?text=AG',
      ),
      Comentario(
        id: 'c2',
        texto:
        'Recomiendo ir muy temprano para evitar las multitudes. Llev... ',
        rating: 4.0,
        fecha: 'hace 1 semana',
        usuarioNombre: 'Maria Fernanda',
        usuarioFotoUrl:
        'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
      ),
    ];
  }

  @override
  Future<void> enviarComentario(
      String lugarId, String texto, double rating) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('Comentario para $lugarId: $texto ($rating estrellas)');
  }

  @override
  Future<void> marcarFavorito(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('Favorito toggle para lugar ID: $lugarId');
  }
}
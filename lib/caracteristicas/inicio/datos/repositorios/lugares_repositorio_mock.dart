// --- lib/caracteristicas/inicio/datos/repositorios/lugares_repositorio_mock.dart ---
// (Esta es la "Cocina Falsa" que simula la base de datos)

import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/categoria.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/comentario.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/repositorios/lugares_repositorio.dart';


// --- Base de Datos Falsa MAESTRA de Lugares (Map) ---
final Map<String, Lugar> _allLugaresDB = {
  // (Tu DB de Lugares intacta...)
  'l1': Lugar( id: 'l1', nombre: 'Machu Picchu', descripcion: 'Antigua ciudadela inca...', urlImagen: 'https://images.unsplash.com/photo-1587595431973-160d0d94add1?ixlib=rb-4.0.3&w=1200', rating: 4.9, categoria: 'Arqueología', reviewsCount: 1500, horario: '6:00 - 17:00', costoEntrada: 'S/ 152.00', puntosInteres: ['Intihuatana', 'Templo del Sol', 'Huayna Picchu'], latitud: -13.1631, longitud: -72.5450, provinciaId: 'p2'),
  'l2': Lugar( id: 'l2', nombre: 'Sacsayhuamán', descripcion: 'Impresionante fortaleza...', urlImagen: 'https://i.ibb.co/1JjZNdCZ/Sacsayhuaman-1024x770-jpg.webp', rating: 4.7, categoria: 'Arqueología', reviewsCount: 800, horario: '7:00 - 18:00', costoEntrada: 'S/ 70.00', puntosInteres: ['Torreones', 'Rodadero'], latitud: -13.5076, longitud: -71.9839, provinciaId: 'p1'),
  'l3': Lugar( id: 'l3', nombre: 'Salineras de Maras', descripcion: 'Pozos de sal preincas...', urlImagen: 'https://i.ibb.co/1t0CKbJZ/SALINERAS-DE-MARAS.jpg', rating: 4.6, categoria: 'Naturaleza', reviewsCount: 400, horario: '9:00 - 17:00', costoEntrada: 'S/ 10.00', puntosInteres: ['Mirador', 'Pozos'], latitud: -13.3039, longitud: -72.1557, provinciaId: 'p2'),
  'l4': Lugar( id: 'l4', nombre: 'Mercado de Chinchero', descripcion: 'Famoso mercado de artesanías...', urlImagen: 'https://i.ibb.co/v4YFMGP0/17-standard.jpg', rating: 4.5, categoria: 'Cultural', reviewsCount: 250, horario: 'Domingos', costoEntrada: 'Gratuito', puntosInteres: ['Textiles', 'Plaza'], latitud: -13.4357, longitud: -72.0460, provinciaId: 'p2'),
  'l5': Lugar( id: 'l5', nombre: 'Montaña de Siete Colores', descripcion: 'La majestuosa montaña Vinicunca.', urlImagen: 'https://i.ibb.co/3YrYJfhr/monta-a.jpg', rating: 4.8, categoria: 'Naturaleza', reviewsCount: 1000, horario: '5:00 - 15:00', costoEntrada: 'S/ 20.00', puntosInteres: ['Mirador'], latitud: -13.8722, longitud: -71.2985, provinciaId: 'p4'),
  'l6': Lugar( id: 'l6', nombre: 'Plaza de Armas', descripcion: 'Centro neurálgico de Cusco...', urlImagen: 'https://i.ibb.co/9HgfbrBJ/plaza-armas-cusco.jpg', rating: 4.8, categoria: 'Cultural', reviewsCount: 1200, horario: 'Todo el día', costoEntrada: 'Gratuito', puntosInteres: ['Catedral', 'Piletas'], latitud: -13.5167, longitud: -71.9785, provinciaId: 'p1'),
};

// --- Base de Datos Falsa de Provincias (Mutable) ---
final List<Provincia> _provinciasDB = [
  Provincia( id: 'p1', nombre: 'Cusco', urlImagen: 'https://i.ibb.co/sdyxLDJh/tg-cusco-top-mobile.webp', categories: ['Arqueología', 'Cultural'], placesCount: 2),
  Provincia( id: 'p2', nombre: 'Urubamba', urlImagen: 'https://i.ibb.co/3yssCRM0/what-to-do-in-urubamba-10-tourist-places-that-you-must-visit-223.jpg', categories: ['Naturaleza', 'Aventura', 'Cultural'], placesCount: 3),
  Provincia( id: 'p4', nombre: 'Quispicanchi', urlImagen: 'https://i.ibb.co/twjKm1g2/i-andahuaylillas.jpg', placesCount: 1, categories: ['Naturaleza']),
];

// --- Base de Datos Falsa de Comentarios (Intacta) ---
final Map<String, List<Comentario>> _comentariosFalsosDB = {
  'l1': [
    Comentario( id: 'c1', texto: '¡Un lugar absolutamente increíble! La energía es única.', rating: 5.0, fecha: 'hace 2 días', lugarId: 'l1', usuarioId: '1', usuarioNombre: 'Alex Gálvez', usuarioFotoUrl: 'https://placehold.co/100x100/333333/FFFFFF?text=AG'),
    Comentario( id: 'c2', texto: 'Recomiendo ir muy temprano para evitar las multitudes. Llev... ', rating: 4.0, fecha: 'hace 1 semana', lugarId: 'l1', usuarioId: '2', usuarioNombre: 'Maria Fernanda', usuarioFotoUrl: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF'),
  ],
};


// --- Implementación del Repositorio (La "Cocina") ---
class LugaresRepositorioMock implements LugaresRepositorio {

  // (Métodos de Lugares intactos...)
  @override
  Future<List<Lugar>> obtenerLugaresPopulares() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _allLugaresDB.values.where((l) => ['l1', 'l2', 'l5'].contains(l.id)).toList();
  }
  @override
  Future<List<Lugar>> obtenerTodosLosLugares() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _allLugaresDB.values.toList();
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
      Categoria( id: '2', nombre: 'Arqueología', urlImagen: 'https://placehold.co/100/A52A2A/FFFFFF?text=Icon'),
      Categoria( id: '3', nombre: 'Naturaleza', urlImagen: 'https://placehold.co/100/228B22/FFFFFF?text=Icon'),
      Categoria( id: '4', nombre: 'Aventura', urlImagen: 'https://placehold.co/100/FF4500/FFFFFF?text=Icon'),
      Categoria( id: '5', nombre: 'Gastronomía', urlImagen: 'https://placehold.co/100/FFD700/FFFFFF?text=Icon'),
      Categoria( id: '6', nombre: 'Cultural', urlImagen: 'https://placehold.co/100/800080/FFFFFF?text=Icon'),
    ];
  }

  @override
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _allLugaresDB.values.where((l) => l.provinciaId == provinciaId).toList();
  }

  // (Métodos de Comentarios intactos...)
  @override
  Future<void> enviarComentario( String lugarId, String texto, double rating, String usuarioNombre, String? urlFotoUsuario, String usuarioId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final nuevoComentario = Comentario( id: 'c_${DateTime.now().millisecondsSinceEpoch}', texto: texto, rating: rating, fecha: 'justo ahora', lugarId: lugarId, usuarioId: usuarioId, usuarioNombre: usuarioNombre, usuarioFotoUrl: urlFotoUsuario ?? 'https://placehold.co/100x100/808080/FFFFFF?text=${usuarioNombre.substring(0,1)}');
    if (!_comentariosFalsosDB.containsKey(lugarId)) {
      _comentariosFalsosDB[lugarId] = [];
    }
    _comentariosFalsosDB[lugarId]!.insert(0, nuevoComentario);
  }

  @override
  Future<void> marcarFavorito(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('Favorito toggle para lugar ID: $lugarId');
  }

  @override
  Future<List<Comentario>> obtenerComentarios(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return _comentariosFalsosDB[lugarId] ?? [];
  }


  // --- (Métodos de Gestión de Lugares) ---

  // ¡CAMBIO AQUÍ! (Devuelve Future<Lugar> y añade "return nuevoLugar")
  @override
  Future<Lugar> crearLugar(Map<String, dynamic> datosLugar) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final nuevoId = 'lugar_${DateTime.now().millisecondsSinceEpoch}';
    final nuevoLugar = Lugar(
      id: nuevoId,
      nombre: datosLugar['nombre'],
      descripcion: datosLugar['descripcion'],
      urlImagen: datosLugar['urlImagen'] ?? 'https://picsum.photos/seed/$nuevoId/1000/600',
      rating: 0.0,
      categoria: datosLugar['categoriaNombre'],
      reviewsCount: 0,
      horario: datosLugar['horario'] ?? 'No especificado',
      costoEntrada: datosLugar['costoEntrada'] ?? 'No especificado',
      puntosInteres: datosLugar['puntosInteres'] ?? [],
      latitud: datosLugar['latitud'] ?? -13.5167,
      longitud: datosLugar['longitud'] ?? -71.9785,
      provinciaId: datosLugar['provinciaId'],
    );
    _allLugaresDB[nuevoId] = nuevoLugar;
    return nuevoLugar; // <-- ¡AÑADIDO!
  }

  // ¡CAMBIO AQUÍ! (Devuelve Future<Lugar> y añade "return lugarActualizado")
  @override
  Future<Lugar> actualizarLugar(String lugarId, Map<String, dynamic> datosLugar) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_allLugaresDB.containsKey(lugarId)) {
      throw Exception('Lugar no encontrado para actualizar');
    }
    final lugarViejo = _allLugaresDB[lugarId]!;
    final lugarActualizado = Lugar(
      id: lugarId,
      nombre: datosLugar['nombre'] ?? lugarViejo.nombre,
      descripcion: datosLugar['descripcion'] ?? lugarViejo.descripcion,
      urlImagen: datosLugar['urlImagen'] ?? lugarViejo.urlImagen,
      rating: lugarViejo.rating,
      categoria: datosLugar['categoriaNombre'] ?? lugarViejo.categoria,
      reviewsCount: lugarViejo.reviewsCount,
      horario: datosLugar['horario'] ?? lugarViejo.horario,
      costoEntrada: datosLugar['costoEntrada'] ?? lugarViejo.costoEntrada,
      puntosInteres: datosLugar['puntosInteres'] ?? lugarViejo.puntosInteres,
      latitud: datosLugar['latitud'] ?? lugarViejo.latitud,
      longitud: datosLugar['longitud'] ?? lugarViejo.longitud,
      provinciaId: datosLugar['provinciaId'] ?? lugarViejo.provinciaId,
    );
    _allLugaresDB[lugarId] = lugarActualizado;
    return lugarActualizado; // <-- ¡AÑADIDO!
  }

  @override
  Future<void> eliminarLugar(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_allLugaresDB.containsKey(lugarId)) {
      _allLugaresDB.remove(lugarId);
    } else {
      throw Exception('Lugar no encontrado para eliminar');
    }
  }

  // --- (Gestión de Provincias intacto) ---

  @override
  Future<void> crearProvincia(Map<String, dynamic> datosProvincia) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final nuevoId = 'p_${DateTime.now().millisecondsSinceEpoch}';

    final nuevaProvincia = Provincia(
      id: nuevoId,
      nombre: datosProvincia['nombre'],
      urlImagen: datosProvincia['urlImagen'] ?? 'https://picsum.photos/seed/$nuevoId/800/600',
      categories: datosProvincia['categories'] ?? [], // Lista de Strings
      placesCount: 0, // Empieza con 0 lugares
    );

    _provinciasDB.add(nuevaProvincia);
    print('Mock: Provincia $nuevoId CREADA');
  }

  @override
  Future<void> actualizarProvincia(String provinciaId, Map<String, dynamic> datosProvincia) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _provinciasDB.indexWhere((p) => p.id == provinciaId);
    if (index == -1) {
      throw Exception('Provincia no encontrada para actualizar');
    }

    final provinciaVieja = _provinciasDB[index];

    final provinciaActualizada = Provincia(
      id: provinciaId,
      nombre: datosProvincia['nombre'] ?? provinciaVieja.nombre,
      urlImagen: datosProvincia['urlImagen'] ?? provinciaVieja.urlImagen,
      categories: datosProvincia['categories'] ?? provinciaVieja.categories,
      placesCount: provinciaVieja.placesCount, // El conteo no se edita aquí
    );

    _provinciasDB[index] = provinciaActualizada;
    print('Mock: Provincia $provinciaId ACTUALIZADA');
  }

  @override
  Future<void> eliminarProvincia(String provinciaId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Regla de negocio: No eliminar si hay lugares asociados
    final hayLugares = _allLugaresDB.values.any((l) => l.provinciaId == provinciaId);
    if (hayLugares) {
      throw Exception('Error: No se puede eliminar. Elimine primero los lugares asociados a esta provincia.');
    }

    _provinciasDB.removeWhere((p) => p.id == provinciaId);
    print('Mock: Provincia $provinciaId ELIMINADA');
  }
}
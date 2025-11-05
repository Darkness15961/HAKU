// --- PIEDRA 2: LA "COCINA FALSA" (VERSIÓN FINAL - ¡CON LAT/LNG!) ---
//
// Esta es la versión actualizada de nuestra "Cocina Falsa".
// Le hemos "enseñado" a "cocinar" los nuevos "ingredientes"
// de la "Receta" final de Lugar (latitud, longitud, etc.).

// 1. Importamos las "Recetas" (Entidades)
import '../../dominio/entidades/categoria.dart';
// ¡Importamos la "Receta" que acabamos de arreglar en el Canvas!
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/comentario.dart';

// 2. Importamos el "Enchufe" (Repositorio)
import '../../dominio/repositorios/lugares_repositorio.dart';

// 3. Creamos la "Cocina Falsa"
class LugaresRepositorioMock implements LugaresRepositorio {

  // --- "Base de Datos Falsa" de Lugares (¡AHORA CON COORDENADAS!) ---
  // (Usamos la "Receta" final de Lugar)
  final _lugaresFalsosDB = [
    Lugar(
      id: '1',
      nombre: 'Machu Picchu',
      urlImagen:
      'https://placehold.co/1000x600/0D47A1/FFFFFF?text=Machu+Picchu',
      rating: 4.9,
      descripcion:
      'Ciudadela inca en lo alto de los Andes, famosa por sus vistas y sofisticada ingeniería. Es un testimonio de la civilización inca y un destino imperdible en Perú.',
      categoria: 'Arqueología',
      reviewsCount: 3250,
      horario: '06:00 - 17:00',
      costoEntrada: 'S/ 152.00',
      puntosInteres: ['Templo del Sol', 'Intihuatana', 'Sala de las 3 Ventanas'],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.1631,
      longitud: -72.5450,
    ),
    Lugar(
      id: '2',
      nombre: 'Montaña 7 Colores',
      urlImagen:
      'https://placehold.co/1000x600/00897B/FFFFFF?text=7+Colores',
      rating: 4.8,
      descripcion:
      'Montaña Vinicunca, con franjas de colores naturales debido a los minerales. Requiere una caminata de aclimatación.',
      categoria: 'Naturaleza',
      reviewsCount: 1890,
      horario: '05:00 - 14:00 (Tour)',
      costoEntrada: 'S/ 10.00 (Entrada)',
      puntosInteres: ['Mirador Principal', 'Valle Rojo (cercano)'],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.8700,
      longitud: -71.3033,
    ),
    Lugar(
      id: '3',
      nombre: 'Ollantaytambo',
      urlImagen:
      'https://placehold.co/1000x600/00569A/FFFFFF?text=Ollantaytambo',
      rating: 4.7,
      descripcion:
      'Pueblo y sitio arqueológico inca, que sirvió como fortaleza y centro religioso. Sus terrazas son impresionantes.',
      categoria: 'Arqueología',
      reviewsCount: 2450,
      horario: '07:00 - 17:00',
      costoEntrada: 'S/ 70.00',
      puntosInteres: [
        'Templo del Sol',
        'Terraplenes',
        'Sector Militar',
        'Baño de la Ñusta'
      ],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.2592,
      longitud: -72.2625,
    ),
    Lugar(
      id: 'p1-1',
      nombre: 'Sacsayhuamán (Cusco)',
      urlImagen:
      'https://placehold.co/1000x600/0D47A1/FFFFFF?text=Sacsayhuaman',
      rating: 4.9,
      descripcion:
      'Impresionante fortaleza ceremonial inca con muros de piedra gigantescos. Ofrece una vista panorámica de la ciudad de Cusco.',
      categoria: 'Arqueología',
      reviewsCount: 2980,
      horario: '07:00 - 17:30',
      costoEntrada: 'S/ 70.00 (Boleto Turístico)',
      puntosInteres: ['Los Baluartes', 'Suchuna', 'El Trono del Inca'],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.5085,
      longitud: -71.9812,
    ),
    Lugar(
      id: 'p1-2',
      nombre: 'Qorikancha (Cusco)',
      urlImagen:
      'https://placehold.co/1000x600/DAA520/FFFFFF?text=Qorikancha',
      rating: 4.8,
      descripcion:
      'El "Templo del Sol", fue el centro religioso más importante del imperio inca. Hoy es la base del Convento de Santo Domingo.',
      categoria: 'Arqueología',
      reviewsCount: 2130,
      horario: '08:30 - 17:30',
      costoEntrada: 'S/ 15.00',
      puntosInteres: ['Templo del Sol', 'Jardín Dorado', 'Convento'],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.5200,
      longitud: -71.9756,
    ),
    Lugar(
      id: 'p2-1',
      nombre: 'Moray (Urubamba)',
      urlImagen: 'https://placehold.co/1000x600/006400/FFFFFF?text=Moray',
      rating: 4.6,
      descripcion:
      'Terrazas agrícolas circulares que sirvieron como un laboratorio botánico inca para experimentar con diferentes climas.',
      categoria: 'Naturaleza',
      reviewsCount: 1540,
      horario: '07:00 - 17:00',
      costoEntrada: 'S/ 70.00 (Boleto Turístico)',
      puntosInteres: ['Andenes Circulares', 'Mirador'],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.2897,
      longitud: -72.1483,
    ),
    Lugar(
      id: 'p3-1',
      nombre: 'Pisac (Calca)',
      urlImagen: 'https://placehold.co/1000x600/8B4513/FFFFFF?text=Pisac',
      rating: 4.7,
      descripcion:
      'Famoso por su mercado artesanal y su impresionante complejo arqueológico en la montaña, con andenes y templos.',
      categoria: 'Arqueología',
      reviewsCount: 1980,
      horario: '08:00 - 17:00',
      costoEntrada: 'S/ 70.00 (Boleto Turístico)',
      puntosInteres: ['Mercado Artesanal', 'Ruinas de Pisac', 'Intihuatana'],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.4253,
      longitud: -71.8480,
    ),
    Lugar(
      id: 'p4-1',
      nombre: 'Tipón (Quispicanchi)',
      urlImagen: 'https://placehold.co/1000x600/008080/FFFFFF?text=Tipon',
      rating: 4.6,
      descripcion:
      'Una joya de la ingeniería hidráulica inca, con terrazas impecables y sistemas de canales de agua que aún funcionan.',
      categoria: 'Arqueología',
      reviewsCount: 950,
      horario: '07:00 - 17:00',
      costoEntrada: 'S/ 70.00 (Boleto Turístico)',
      puntosInteres: ['Canales de Agua', 'Andenes', 'Mirador'],
      // --- ¡ARREGLO! (Datos de tu MER) ---
      latitud: -13.6186,
      longitud: -71.7836,
    ),
  ];

  // --- ORDEN 1: Obtener Lugares Populares ---
  @override
  Future<List<Lugar>> obtenerLugaresPopulares() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Devuelve los 3 primeros de nuestra "base de datos falsa"
    return _lugaresFalsosDB.take(3).toList();
  }

  // --- ORDEN 2: Obtener Provincias ---
  @override
  Future<List<Provincia>> obtenerProvincias() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Provincia(
        id: 'p1',
        nombre: 'Cusco',
        urlImagen: 'https://placehold.co/800x600/0D47A1/FFFFFF?text=Cusco',
        placesCount: 124,
        categories: ['Arqueología', 'Cultural'],
      ),
      Provincia(
        id: 'p2',
        nombre: 'Urubamba',
        urlImagen: 'https://placehold.co/800x600/00897B/FFFFFF?text=Urubamba',
        placesCount: 78,
        categories: ['Naturaleza', 'Aventura'],
      ),
      Provincia(
        id: 'p3',
        nombre: 'Calca',
        urlImagen: 'https://placehold.co/800x600/1976D2/FFFFFF?text=Calca',
        placesCount: 34,
        categories: ['Gastronomía', 'Naturaleza'],
      ),
      Provincia(
        id: 'p4',
        nombre: 'Quispicanchi',
        urlImagen:
        'https://placehold.co/800x600/283593/FFFFFF?text=Quispicanchi',
        placesCount: 21,
        categories: ['Naturaleza'],
      ),
    ];
  }

  // --- ORDEN 3: Obtener Categorías ---
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

  // --- ORDEN 4: Obtener Lugares por Provincia ---
  @override
  Future<List<Lugar>> obtenerLugaresPorProvincia(String provinciaId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Lógica falsa: Filtramos nuestra "base de datos falsa"
    if (provinciaId == 'p1') { // Cusco
      return _lugaresFalsosDB.where((l) => l.id == 'p1-1' || l.id == 'p1-2').toList();
    }
    if (provinciaId == 'p2') { // Urubamba
      return _lugaresFalsosDB.where((l) => l.id == '3' || l.id == 'p2-1').toList();
    }
    if (provinciaId == 'p3') { // Calca
      return _lugaresFalsosDB.where((l) => l.id == 'p3-1').toList();
    }
    if (provinciaId == 'p4') { // Quispicanchi
      return _lugaresFalsosDB.where((l) => l.id == 'p4-1').toList();
    }
    // Por defecto
    return [ _lugaresFalsosDB[0] ];
  }

  // --- ÓRDENES PARA DETALLE ---

  // ORDEN 5: "Enviar un nuevo comentario"
  @override
  Future<void> enviarComentario(
      String lugarId, String texto, double rating) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('Comentario para $lugarId: $texto ($rating estrellas)');
  }

  // ORDEN 6: "Marcar/Desmarcar como favorito"
  @override
  Future<void> marcarFavorito(String lugarId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('Favorito toggle para lugar ID: $lugarId');
  }

  // ORDEN 7: "Traer los comentarios de un lugar"
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
        'Recomiendo ir muy temprano para evitar las multitudes. Lleven agua y un buen guía.',
        rating: 4.0,
        fecha: 'hace 1 semana',
        usuarioNombre: 'Maria Fernanda',
        usuarioFotoUrl:
        'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
      ),
    ];
  }
}
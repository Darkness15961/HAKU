// --- PIEDRA 3 (RUTAS): LA "COCINA FALSA" (MOCK) ---
//
// Esta es la "Cocina Falsa" para las Rutas.
// "Finge" ser el backend de Laravel y "cocina"
// "Rutas Falsas" para que podamos simular
// las 3 pestañas (Recomendadas, Guardadas, Creadas).

// 1. Importamos la "Receta" (Entidad) que va a "cocinar"
import '../../dominio/entidades/ruta.dart';

// 2. Importamos el "Enchufe" (Repositorio) al que se va a conectar
//    (Este "Enchufe" es el que está en el Canvas)
import '../../dominio/repositorios/rutas_repositorio.dart';

// 3. Creamos la "Cocina Falsa"
// "implements RutasRepositorio" significa:
// "Prometo que me conectaré al 'Enchufe' (el del Canvas)
// y 'cocinaré' todas las 'órdenes' que define".
class RutasRepositorioMock implements RutasRepositorio {
  // --- Simulación de "Base de Datos Falsa" de Rutas ---
  //
  // Creamos una lista de "Rutas Falsas" que usaremos para
  // simular las diferentes pestañas.
  // Usamos la "Receta" (ruta.dart) que ya creamos.

  final List<Ruta> _rutasFalsasDB = [
    // Ruta 1 (Recomendada, No Favorita, No Inscrito)
    Ruta(
      id: 'r1',
      nombre: 'Aventura en el Valle Sagrado (1 Día)',
      descripcion: 'Disfruta de la experiencia completa del Valle Sagrado...',
      urlImagenPrincipal:
      'https://placehold.co/1000x600/0D47A1/FFFFFF?text=Valle+Sagrado',
      precio: 80.00,
      dificultad: 'facil',
      cupos: 30,
      visible: true,
      guiaId: 'g1',
      guiaNombre: 'Alejandro Quispe',
      guiaFotoUrl: 'https://placehold.co/100x100/333333/FFFFFF?text=AQ',
      rating: 4.8,
      reviewsCount: 120,
      lugaresIncluidos: ['Pisac', 'Ollantaytambo', 'Chinchero'],
      inscritosCount: 12,
      esFavorita: false, // El usuario actual NO la ha guardado
      estaInscrito: false, // El usuario actual NO está inscrito
    ),
    // Ruta 2 (Recomendada, Favorita, Inscrito)
    Ruta(
      id: 'r2',
      nombre: 'Trekking Salkantay (5 Días)',
      descripcion: 'Una ruta alternativa increíble a Machu Picchu...',
      urlImagenPrincipal:
      'https://placehold.co/1000x600/00897B/FFFFFF?text=Salkantay',
      precio: 900.00,
      dificultad: 'dificil',
      cupos: 40,
      visible: true,
      guiaId: 'g2',
      guiaNombre: 'Maria Fernanda',
      guiaFotoUrl: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
      rating: 4.9,
      reviewsCount: 350,
      lugaresIncluidos: ['Mollepata', 'Salkantay', 'Aguas Calientes'],
      inscritosCount: 20,
      esFavorita: true, // El usuario actual SÍ la guardó
      estaInscrito: true, // El usuario actual SÍ está inscrito
    ),
    // Ruta 3 (Creada por el Guía, Borrador)
    Ruta(
      id: 'r3',
      nombre: 'Explorando la Montaña de 7 Colores',
      descripcion: 'Un tour de día completo a Vinicunca...',
      urlImagenPrincipal:
      'https://placehold.co/1000x600/8B4513/FFFFFF?text=Vinicunca',
      precio: 60.00,
      dificultad: 'medio',
      cupos: 25,
      visible: false, // "false" = Borrador (no es pública)
      guiaId: 'g_usuario_actual', // ID del Guía (nuestro usuario)
      guiaNombre: 'Mi Propia Ruta (Guía)',
      guiaFotoUrl: 'https://placehold.co/100x100/AAAAAA/FFFFFF?text=YO',
      rating: 0.0,
      reviewsCount: 0,
      lugaresIncluidos: ['Vinicunca'],
      inscritosCount: 0,
      esFavorita: false,
      estaInscrito: false,
    ),
  ];

  // --- ORDEN 1: "Traer la lista de rutas" ---
  @override
  Future<List<Ruta>> obtenerRutas(String tipoFiltro) async {
    // 1. Simulamos un retraso de red
    await Future.delayed(const Duration(milliseconds: 900));

    // 2. Lógica de simulación (basada en tu diseño)
    switch (tipoFiltro) {
      case 'guardadas':
      // Devuelve solo las rutas donde "esFavorita" es true
        return _rutasFalsasDB.where((ruta) => ruta.esFavorita).toList();
      case 'creadas_por_mi':
      // Devuelve solo las rutas creadas por el guía (ID simulado)
        return _rutasFalsasDB
            .where((ruta) => ruta.guiaId == 'g_usuario_actual')
            .toList();
      case 'recomendadas':
      default:
      // Devuelve todas las rutas que son "visibles" (públicas)
        return _rutasFalsasDB.where((ruta) => ruta.visible).toList();
    }
  }

  // --- ORDEN 2: "Inscribirse a una ruta" ---
  @override
  Future<void> inscribirseEnRuta(String rutaId) async {
    // 1. Simulamos un retraso de red
    await Future.delayed(const Duration(milliseconds: 500));
    // 2. Imprimimos en consola para ver que funcionó
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('El usuario se ha INSCRITO en la ruta ID: $rutaId');
    print('----------------------------------');
  }

  // --- ORDEN 3: "Salir de una ruta" ---
  @override
  Future<void> salirDeRuta(String rutaId) async {
    // 1. Simulamos un retraso
    await Future.delayed(const Duration(milliseconds: 300));
    // 2. Imprimimos en consola
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('El usuario ha SALIDO de la ruta ID: $rutaId');
    print('----------------------------------');
  }

  // --- ORDEN 4: "Marcar/Desmarcar como favorita" ---
  @override
  Future<void> toggleFavoritoRuta(String rutaId) async {
    // 1. Simulamos un retraso
    await Future.delayed(const Duration(milliseconds: 200));
    // 2. Imprimimos en consola
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('El usuario ha marcado/desmarcado como FAVORITA la ruta ID: $rutaId');
    print('----------------------------------');
  }

  // --- ORDEN 5: "Crear una nueva ruta" ---
  @override
  Future<void> crearRuta(Map<String, dynamic> datosRuta) async {
    // 1. Simulamos un retraso
    await Future.delayed(const Duration(milliseconds: 1200));
    // 2. Imprimimos en consola los datos que recibimos
    //    del formulario (para ver que funciona)
    print('--- ¡ORDEN RECIBIDA POR EL MOCK! ---');
    print('El Guía está creando una nueva ruta con estos datos:');
    print(datosRuta);
    print('----------------------------------');
  }
}

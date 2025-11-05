// --- PIEDRA 4: EL "MESERO" (ACTUALIZADO) ---
//
// Esta es la versión actualizada del "Mesero".
// Le hemos "enseñado" a manejar las "órdenes"
// para la página de detalle (comentarios, favoritos, etc.).

import 'package:flutter/material.dart';

// Importamos el "Enchufe" (El Contrato/Repositorio)
import '../../dominio/repositorios/lugares_repositorio.dart';

// Importamos las "Recetas" (Entidades)
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';
// --- ¡NUEVA IMPORTACIÓN! ---
// Importamos la "Receta" de Comentario
import '../../dominio/entidades/comentario.dart';

// Importamos el "Conector" (GetIt)
import '../../../../locator.dart';

class LugaresVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS (Lo que necesita el "Mesero") ---
  late final LugaresRepositorio _repositorio;

  // --- B. ESTADO DE LA UI (INICIO_PAGINA) ---
  bool _estaCargandoInicio = true;
  List<Lugar> _lugaresPopulares = [];
  List<Provincia> _provincias = [];
  List<Categoria> _categorias = [];
  String _terminoBusquedaInicio = '';
  String _categoriaSeleccionadaIdInicio = '1';
  int _carouselIndex = 0;

  // --- C. GETTERS (INICIO_PAGINA) ---
  bool get estaCargandoInicio => _estaCargandoInicio;
  List<Lugar> get lugaresPopulares => _lugaresPopulares;
  List<Categoria> get categorias => _categorias;
  String get categoriaSeleccionadaIdInicio => _categoriaSeleccionadaIdInicio;
  int get carouselIndex => _carouselIndex;

  List<Provincia> get provinciasFiltradas {
    List<Provincia> provinciasFiltradas = _provincias;

    if (_categoriaSeleccionadaIdInicio != '1') {
      final categoria =
      _categorias.firstWhere((c) => c.id == _categoriaSeleccionadaIdInicio);
      provinciasFiltradas = provinciasFiltradas.where((provincia) {
        return provincia.categories.contains(categoria.nombre);
      }).toList();
    }
    if (_terminoBusquedaInicio.isNotEmpty) {
      provinciasFiltradas = provinciasFiltradas.where((provincia) {
        return provincia.nombre
            .toLowerCase()
            .contains(_terminoBusquedaInicio.toLowerCase());
      }).toList();
    }
    return provinciasFiltradas;
  }

  // --- D. ESTADO DE LA UI (PROVINCIA_LUGARES_PAGINA) ---
  bool _estaCargandoLugaresDeProvincia = true;
  List<Lugar> _lugaresDeProvincia = [];
  String _terminoBusquedaProvincia = '';
  String _categoriaSeleccionadaIdProvincia = '1';

  // --- E. GETTERS (PROVINCIA_LUGARES_PAGINA) ---
  bool get estaCargandoLugaresDeProvincia => _estaCargandoLugaresDeProvincia;
  String get categoriaSeleccionadaIdProvincia =>
      _categoriaSeleccionadaIdProvincia;

  List<Lugar> get lugaresFiltradosDeProvincia {
    List<Lugar> lugaresFiltrados = _lugaresDeProvincia;

    if (_categoriaSeleccionadaIdProvincia != '1') {
      final categoria =
      _categorias.firstWhere((c) => c.id == _categoriaSeleccionadaIdProvincia);
      lugaresFiltrados = lugaresFiltrados.where((lugar) {
        return lugar.categoria == categoria.nombre;
      }).toList();
    }
    if (_terminoBusquedaProvincia.isNotEmpty) {
      lugaresFiltrados = lugaresFiltrados.where((lugar) {
        final busqueda = _terminoBusquedaProvincia.toLowerCase();
        return lugar.nombre.toLowerCase().contains(busqueda) ||
            lugar.descripcion.toLowerCase().contains(busqueda);
      }).toList();
    }
    return lugaresFiltrados;
  }

  // --- ¡NUEVO! F. ESTADO DE LA UI (DETALLE_LUGAR_PAGINA) ---
  //
  // Añadimos un nuevo conjunto de variables de estado
  // solo para la página de detalle del lugar.

  // "Interruptor" de carga para los comentarios
  bool _estaCargandoComentarios = true;
  // Lista para guardar los comentarios
  List<Comentario> _comentarios = [];

  // --- ¡NUEVO! G. GETTERS (DETALLE_LUGAR_PAGINA) ---
  bool get estaCargandoComentarios => _estaCargandoComentarios;
  List<Comentario> get comentarios => _comentarios;

  // (Nota: El estado de "favorito" lo manejaremos
  // más adelante con el "Mesero de Seguridad",
  // como hablamos)

  // --- H. CONSTRUCTOR (Cuando el "Mesero" empieza su turno) ---
  LugaresVM() {
    // 3. (En secreto, "getIt" le da la "Cocina Falsa" (Mock)
    //    porque así lo configuramos en locator.dart)
    _repositorio = getIt<LugaresRepositorio>();

    // 4. Apenas empieza el turno, el "Mesero" va a la cocina
    //    a pedir todos los platos iniciales.
    cargarDatosIniciales();
  }

  // --- I. MÉTODOS (Órdenes para INICIO_PAGINA) ---

  Future<void> cargarDatosIniciales() async {
    _estaCargandoInicio = true;
    notifyListeners();

    // Pedimos las 3 "órdenes" al mismo tiempo
    final resultados = await Future.wait([
      _repositorio.obtenerLugaresPopulares(),
      _repositorio.obtenerProvincias(),
      _repositorio.obtenerCategorias(),
    ]);

    // Guardamos los "platos"
    _lugaresPopulares = resultados[0] as List<Lugar>;
    _provincias = resultados[1] as List<Provincia>;
    _categorias = resultados[2] as List<Categoria>;

    _estaCargandoInicio = false;
    notifyListeners();
  }

  void buscarEnInicio(String termino) {
    _terminoBusquedaInicio = termino;
    notifyListeners();
  }

  void seleccionarCategoriaEnInicio(String categoriaId) {
    _categoriaSeleccionadaIdInicio = categoriaId;
    notifyListeners();
  }

  void setCarouselIndex(int index) {
    _carouselIndex = index;
    notifyListeners();
  }

  // --- J. MÉTODOS (Órdenes para PROVINCIA_LUGARES_PAGINA) ---

  Future<void> cargarLugaresPorProvincia(String provinciaId) async {
    _estaCargandoLugaresDeProvincia = true;
    _terminoBusquedaProvincia = '';
    _categoriaSeleccionadaIdProvincia = '1';
    notifyListeners();

    _lugaresDeProvincia =
    await _repositorio.obtenerLugaresPorProvincia(provinciaId);

    _estaCargandoLugaresDeProvincia = false;
    notifyListeners();
  }

  void buscarEnProvincia(String termino) {
    _terminoBusquedaProvincia = termino;
    notifyListeners();
  }

  void seleccionarCategoriaEnProvincia(String categoriaId) {
    _categoriaSeleccionadaIdProvincia = categoriaId;
    notifyListeners();
  }

  // --- ¡NUEVO! K. MÉTODOS (Órdenes para DETALLE_LUGAR_PAGINA) ---

  // ORDEN 7: "Traer los comentarios de este lugar"
  Future<void> cargarComentarios(String lugarId) async {
    // 1. Encendemos el "interruptor" de carga de comentarios
    _estaCargandoComentarios = true;
    // 2. "Avisamos" a la UI que muestre un spinner
    //    (pero solo actualizamos si la UI sigue "montada")
    notifyListeners();

    // 3. Pedimos la "orden" a la "Cocina" (Mock)
    _comentarios = await _repositorio.obtenerComentarios(lugarId);

    // 4. Apagamos el "interruptor"
    _estaCargandoComentarios = false;
    // 5. "Avisamos" a la UI que la "comida" (comentarios) está lista
    notifyListeners();
  }

  // ORDEN 5: "Enviar este nuevo comentario"
  Future<void> enviarComentario(
      String lugarId, String texto, double rating) async {
    // 1. (Opcional) Mostramos un indicador de carga
    //    (Por ahora, solo enviamos la orden)

    // 2. Le damos la "orden" a la "Cocina" (Mock)
    await _repositorio.enviarComentario(lugarId, texto, rating);

    // 3. (IMPORTANTE) Después de enviar, volvemos a cargar
    //    la lista de comentarios para que el nuevo aparezca
    //    instantáneamente (¡buena experiencia de usuario!)
    await cargarComentarios(lugarId);
  }

  // ORDEN 6: "Marcar este lugar como favorito"
  Future<void> marcarFavorito(String lugarId) async {
    // 1. Le damos la "orden" a la "Cocina" (Mock)
    await _repositorio.marcarFavorito(lugarId);

    // 2. (Opcional) "Avisamos" a la UI que el
    //    estado de favorito cambió (esto lo conectaremos
    //    con el "Mesero de Seguridad" más adelante)
    // notifyListeners();
  }
}


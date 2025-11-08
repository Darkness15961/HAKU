// --- PIEDRA 4: EL "MESERO" (ACTUALIZADO CON FUTURE Y GETTER DE PERFIL) ---
//
// 1. Se arregló el constructor (ya no carga datos).
// 2. 'cargarDatosIniciales(AuthVM)' AHORA DEVUELVE UN FUTURE<void>
//    para que el RefreshIndicator (en inicio_pagina) pueda "esperarlo".
// 3. Se añadió la lógica de Favoritos (conectada al AuthVM).
// 4. ¡CORREGIDO! Se añadió el getter 'cargaInicialRealizada'.

import 'dart:async'; // <-- ¡IMPORTANTE PARA EL COMPLETER!
import 'package:flutter/material.dart';

// Importamos el "Enchufe" (El Contrato/Repositorio)
import '../../dominio/repositorios/lugares_repositorio.dart';

// Importamos las "Recetas" (Entidades)
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';
import '../../dominio/entidades/comentario.dart';

// Importamos el "Conector" (GetIt)
import '../../../../locator.dart';

// --- ¡NUEVA IMPORTACIÓN! ---
// Importamos el "Cerebro" (AuthVM)
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class LugaresVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final LugaresRepositorio _repositorio;
  AutenticacionVM? _authVM; // <-- ¡NUEVO!

  // --- B. ESTADO DE LA UI (INICIO_PAGINA) ---
  bool _estaCargandoInicio = true;
  List<Lugar> _lugaresPopulares = [];
  List<Provincia> _provincias = [];
  List<Categoria> _categorias = [];
  String _terminoBusquedaInicio = '';
  String _categoriaSeleccionadaIdInicio = '1';
  int _carouselIndex = 0;
  bool _cargaInicialRealizada = false; // <-- ¡NUEVO!

  // --- C. GETTERS (INICIO_PAGINA) ---
  bool get estaCargandoInicio => _estaCargandoInicio;
  List<Lugar> get lugaresPopulares => _lugaresPopulares;
  List<Categoria> get categorias => _categorias;
  String get categoriaSeleccionadaIdInicio => _categoriaSeleccionadaIdInicio;
  int get carouselIndex => _carouselIndex;

  // --- ¡LÍNEA AÑADIDA QUE FALTABA! ---
  bool get cargaInicialRealizada => _cargaInicialRealizada;
  // --- FIN DE LÍNEA AÑADIDA ---

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

  // --- F. ESTADO DE LA UI (DETALLE_LUGAR_PAGINA) ---
  bool _estaCargandoComentarios = true;
  List<Comentario> _comentarios = [];

  // --- G. GETTERS (DETALLE_LUGAR_PAGINA) ---
  bool get estaCargandoComentarios => _estaCargandoComentarios;
  List<Comentario> get comentarios => _comentarios;

  // --- ¡NUEVO GETTER PARA EL PERFIL! (Paso 1 Acoplado) ---
  List<Lugar> get misLugaresFavoritos {
    // 1. Verificamos que el "Cerebro" (AuthVM) esté listo
    if (_authVM == null || !_authVM!.estaLogueado) return [];

    // 2. Obtenemos los IDs del "Cerebro"
    final ids = _authVM!.lugaresFavoritosIds;

    // 3. Filtramos la lista completa de lugares
    // (Usamos _lugaresPopulares, que es la lista principal que carga este VM)
    return _lugaresPopulares.where((l) => ids.contains(l.id)).toList();
  }
  // --- FIN DE NUEVO GETTER ---

  // --- H. CONSTRUCTOR (¡CORREGIDO!) ---
  LugaresVM() {
    _repositorio = getIt<LugaresRepositorio>();
    // ¡HEMOS QUITADO la llamada a cargarDatosIniciales() de aquí!
    // El constructor ahora está limpio.
  }

  // --- I. MÉTODOS DE INICIALIZACIÓN (¡CORREGIDOS CON FUTURE!) ---

  // --- ¡CORREGIDO! --- Ahora devuelve un Future<void>
  Future<void> cargarDatosIniciales(AutenticacionVM authVM) async {

    // Si es la primera vez que se llama (desde initState)
    // guardamos la referencia a AuthVM
    if (_authVM == null) {
      _authVM = authVM;
      _authVM?.addListener(_onAuthChanged);
    }

    // Si AuthVM sigue cargando, esperamos
    if (_authVM?.estaCargando ?? false) {
      _estaCargandoInicio = true; // Mostramos spinner
      notifyListeners();

      // Creamos un Completer para que el 'await' en la Vista espere
      final authCompleter = Completer<void>();

      // Creamos un listener temporal que se auto-elimina
      void onAuthReady() {
        _authVM?.removeListener(onAuthReady); // Se auto-elimina
        if (!authCompleter.isCompleted) {
          authCompleter.complete();
        }
      }

      _authVM?.addListener(onAuthReady);
      await authCompleter.future; // <-- El 'await' de la Vista espera aquí
    }

    // Si AuthVM ya está listo (Anónimo o logueado), cargamos
    // --- ¡CORREGIDO! --- Usamos 'await'
    await _cargarCatalogos(); // <-- El 'await' de la Vista espera aquí
  }

  // Cuando el usuario inicia o cierra sesión, notificamos
  // para que los corazones de "favorito" se redibujen.
  void _onAuthChanged() {
    notifyListeners();
  }

  // Este era tu antiguo "cargarDatosIniciales"
  Future<void> _cargarCatalogos() async {
    _estaCargandoInicio = true;

    // Notificamos solo si NO es la primera carga
    // (para evitar el error de 'setState' en 'build' de initState)
    if(_cargaInicialRealizada) {
      Future.microtask(() => notifyListeners());
    }

    try {
      final resultados = await Future.wait([
        _repositorio.obtenerLugaresPopulares(),
        _repositorio.obtenerProvincias(),
        _repositorio.obtenerCategorias(),
      ]);

      _lugaresPopulares = resultados[0] as List<Lugar>;
      _provincias = resultados[1] as List<Provincia>;
      _categorias = resultados[2] as List<Categoria>;

    } catch (e) {
      // Manejar error si es necesario
    } finally {
      _estaCargandoInicio = false;
      _cargaInicialRealizada = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authVM?.removeListener(_onAuthChanged);
    // (El listener _onAuthReady se auto-elimina)
    super.dispose();
  }

  // --- J. MÉTODOS (Órdenes para INICIO_PAGINA) ---
  // ... (buscarEnInicio, seleccionarCategoriaEnInicio, setCarouselIndex)
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

  // --- K. MÉTODOS (Órdenes para PROVINCIA_LUGARES_PAGINA) ---
  // ... (cargarLugaresPorProvincia, buscarEnProvincia, seleccionarCategoriaEnProvincia)
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

  // --- L. MÉTODOS (Órdenes para DETALLE_LUGAR_PAGINA) ---
  // ... (cargarComentarios, enviarComentario)
  Future<void> cargarComentarios(String lugarId) async {
    _estaCargandoComentarios = true;
    notifyListeners();

    _comentarios = await _repositorio.obtenerComentarios(lugarId);

    _estaCargandoComentarios = false;
    notifyListeners();
  }

  Future<void> enviarComentario(
      String lugarId, String texto, double rating) async {
    await _repositorio.enviarComentario(lugarId, texto, rating);
    await cargarComentarios(lugarId);
  }

  // --- ¡LÓGICA DE FAVORITOS CONECTADA! ---

  // NUEVO GETTER: La UI preguntará a este método si un lugar es favorito
  bool esLugarFavorito(String lugarId) {
    return _authVM?.lugaresFavoritosIds.contains(lugarId) ?? false;
  }





  // MÉTODO MODIFICADO: Ahora llama al "cerebro" (AuthVM)
  Future<void> toggleLugarFavorito(String lugarId) async {
    // 1. Le damos la "orden" al "Cerebro" (AuthVM)
    await _authVM?.toggleLugarFavorito(lugarId);

    // 2. No necesitamos notificar. AuthVM notificará,
    //    y este VM (LugaresVM) escuchará ese cambio
    //    y se redibujará automáticamente.
  }
}
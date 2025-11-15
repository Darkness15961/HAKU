// --- PIEDRA 4: EL "MESERO" (VERSIÓN ACOMPLADA PARA COMENTARIOS Y GESTIÓN) ---
//
// (...)
// 2. (¡NUEVO!): Añadida la lógica de Admin para 'crearLugar',
//    'actualizarLugar' y 'eliminarLugar' (Simulado).
// 3. (¡NUEVO!): Añadida la lógica de Admin para gestionar Provincias.

import 'dart:async';
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

// Importamos el "Cerebro" (AuthVM)
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class LugaresVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final LugaresRepositorio _repositorio;
  AutenticacionVM? _authVM;

  // --- B. ESTADO DE LA UI (INICIO_PAGINA) ---
  bool _estaCargandoInicio = true;
  List<Lugar> _lugaresPopulares = [];
  List<Provincia> _provincias = [];
  List<Categoria> _categorias = [];
  List<Lugar> _lugaresTotales = [];
  String _terminoBusquedaInicio = '';
  String _categoriaSeleccionadaIdInicio = '1';
  int _carouselIndex = 0;
  bool _cargaInicialRealizada = false;

  // --- ¡AÑADIDO! ESTADO DE GESTIÓN ---
  bool _estaCargandoGestion = false;
  String? _errorGestion;

  // --- C. GETTERS (INICIO_PAGINA Y PERFIL) ---
  bool get estaCargandoInicio => _estaCargandoInicio;
  List<Lugar> get lugaresPopulares => _lugaresPopulares;
  List<Categoria> get categorias => _categorias;
  String get categoriaSeleccionadaIdInicio => _categoriaSeleccionadaIdInicio;
  int get carouselIndex => _carouselIndex;
  bool get cargaInicialRealizada => _cargaInicialRealizada;
  List<Lugar> get lugaresTotales => _lugaresTotales;

  // --- ¡AÑADIDO! GETTERS DE GESTIÓN ---
  bool get estaCargandoGestion => _estaCargandoGestion;
  String? get errorGestion => _errorGestion;

  List<Lugar> get misLugaresFavoritos {
    if (_authVM == null || !_authVM!.estaLogueado) return [];
    final ids = _authVM!.lugaresFavoritosIds;
    return _lugaresTotales.where((l) => ids.contains(l.id)).toList();
  }

  List<Provincia> get provinciasFiltradas {
    List<Provincia> provinciasFiltradas = _provincias;

    if (_categoriaSeleccionadaIdInicio != '1') {
      final categoria =
      _categorias.firstWhere((c) => c.id == _categoriaSeleccionadaIdInicio);
      provinciasFiltradas = provinciasFiltradas.where((provincia) {
        return provincia.categories.any((c) => c.toLowerCase() == categoria.nombre.toLowerCase());
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
        return lugar.categoria.toLowerCase() == categoria.nombre.toLowerCase();
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


  // --- H. CONSTRUCTOR (¡LIMPIO!) ---
  LugaresVM() {
    _repositorio = getIt<LugaresRepositorio>();
  }

  // --- I. MÉTODOS DE INICIALIZACIÓN (¡CORREGIDOS CON FUTURE!) ---
  // (Tu código intacto aquí...)
  Future<void> cargarDatosIniciales(AutenticacionVM authVM) async {
    if (_authVM == null) {
      _authVM = authVM;
      _authVM?.addListener(_onAuthChanged);
    }

    if (_authVM?.estaCargando ?? false) {
      _estaCargandoInicio = true;
      notifyListeners();
      final authCompleter = Completer<void>();
      void onAuthReady() {
        _authVM?.removeListener(onAuthReady);
        if (!authCompleter.isCompleted) {
          authCompleter.complete();
        }
      }
      _authVM?.addListener(onAuthReady);
      await authCompleter.future;
    }

    await _cargarCatalogos();
  }

  void _onAuthChanged() {
    notifyListeners();
  }

  Future<void> _cargarCatalogos() async {
    _estaCargandoInicio = true;

    if(_cargaInicialRealizada) {
      Future.microtask(() => notifyListeners());
    }

    try {
      final todosLugaresFuture = _repositorio.obtenerTodosLosLugares();
      final resultados = await Future.wait([
        _repositorio.obtenerLugaresPopulares(),
        _repositorio.obtenerProvincias(),
        _repositorio.obtenerCategorias(),
        todosLugaresFuture,
      ]);

      _lugaresPopulares = resultados[0] as List<Lugar>;
      _provincias = resultados[1] as List<Provincia>;
      _categorias = resultados[2] as List<Categoria>;
      _lugaresTotales = resultados[3] as List<Lugar>;

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
    super.dispose();
  }

  // --- J. MÉTODOS (Órdenes para INICIO_PAGINA) ---
  // (Tu código intacto aquí...)
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
  // (Tu código intacto aquí...)
  Future<void> cargarLugaresPorProvincia(String provinciaId) async {
    _estaCargandoLugaresDeProvincia = true;
    _terminoBusquedaProvincia = '';
    _categoriaSeleccionadaIdProvincia = '1';
    notifyListeners();

    _lugaresDeProvincia = _lugaresTotales
        .where((lugar) => lugar.provinciaId == provinciaId)
        .toList();

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
  // (Tu código intacto aquí...)
  Future<void> cargarComentarios(String lugarId) async {
    _estaCargandoComentarios = true;
    notifyListeners();
    _comentarios = await _repositorio.obtenerComentarios(lugarId);
    _estaCargandoComentarios = false;
    notifyListeners();
  }

  Future<void> enviarComentario(
      String lugarId, String texto, double rating) async {
    if (_authVM == null || !_authVM!.estaLogueado || _authVM!.usuarioActual == null) {
      print("Error: Usuario no autenticado. No se puede comentar.");
      return;
    }
    final usuario = _authVM!.usuarioActual!;
    final String usuarioNombre = usuario.nombre;
    final String? urlFotoUsuario = usuario.urlFotoPerfil;
    final String usuarioId = usuario.id;

    await _repositorio.enviarComentario(
        lugarId,
        texto,
        rating,
        usuarioNombre,
        urlFotoUsuario,
        usuarioId
    );
    await cargarComentarios(lugarId);
  }

  // --- M. LÓGICA DE FAVORITOS (Intacta) ---
  bool esLugarFavorito(String lugarId) {
    return _authVM?.lugaresFavoritosIds.contains(lugarId) ?? false;
  }

  Future<void> toggleLugarFavorito(String lugarId) async {
    await _authVM?.toggleLugarFavorito(lugarId);
  }


  // --- N. MÉTODOS (Órdenes para GESTIÓN DE LUGARES) ---
  Future<void> cargarTodosLosLugares() async {
    _estaCargandoGestion = true;
    notifyListeners();
    try {
      _lugaresTotales = await _repositorio.obtenerTodosLosLugares();
    } catch (e) {
      _errorGestion = e.toString();
    }
    _estaCargandoGestion = false;
    notifyListeners();
  }

  Future<void> crearLugar(Map<String, dynamic> datosLugar) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      final String provinciaId = datosLugar['provinciaId'];
      final String categoriaId = datosLugar['categoriaId'];
      final String provinciaNombre = _provincias.firstWhere((p) => p.id == provinciaId).nombre;
      final String categoriaNombre = _categorias.firstWhere((c) => c.id == categoriaId).nombre;
      datosLugar['provinciaNombre'] = provinciaNombre;
      datosLugar['categoriaNombre'] = categoriaNombre;
      await _repositorio.crearLugar(datosLugar);
      await cargarTodosLosLugares();
    } catch (e) {
      _errorGestion = e.toString();
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  Future<void> actualizarLugar(String lugarId, Map<String, dynamic> datosLugar) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      final String provinciaId = datosLugar['provinciaId'];
      final String categoriaId = datosLugar['categoriaId'];
      final String provinciaNombre = _provincias.firstWhere((p) => p.id == provinciaId).nombre;
      final String categoriaNombre = _categorias.firstWhere((c) => c.id == categoriaId).nombre;
      datosLugar['provinciaNombre'] = provinciaNombre;
      datosLugar['categoriaNombre'] = categoriaNombre;
      await _repositorio.actualizarLugar(lugarId, datosLugar);
      await cargarTodosLosLugares();
    } catch (e) {
      _errorGestion = e.toString();
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  Future<void> eliminarLugar(String lugarId) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      await _repositorio.eliminarLugar(lugarId);
      _lugaresTotales.removeWhere((l) => l.id == lugarId);
    } catch (e) {
      _errorGestion = e.toString();
    }
    _estaCargandoGestion = false;
    notifyListeners();
  }


  // --- ¡AÑADIDO! O. MÉTODOS (Órdenes para GESTIÓN DE PROVINCIAS) ---

  // Usado para recargar la lista de 'provinciasFiltradas' en la página de gestión
  Future<void> cargarTodasLasProvincias() async {
    _estaCargandoGestion = true;
    notifyListeners();
    try {
      // _provincias ya se carga al inicio, pero forzamos recarga
      _provincias = await _repositorio.obtenerProvincias();
    } catch (e) {
      _errorGestion = e.toString();
    }
    _estaCargandoGestion = false;
    notifyListeners();
  }

  Future<void> crearProvincia(Map<String, dynamic> datosProvincia) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      await _repositorio.crearProvincia(datosProvincia);
      // Recargamos la lista local
      await cargarTodasLasProvincias();
    } catch (e) {
      _errorGestion = e.toString();
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  Future<void> actualizarProvincia(String provinciaId, Map<String, dynamic> datosProvincia) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      await _repositorio.actualizarProvincia(provinciaId, datosProvincia);
      await cargarTodasLasProvincias();
    } catch (e) {
      _errorGestion = e.toString();
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  Future<void> eliminarProvincia(String provinciaId) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      await _repositorio.eliminarProvincia(provinciaId);
      // Actualizamos la lista localmente
      _provincias.removeWhere((p) => p.id == provinciaId);
    } catch (e) {
      _errorGestion = e.toString();
    }
    _estaCargandoGestion = false;
    notifyListeners();
  }
// --- FIN DE LO AÑADIDO ---
}
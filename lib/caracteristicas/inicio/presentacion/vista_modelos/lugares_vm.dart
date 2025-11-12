// --- PIEDRA 4: EL "MESERO" (VERSIÓN ACOMPLADA PARA COMENTARIOS) ---
//
// 1. (ACOMPLADO): El método 'enviarComentario' ahora "jala" los datos
//    del 'AuthVM' (Cerebro) para enviarlos al Repositorio.
// 2. (ESTABLE): Mantiene toda la lógica de 'lugaresTotales'.

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
  AutenticacionVM? _authVM; // <-- Ya tiene la conexión al "Cerebro"

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

  // --- C. GETTERS (INICIO_PAGINA Y PERFIL) ---
  bool get estaCargandoInicio => _estaCargandoInicio;
  List<Lugar> get lugaresPopulares => _lugaresPopulares;
  List<Categoria> get categorias => _categorias;
  String get categoriaSeleccionadaIdInicio => _categoriaSeleccionadaIdInicio;
  int get carouselIndex => _carouselIndex;
  bool get cargaInicialRealizada => _cargaInicialRealizada;
  List<Lugar> get lugaresTotales => _lugaresTotales;

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
        // (Lógica de filtro de provincia acoplada para minúsculas)
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
        // (Lógica de filtro de provincia acoplada para minúsculas)
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

  // --- ¡MÉTODO CRÍTICO ACTUALIZADO! ---
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
  Future<void> cargarComentarios(String lugarId) async {
    _estaCargandoComentarios = true;
    notifyListeners();

    _comentarios = await _repositorio.obtenerComentarios(lugarId);

    _estaCargandoComentarios = false;
    notifyListeners();
  }

  // --- ¡MÉTODO ACOMPLADO! (Paso 2) ---
  Future<void> enviarComentario(
      String lugarId, String texto, double rating) async {

    // 1. Verificamos el "Cerebro" (AuthVM)
    if (_authVM == null || !_authVM!.estaLogueado || _authVM!.usuarioActual == null) {
      // (Esto es solo una seguridad, la UI no debería permitir
      //  enviar el comentario si el usuario no está logueado)
      print("Error: Usuario no autenticado. No se puede comentar.");
      return;
    }

    // 2. Obtenemos los datos del usuario logueado desde el "Cerebro"
    final usuario = _authVM!.usuarioActual!;
    final String usuarioNombre = usuario.nombre;
    final String? urlFotoUsuario = usuario.urlFotoPerfil; // Es 'String?' (opcional)
    final String usuarioId = usuario.id;

    // 3. Llamamos al "Enchufe" (Repositorio) con la "orden" ACOMPLADA
    await _repositorio.enviarComentario(
        lugarId,
        texto,
        rating,
        usuarioNombre, // <-- Acoplado
        urlFotoUsuario, // <-- Acoplado
        usuarioId       // <-- Acoplado
    );

    // 4. Refrescamos la lista
    // (En el Paso 3, haremos que el Mock guarde esto,
    // así que 'cargarComentarios' mostrará el nuevo comentario)
    await cargarComentarios(lugarId);
  }
  // --- FIN DE MÉTODO ACOMPLADO ---

  // --- ¡LÓGICA DE FAVORITOS CONECTADA! ---

  bool esLugarFavorito(String lugarId) {
    return _authVM?.lugaresFavoritosIds.contains(lugarId) ?? false;
  }

  Future<void> toggleLugarFavorito(String lugarId) async {
    await _authVM?.toggleLugarFavorito(lugarId);
  }
}
import 'dart:async';
import 'package:flutter/material.dart';

import '../../dominio/repositorios/lugares_repositorio.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';
import '../../dominio/entidades/comentario.dart';
import '../../dominio/entidades/recuerdo.dart';
import '../../../../locator.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../datos/repositorios/lugares_repositorio_supabase.dart'; // Import necesario para cast

class LugaresVM extends ChangeNotifier {
  late final LugaresRepositorio _repositorio;
  AutenticacionVM? _authVM;

  // --- ESTADO INICIO ---
  bool _estaCargandoInicio = true;
  List<Lugar> _lugaresPopulares = [];
  List<Provincia> _provincias = [];
  List<Categoria> _categorias = [];
  List<Lugar> _lugaresTotales = []; // Esta es la lista "maestra"

  String _terminoBusquedaInicio = '';
  String _categoriaSeleccionadaIdInicio = '1';
  int _carouselIndex = 0;
  bool _cargaInicialRealizada = false;

  // --- ESTADO GESTIÓN ---
  bool _estaCargandoGestion = false;
  String? _errorGestion;

  // --- ESTADO DETALLE ---
  bool _estaCargandoLugaresDeProvincia = true;
  List<Lugar> _lugaresDeProvincia = [];
  String _terminoBusquedaProvincia = '';
  String _categoriaSeleccionadaIdProvincia = '1';

  bool _estaCargandoComentarios = true;
  List<Comentario> _comentarios = [];

  List<Recuerdo> _misRecuerdos = []; // <--- NUEVO
  List<Recuerdo> get misRecuerdos => _misRecuerdos; // <--- NUEVO

  // --- GETTERS ---
  bool get estaCargandoInicio => _estaCargandoInicio;
  List<Lugar> get lugaresPopulares => _lugaresPopulares;
  List<Categoria> get categorias => _categorias;
  String get categoriaSeleccionadaIdInicio => _categoriaSeleccionadaIdInicio;
  int get carouselIndex => _carouselIndex;
  bool get cargaInicialRealizada => _cargaInicialRealizada;
  List<Lugar> get lugaresTotales => _lugaresTotales;

  bool get estaCargandoGestion => _estaCargandoGestion;
  String? get errorGestion => _errorGestion;

  List<Provincia> get todasLasProvincias => _provincias;
  bool get estaCargandoLugaresDeProvincia => _estaCargandoLugaresDeProvincia;
  String get categoriaSeleccionadaIdProvincia =>
      _categoriaSeleccionadaIdProvincia;
  bool get estaCargandoComentarios => _estaCargandoComentarios;
  List<Comentario> get comentarios => _comentarios;

  // --- GETTERS CALCULADOS ---
  List<Lugar> get misLugaresPublicados {
    if (_authVM == null || !_authVM!.estaLogueado) return [];
    final userId = _authVM!.usuarioActual!.id;
    return _lugaresTotales.where((l) => l.usuarioId == userId).toList();
  }

  List<Lugar> get misLugaresFavoritos {
    if (_authVM == null || !_authVM!.estaLogueado) return [];
    final ids = _authVM!.lugaresFavoritosIds;
    // Buscamos los lugares que coincidan con los IDs de favoritos
    return _lugaresTotales.where((l) => ids.contains(l.id)).toList();
  }

  List<Provincia> get provinciasFiltradas {
    List<Provincia> filtradas = _provincias;
    if (_categoriaSeleccionadaIdInicio != '1') {
      final categoria = _categorias.firstWhere(
        (c) => c.id == _categoriaSeleccionadaIdInicio,
      );
      filtradas = filtradas
          .where(
            (p) => p.categories.any(
              (c) => c.toLowerCase() == categoria.nombre.toLowerCase(),
            ),
          )
          .toList();
    }
    if (_terminoBusquedaInicio.isNotEmpty) {
      filtradas = filtradas
          .where(
            (p) => p.nombre.toLowerCase().contains(
              _terminoBusquedaInicio.toLowerCase(),
            ),
          )
          .toList();
    }
    return filtradas;
  }

  List<Lugar> get lugaresFiltradosDeProvincia {
    List<Lugar> filtrados = _lugaresDeProvincia;
    if (_categoriaSeleccionadaIdProvincia != '1') {
      final categoria = _categorias.firstWhere(
        (c) => c.id == _categoriaSeleccionadaIdProvincia,
      );
      filtrados = filtrados
          .where(
            (l) => l.categoria.toLowerCase() == categoria.nombre.toLowerCase(),
          )
          .toList();
    }
    if (_terminoBusquedaProvincia.isNotEmpty) {
      final busqueda = _terminoBusquedaProvincia.toLowerCase();
      filtrados = filtrados
          .where(
            (l) =>
                l.nombre.toLowerCase().contains(busqueda) ||
                l.descripcion.toLowerCase().contains(busqueda),
          )
          .toList();
    }
    return filtrados;
  }

  // --- CONSTRUCTOR ---
  LugaresVM() {
    _repositorio = getIt<LugaresRepositorio>();
  }

  // --- INICIALIZACIÓN ---
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
        if (!authCompleter.isCompleted) authCompleter.complete();
      }

      _authVM?.addListener(onAuthReady);
      await authCompleter.future;
    }

    // Cargar datos dependientes del usuario
    if (_authVM?.estaLogueado ?? false) {
      await cargarFavoritos();
      await cargarMisRecuerdos(); // <--- ¡AGREGAR ESTO!
    }

    await _cargarCatalogos();
  }

  void _onAuthChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _authVM?.removeListener(_onAuthChanged);
    super.dispose();
  }

  // --- NUEVO MÉTODO FASE 4 ---
  Future<void> cargarMisRecuerdos() async {
    if (_repositorio is LugaresRepositorioSupabase) {
      try {
        _misRecuerdos = await (_repositorio as LugaresRepositorioSupabase)
            .obtenerMisRecuerdos();
        notifyListeners();
      } catch (e) {
        print("Error cargando recuerdos: $e");
      }
    }
  }

  // --- CARGA DE DATOS ---
  Future<void> _cargarCatalogos() async {
    _estaCargandoInicio = true;
    if (_cargaInicialRealizada) Future.microtask(() => notifyListeners());

    // 1. Cargar Favoritos desde DB si está logueado
    if (_authVM?.estaLogueado ?? false) {
      await cargarFavoritos();
    }

    try {
      final resultados = await Future.wait([
        _repositorio.obtenerLugaresPopulares(),
        _repositorio.obtenerProvincias(),
        _repositorio.obtenerCategorias(),
        _repositorio.obtenerTodosLosLugares(),
      ]);

      _lugaresPopulares = resultados[0] as List<Lugar>;
      _provincias = resultados[1] as List<Provincia>;
      _categorias = resultados[2] as List<Categoria>;
      _lugaresTotales =
          resultados[3] as List<Lugar>; // Lista maestra actualizada
    } catch (e) {
      print("Error cargando catálogos: $e");
    } finally {
      _estaCargandoInicio = false;
      _cargaInicialRealizada = true;
      notifyListeners();
    }
  }

  // --- NUEVO: Cargar Favoritos Reales ---
  Future<void> cargarFavoritos() async {
    // Validamos que haya usuario logueado
    if (_authVM == null || !_authVM!.estaLogueado) return;

    final userId = _authVM!.usuarioActual!.id;

    // Llamamos DIRECTAMENTE al repositorio (sin cast, sin 'if is Supabase')
    // Ahora el contrato lo permite.
    final ids = await _repositorio.obtenerIdsFavoritos(userId);

    // Actualizamos el AuthVM
    _authVM?.actualizarFavoritos(ids);
    notifyListeners();
  }

  // --- BÚSQUEDA Y FILTROS ---
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

  // --- LUGARES POR PROVINCIA ---
  Future<void> cargarLugaresPorProvincia(String provinciaId) async {
    _estaCargandoLugaresDeProvincia = true;
    _terminoBusquedaProvincia = '';
    _categoriaSeleccionadaIdProvincia = '1';
    notifyListeners();

    // Filtramos de la lista total en memoria para rapidez,
    // pero podrías llamar al repo si prefieres datos frescos siempre.
    _lugaresDeProvincia = _lugaresTotales
        .where((l) => l.provinciaId == provinciaId)
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

  // --- GESTIÓN DE USUARIO ---
  Future<void> cargarLugaresPorUsuario() async {
    if (_authVM == null || !_authVM!.estaLogueado) return;
    _estaCargandoGestion = true;
    notifyListeners();
    try {
      final userId = _authVM!.usuarioActual!.id;
      final lugaresUsuario = await _repositorio.obtenerLugaresPorUsuario(
        userId,
      );
      // Actualizamos la lista maestra con los datos frescos del usuario
      for (var lugar in lugaresUsuario) {
        final index = _lugaresTotales.indexWhere((l) => l.id == lugar.id);
        if (index != -1) {
          _lugaresTotales[index] = lugar;
        } else {
          _lugaresTotales.add(lugar);
        }
      }
    } catch (e) {
      _errorGestion = e.toString();
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  // --- COMENTARIOS Y RATING ---
  Future<void> cargarComentarios(String lugarId) async {
    _estaCargandoComentarios = true;
    notifyListeners();
    _comentarios = await _repositorio.obtenerComentarios(lugarId);
    _estaCargandoComentarios = false;
    notifyListeners();
  }

  Future<void> enviarComentario(
    String lugarId,
    String texto,
    double rating,
  ) async {
    if (_authVM == null ||
        !_authVM!.estaLogueado ||
        _authVM!.usuarioActual == null)
      return;

    final usuario = _authVM!.usuarioActual!;
    await _repositorio.enviarComentario(
      lugarId,
      texto,
      rating,
      usuario.nombre,
      usuario.urlFotoPerfil,
      usuario.id,
    );

    // 1. Recargar comentarios para ver el nuevo
    await cargarComentarios(lugarId);
    // 2. Recargar datos del lugar para ver el nuevo rating/promedio
    await recargarLugar(lugarId);
  }

  // --- NUEVO: Recargar un solo lugar ---
  Future<void> recargarLugar(String lugarId) async {
    // Por simplicidad y consistencia, recargamos todo el catálogo
    // Esto asegura que el rating se actualice en la lista principal y favoritos
    final todos = await _repositorio.obtenerTodosLosLugares();
    _lugaresTotales = todos;
    notifyListeners();
  }

  // --- FAVORITOS ---
  bool esLugarFavorito(String lugarId) {
    return _authVM?.lugaresFavoritosIds.contains(lugarId) ?? false;
  }

  Future<void> toggleLugarFavorito(String lugarId) async {
    // 1. Optimista: Cambiamos en UI inmediatamente
    await _authVM?.toggleLugarFavorito(lugarId);
    notifyListeners();

    try {
      // 2. Real: Llamamos a BD
      await _repositorio.marcarFavorito(lugarId);
      // 3. Confirmación: Recargamos la lista real de favoritos para asegurar sincronía
      await cargarFavoritos();
    } catch (e) {
      // Si falla, revertimos el cambio optimista
      await _authVM?.toggleLugarFavorito(lugarId);
      notifyListeners();
    }
  }

  // --- GESTIÓN DE LUGARES (ADMIN) ---
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
      final nuevoLugar = await _repositorio.crearLugar(datosLugar);
      _lugaresTotales.add(nuevoLugar);
    } catch (e) {
      _errorGestion = e.toString();
      rethrow;
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  Future<void> actualizarLugar(
    String lugarId,
    Map<String, dynamic> datosLugar,
  ) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      final lugarActualizado = await _repositorio.actualizarLugar(
        lugarId,
        datosLugar,
      );
      final index = _lugaresTotales.indexWhere((l) => l.id == lugarId);
      if (index != -1) {
        _lugaresTotales[index] = lugarActualizado;
      }
    } catch (e) {
      _errorGestion = e.toString();
      rethrow;
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
      rethrow;
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  // --- GESTIÓN DE PROVINCIAS ---
  Future<void> cargarTodasLasProvincias() async {
    _estaCargandoGestion = true;
    notifyListeners();
    try {
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
      await cargarTodasLasProvincias();
    } catch (e) {
      _errorGestion = e.toString();
      rethrow;
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }

  Future<void> actualizarProvincia(
    String provinciaId,
    Map<String, dynamic> datosProvincia,
  ) async {
    _estaCargandoGestion = true;
    _errorGestion = null;
    notifyListeners();
    try {
      await _repositorio.actualizarProvincia(provinciaId, datosProvincia);
      await cargarTodasLasProvincias();
    } catch (e) {
      _errorGestion = e.toString();
      rethrow;
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
      _provincias.removeWhere((p) => p.id == provinciaId);
    } catch (e) {
      _errorGestion = e.toString();
      rethrow;
    } finally {
      _estaCargandoGestion = false;
      notifyListeners();
    }
  }
}

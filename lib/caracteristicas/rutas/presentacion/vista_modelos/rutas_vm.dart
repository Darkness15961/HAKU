// --- CARACTERISTICAS/RUTAS/PRESENTACION/VISTA_MODELOS/RUTAS_VM.DART ---
// Versión: CON CEREBRO OSRM (Calcula la ruta antes de guardar)

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // <--- NUEVO IMPORT (Para manejar coordenadas)
import '../../dominio/repositorios/rutas_repositorio.dart';
import '../../datos/repositorios/rutas_repositorio_supabase.dart';
import '../../dominio/entidades/ruta.dart';
import '../../../../locator.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../datos/servicios/osrm_service.dart'; // <--- NUEVO IMPORT (Tu servicio calculadora)


class RutasVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final RutasRepositorio _repositorio;
  final OsrmService _osrmService = OsrmService(); // <--- Instancia del servicio
  AutenticacionVM? _authVM;

  // --- B. ESTADO DE LA UI ---
  // --- B. ESTADO DE LA UI ---
  bool _estaCargando = false;
  List<Ruta> _rutas = [];
  String _pestanaActual = 'Recomendadas';
  String _categoriaActual = 'Todos';
  String? _error;
  bool _cargaInicialRealizada = false;

  // --- PAGINACIÓN ---
  int _page = 0;
  final int _pageSize = 6;
  bool _hasMore = true; // Si hay más páginas por cargar
  bool _isLoadingMore = false; // Cargando la siguiente página (spinner abajo)

  // --- C. GETTERS (Iguales) ---
  bool get estaCargando => _estaCargando;
  String get pestanaActual => _pestanaActual;
  String get categoriaActual => _categoriaActual;
  String? get error => _error;
  bool get cargaInicialRealizada => _cargaInicialRealizada;
  
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  List<Ruta> get rutasFiltradas {
    if (_categoriaActual == 'Todos') {
      return _rutas;
    } else {
      return _rutas.where((ruta) {
        return ruta.categoria.toLowerCase() == _categoriaActual.toLowerCase();
      }).toList();
    }
  }

  List<Ruta> get misRutasInscritas {
    if (_authVM == null || !_authVM!.estaLogueado) return [];
    final ids = _authVM!.rutasInscritasIds;
    return _rutas.where((r) => ids.contains(r.id)).toList();
  }

  // --- D. CONSTRUCTOR ---
  RutasVM() {
    _repositorio = getIt<RutasRepositorio>();
  }

  // --- E. MÉTODOS DE CARGA (Iguales) ---
  void cargarDatosIniciales(AutenticacionVM authVM) {
    if (_cargaInicialRealizada) return;
    _authVM = authVM;
    if (_authVM?.estaCargando ?? false) {
      _authVM?.addListener(_onAuthReadyParaRutas);
      return;
    }
    _iniciarCargaLogica();
  }

  void _onAuthReadyParaRutas() {
    _iniciarCargaLogica();
    _authVM?.removeListener(_onAuthReadyParaRutas);
  }

  void _iniciarCargaLogica() {
    _authVM?.addListener(_actualizarPestanaPorRol);
    _actualizarPestanaPorRol();
  }

  void _actualizarPestanaPorRol() {
    final rol = _authVM?.usuarioActual?.rol;
    final esAnonimo = !(_authVM?.estaLogueado ?? false);

    if (_pestanaActual == 'Creadas por mí' &&
        rol != 'guia_aprobado' &&
        rol != 'guia' &&
        rol != 'guia_local' &&
        rol != 'admin') {
      _pestanaActual = 'Recomendadas';
    }
    if (_pestanaActual == 'Guardadas' && esAnonimo) {
      _pestanaActual = 'Recomendadas';
    }

    if (!_estaCargando) {
      cargarRutas();
    }
  }

  // --- E. MÉTODOS DE CARGA (Con Paginación) ---
  
  // Método público para "Cargar Más" (Scroll Bottom)
  Future<void> cargarMasRutas() async {
    if (_isLoadingMore || !_hasMore) return;
    await cargarRutas(refresh: false);
  }

  Future<void> cargarRutas({bool refresh = true}) async {
    if (refresh) {
      _estaCargando = true; // Spinner grande solo si es refresh
      _page = 0;
      _hasMore = true;
      _error = null;
      notifyListeners();
    } else {
      _isLoadingMore = true; // Spinner pequeño abajo
      notifyListeners();
    }

    try {
      String tipoFiltro = 'recomendadas';
      if (_pestanaActual == 'Mis Inscripciones') {
        tipoFiltro = 'inscritas';
      } else if (_pestanaActual == 'Creadas por mí') {
        tipoFiltro = 'creadas_por_mi';
      }

      print('🔄 [VM] Cargando rutas. Page: $_page. Filter: $tipoFiltro. Refresh: $refresh');

      final nuevasRutas = await _repositorio.obtenerRutas(
        tipoFiltro,
        page: _page,
        pageSize: _pageSize,
      );

      if (refresh) {
        _rutas = nuevasRutas;
      } else {
        _rutas.addAll(nuevasRutas);
      }

      // Lógica de "Habrá más?": Si trajimos menos de lo pedido, se acabó.
      if (nuevasRutas.length < _pageSize) {
        _hasMore = false;
      } else {
        _page++; // Preparamos para la siguiente
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      _estaCargando = false;
      _isLoadingMore = false;
      if (refresh) _cargaInicialRealizada = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authVM?.removeListener(_actualizarPestanaPorRol);
    _authVM?.removeListener(_onAuthReadyParaRutas);
    super.dispose();
  }

  // --- G. MÉTODOS DE ACCIÓN ---

  void cambiarPestana(String nuevaPestana) {
    if (nuevaPestana == _pestanaActual) return;
    _pestanaActual = nuevaPestana;
    _categoriaActual = 'Todos';
    cargarRutas(refresh: true); // Al cambiar pestaña, reiniciamos todo
  }

  void cambiarCategoria(String nuevaCategoria) {
    if (nuevaCategoria == _categoriaActual) return;
    _categoriaActual = nuevaCategoria;
    notifyListeners();
  }

  Future<void> inscribirseEnRuta(String rutaId) async {
    await _repositorio.inscribirseEnRuta(rutaId);
    await _authVM?.toggleRutaInscrita(rutaId);
  }

  Future<void> unirseARutaPorCodigo(String codigo) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      if (_repositorio is RutasRepositorioSupabase) {
        await _repositorio.unirseARutaPorCodigo(codigo);
      } else {
        await _repositorio.unirseARutaPorCodigo(codigo);
      }
      _estaCargando = false;
      notifyListeners();
      await cargarRutas();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> salirDeRuta(String rutaId) async {
    await _repositorio.salirDeRuta(rutaId);
    await _authVM?.toggleRutaInscrita(rutaId);
  }

  Future<void> toggleFavoritoRuta(String rutaId) async {
    await _authVM?.toggleRutaFavorita(rutaId);
  }

  // --- ¡AQUÍ ESTÁ LA MAGIA OSRM! (Método Modificado) ---
  Future<void> crearRuta(Map<String, dynamic> datosRuta) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. RECUPERAR COORDENADAS
      // En 'crear_ruta_pagina.dart', estamos pasando 'lugaresIds' (lista de Strings).
      // Pero para calcular la ruta, necesitamos los objetos Lugar completos (con lat/lng).
      //
      // OPCIÓN SEGURA: Si ya tienes los objetos Lugar en la página anterior,
      // lo ideal sería pasarlos. Pero para no romper tu flujo actual, vamos a
      // asumir que debemos confiar en los IDs o que 'datosRuta' trae algo más.

      // TRUCO: Como en 'crear_ruta_pagina.dart' tú tienes la lista '_locations',
      // vamos a hacer un pequeño hack:
      // Tu UI debería enviar una lista de LatLng en 'datosRuta' bajo una clave temporal.
      //
      // Si no lo hace, no podemos calcular.
      // Asumiremos que agregaste 'puntos_coordenadas' al mapa en el paso anterior.
      // Si no, el servicio devuelve vacío y no pasa nada malo.

      List<LatLng> puntosParaCalculo = [];
      if (datosRuta['puntos_coordenadas'] != null) {
        puntosParaCalculo = datosRuta['puntos_coordenadas'] as List<LatLng>;
      }

      // 2. LLAMAR A OSRM (El Cerebro)
      if (puntosParaCalculo.length >= 2) {
        print('🧠 [RutasVM] Calculando ruta con OSRM...');
        final resultadoOsrm = await _osrmService.getRutaCompleta(puntosParaCalculo);

        // 3. AGREGAR RESULTADOS AL MAPA PARA SUPABASE
        // Ojo: jsonEncode lo hace Supabase internamente si le pasas listas simples.
        // Pero nosotros necesitamos pasar una lista de listas [[lat,lng], [lat,lng]].
        final List<LatLng> geometria = resultadoOsrm['points'];
        final List<List<double>> geometriaJson = geometria.map((p) => [p.latitude, p.longitude]).toList();

        datosRuta['geometria_json'] = geometriaJson;
        datosRuta['distancia_metros'] = resultadoOsrm['distance'];
        datosRuta['duracion_segundos'] = resultadoOsrm['duration'];

        print('✅ [RutasVM] OSRM terminó. Distancia: ${resultadoOsrm['distance']}m');
      } else {
        print('⚠️ [RutasVM] No hay suficientes puntos para calcular ruta.');
      }

      // 4. GUARDAR EN BASE DE DATOS (Lo de siempre)
      await _repositorio.crearRuta(datosRuta);

      _estaCargando = false;
      notifyListeners();
      await cargarRutas();

    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // --- (Resto de métodos CRUD iguales) ---

  Future<void> actualizarRuta(
      String rutaId,
      Map<String, dynamic> datosRuta,
      ) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      // NOTA: Si quisieras recalcular la ruta al editar, aquí deberías repetir
      // la lógica de OSRM (Paso 1, 2, 3) antes de llamar a actualizarRuta.
      // Por ahora lo dejamos simple.
      await _repositorio.actualizarRuta(rutaId, datosRuta);
      _estaCargando = false;
      notifyListeners();
      await cargarRutas();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> cancelarRuta(String rutaId, String mensaje) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.cancelarRuta(rutaId, mensaje);
      _estaCargando = false;
      notifyListeners();
      await cargarRutas();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> eliminarRuta(String rutaId) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.eliminarRuta(rutaId);
      _estaCargando = false;
      notifyListeners();
      await cargarRutas();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> marcarAsistencia(String rutaId) async {
    _estaCargando = true;
    notifyListeners();
    try {
      if (_repositorio is RutasRepositorioSupabase) {
        await (_repositorio as RutasRepositorioSupabase).marcarAsistencia(rutaId);
      }
      await cargarRutas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  Future<void> cambiarEstadoRuta(String rutaId, String nuevoEstado) async {
    _estaCargando = true;
    notifyListeners();
    try {
      if (_repositorio is RutasRepositorioSupabase) {
        await (_repositorio as RutasRepositorioSupabase).cambiarEstadoRuta(rutaId, nuevoEstado);
      }
      await cargarRutas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }
}
// --- PIEDRA 5 (RUTAS): EL "MESERO DE RUTAS" (CONECTADO AL CEREBRO Y PERFIL) ---
//
// 1. (BUG LÓGICA CORREGIDO): 'inscribirseEnRuta' y 'salirDeRuta'
//    ahora SÍ llaman al repositorio para actualizar la base de datos
//    (el Mock), lo que arregla el bug de 'inscritosCount'.

import 'package:flutter/material.dart';
import '../../dominio/repositorios/rutas_repositorio.dart';
import '../../dominio/entidades/ruta.dart';
import '../../../../locator.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class RutasVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final RutasRepositorio _repositorio;
  AutenticacionVM? _authVM;

  // --- B. ESTADO DE LA UI ---
  bool _estaCargando = false;
  List<Ruta> _rutas = [];
  String _pestanaActual = 'Recomendadas';
  String _dificultadActual = 'Todos';
  String? _error;
  bool _cargaInicialRealizada = false;

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  String get pestanaActual => _pestanaActual;
  String get dificultadActual => _dificultadActual;
  String? get error => _error;
  bool get cargaInicialRealizada => _cargaInicialRealizada;

  List<Ruta> get rutasFiltradas {
    if (_dificultadActual == 'Todos') {
      return _rutas;
    } else {
      return _rutas.where((ruta) {
        return ruta.dificultad.toLowerCase() ==
            _dificultadActual.toLowerCase();
      }).toList();
    }
  }

  // --- ¡NUEVO GETTER PARA EL PERFIL! (Paso 2 Acoplado) ---
  List<Ruta> get misRutasInscritas {
    // 1. Verificamos que el "Cerebro" (AuthVM) esté listo
    if (_authVM == null || !_authVM!.estaLogueado) return [];

    // 2. Obtenemos los IDs del "Cerebro"
    final ids = _authVM!.rutasInscritasIds;

    // 3. Filtramos la lista completa de rutas
    // (Usamos _rutas, que es la lista principal que carga este VM)
    return _rutas.where((r) => ids.contains(r.id)).toList();
  }
  // --- FIN DE NUEVO GETTER ---

  // --- D. CONSTRUCTOR (¡LIMPIO!) ---
  RutasVM() {
    _repositorio = getIt<RutasRepositorio>();
  }

  // --- E. MÉTODO DE CARGA INICIAL (AHORA ES INTELIGENTE) ---
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

    if (_pestanaActual == 'Creadas por mí' && rol != 'guia_aprobado' && rol != 'admin') {
      _pestanaActual = 'Recomendadas';
    }
    if (_pestanaActual == 'Guardadas' && esAnonimo) {
      _pestanaActual = 'Recomendadas';
    }

    if (!_estaCargando) {
      cargarRutas();
    }
  }

  // --- ¡MÉTODO ACTUALIZADO! ---
  // ORDEN 1: "Cargar las rutas" (Llama al Repositorio)
  Future<void> cargarRutas() async {
    _estaCargando = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      String tipoFiltro = 'recomendadas';

      // --- ¡CAMBIO DE LÓGICA! ---
      if (_pestanaActual == 'Guardadas') {
        // "Guardadas" ya no es un filtro de API.
        // Pedimos todas las rutas públicas para poder filtrarlas localmente.
        tipoFiltro = 'recomendadas';
      } else if (_pestanaActual == 'Creadas por mí') {
        tipoFiltro = 'creadas_por_mi';
      }
      // --- FIN DEL CAMBIO ---

      _rutas = await _repositorio.obtenerRutas(tipoFiltro);

      // --- ¡FILTRO DEL CEREBRO! ---
      // Si la pestaña es "Guardadas", filtramos la lista
      // usando los IDs del AuthVM (el "Cerebro").
      if (_pestanaActual == 'Guardadas' && (_authVM?.estaLogueado ?? false)) {
        // Necesitamos 'rutasFavoritasIds' del AuthVM
        final idsFavoritos = _authVM!.rutasFavoritasIds;
        _rutas = _rutas.where((r) => idsFavoritos.contains(r.id)).toList();
      }

    } catch (e) {
      _error = e.toString();
    } finally {
      _estaCargando = false;
      _cargaInicialRealizada = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authVM?.removeListener(_actualizarPestanaPorRol);
    _authVM?.removeListener(_onAuthReadyParaRutas);
    super.dispose();
  }

  // --- G. MÉTODOS DE ACCIÓN (¡CONECTADOS AL CEREBRO!) ---

  void cambiarPestana(String nuevaPestana) {
    if (nuevaPestana == _pestanaActual) return;
    _pestanaActual = nuevaPestana;
    _dificultadActual = 'Todos';
    cargarRutas();
  }

  void cambiarDificultad(String nuevaDificultad) {
    if (nuevaDificultad == _dificultadActual) return;
    _dificultadActual = nuevaDificultad;
    notifyListeners();
  }

  // --- ¡MÉTODO CORREGIDO! ---
  Future<void> inscribirseEnRuta(String rutaId) async {
    // 1. Llama al repositorio para actualizar la BD (Mock)
    await _repositorio.inscribirseEnRuta(rutaId);
    // 2. Llama al "Cerebro" para actualizar la UI
    await _authVM?.toggleRutaInscrita(rutaId);
  }

  // --- ¡MÉTODO CORREGIDO! ---
  Future<void> salirDeRuta(String rutaId) async {
    // 1. Llama al repositorio para actualizar la BD (Mock)
    await _repositorio.salirDeRuta(rutaId);
    // 2. Llama al "Cerebro" para actualizar la UI
    await _authVM?.toggleRutaInscrita(rutaId);
  }

  // --- ¡MÉTODO ACTUALIZADO! ---
  Future<void> toggleFavoritoRuta(String rutaId) async {
    // Llama al nuevo método del "Cerebro".
    await _authVM?.toggleRutaFavorita(rutaId);
  }

  // Este método sí debe llamar al repositorio
  Future<void> crearRuta(Map<String, dynamic> datosRuta) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.crearRuta(datosRuta);
      _estaCargando = false;
      notifyListeners();
      await cargarRutas();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      // ¡Relanzamos el error para que la UI lo atrape!
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // --- ¡NUEVAS FUNCIONES CRUD AÑADIDAS! ---

  /// Actualiza una ruta existente en la base de datos.
  Future<void> actualizarRuta(String rutaId, Map<String, dynamic> datosRuta) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.actualizarRuta(rutaId, datosRuta);
      _estaCargando = false;
      notifyListeners();
      // Recargamos las rutas para ver los cambios
      await cargarRutas();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// Cancela una ruta: notifica a usuarios y la oculta (lógica de negocio).
  Future<void> cancelarRuta(String rutaId, String mensaje) async { // <-- ¡ACTUALIZADO!
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.cancelarRuta(rutaId, mensaje); // <-- ¡ACTUALIZADO!
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

  /// Elimina una ruta permanentemente (solo si no tiene inscritos).
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

}
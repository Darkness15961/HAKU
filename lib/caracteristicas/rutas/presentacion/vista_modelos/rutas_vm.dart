// --- PIEDRA 5 (RUTAS): EL "MESERO DE RUTAS" (VERSIÓN COMPLETA Y CORREGIDA) ---
//
// Esta versión es 100% completa.
// 1. Incluye TODOS los imports necesarios.
// 2. Tiene el constructor vacío RutasVM() para coincidir con main.dart.
// 3. Tiene la lógica de carga correcta en cargarDatosIniciales()
//    para arreglar el bug de "sigue cargando".

import 'package:flutter/material.dart';
import '../../dominio/repositorios/rutas_repositorio.dart'; // <-- Import necesario
import '../../dominio/entidades/ruta.dart'; // <-- Import necesario
import '../../../../locator.dart'; // <-- Import necesario
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

  // --- D. CONSTRUCTOR (¡SÚPER LIMPIO!) ---
  // Coincide con el create: (context) => RutasVM() de main.dart
  RutasVM() {
    _repositorio = getIt<RutasRepositorio>();
    // Constructor 100% limpio.
  }

  // --- E. MÉTODO DE CARGA INICIAL (RECIBE EL AUTH_VM) ---
  // La página (rutas_pagina.dart) llamará a este método
  void cargarDatosIniciales(AutenticacionVM authVM) {
    if (_cargaInicialRealizada) return;
    _authVM = authVM;

    // Verificamos si AuthVM está ocupado
    if (_authVM?.estaCargando ?? false) {
      // ¡NO ponemos _estaCargando = true aquí!
      // Solo esperamos a que AuthVM termine.
      _authVM?.addListener(_onAuthReadyParaRutas);
      return;
    }

    // Si AuthVM no está ocupado (Anónimo), iniciamos.
    _iniciarCargaLogica();
  }

  // Listener temporal que se llama CUANDO AuthVM termina
  void _onAuthReadyParaRutas() {
    _iniciarCargaLogica();
    _authVM?.removeListener(_onAuthReadyParaRutas);
  }

  // Método privado para la lógica de carga real
  void _iniciarCargaLogica() {
    // 1. Nos suscribimos al listener permanente
    _authVM?.addListener(_actualizarPestanaPorRol);
    // 2. Ejecutamos la carga por primera vez
    _actualizarPestanaPorRol();
  }

  // Método de Lógica de Roles
  void _actualizarPestanaPorRol() {
    final rol = _authVM?.usuarioActual?.rol;
    final esAnonimo = !(_authVM?.estaLogueado ?? false);

    if (_pestanaActual == 'Creadas por mí' && rol != 'guia_aprobado' && rol != 'admin') {
      _pestanaActual = 'Recomendadas';
    }
    if (_pestanaActual == 'Guardadas' && esAnonimo) {
      _pestanaActual = 'Recomendadas';
    }

    // Ahora que el _estaCargando de RutasVM no está
    // atascado en 'true', este 'if' SÍ funcionará.
    if (!_estaCargando) {
      cargarRutas();
    }
  }

  // ORDEN 1: "Cargar las rutas"
  Future<void> cargarRutas() async {
    _estaCargando = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      String tipoFiltro = 'recomendadas';
      if (_pestanaActual == 'Guardadas') {
        tipoFiltro = 'guardadas';
      } else if (_pestanaActual == 'Creadas por mí') {
        tipoFiltro = 'creadas_por_mi';
      }

      _rutas = await _repositorio.obtenerRutas(tipoFiltro);
    } catch (e) {
      _error = e.toString();
    } finally {
      _estaCargando = false;
      _cargaInicialRealizada = true;
      notifyListeners();
    }
  }

  // --- F. LIMPIEZA DE LISTENERS ---
  @override
  void dispose() {
    _authVM?.removeListener(_actualizarPestanaPorRol);
    _authVM?.removeListener(_onAuthReadyParaRutas);
    super.dispose();
  }

  // --- G. MÉTODOS DE ACCIÓN (Sin cambios) ---
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

  Future<void> inscribirseEnRuta(String rutaId) async {
    try {
      await _repositorio.inscribirseEnRuta(rutaId);
      await cargarRutas();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> salirDeRuta(String rutaId) async {
    try {
      await _repositorio.salirDeRuta(rutaId);
      await cargarRutas();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFavoritoRuta(String rutaId) async {
    try {
      await _repositorio.toggleFavoritoRuta(rutaId);
      await cargarRutas();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

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
    }
  }
}




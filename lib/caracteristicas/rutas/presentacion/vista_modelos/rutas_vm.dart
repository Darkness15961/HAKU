// --- PIEDRA 5 (RUTAS): EL "MESERO DE RUTAS" (SIMPLE Y FUNCIONAL) ---
//
// Revertimos a la versión simple sin banderas.
// La lógica de espera se traslada a la Vista (rutas_pagina.dart).

import 'package:flutter/material.dart';

// (Importaciones)
import '../../dominio/repositorios/rutas_repositorio.dart';
import '../../dominio/entidades/ruta.dart';
import '../../../../locator.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class RutasVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final RutasRepositorio _repositorio;
  final AutenticacionVM? _authVM;

  // --- B. ESTADO DE LA UI ---
  bool _estaCargando = false;
  List<Ruta> _rutas = [];
  String _pestanaActual = 'Recomendadas'; // (Sin eñe)
  String _dificultadActual = 'Todos'; // (Sin eñe)
  String? _error;

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  String get pestanaActual => _pestanaActual;
  String get dificultadActual => _dificultadActual;
  String? get error => _error;

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

  // --- D. CONSTRUCTOR ---
  // El "Mesero" es "perezoso" (lazy).
  RutasVM(this._authVM) {
    _repositorio = getIt<RutasRepositorio>();
    // "Escuchamos" al "Mesero de Seguridad"
    _authVM?.addListener(_actualizarPestanaPorRol);
  }

  // ¡MÉTODO DE CARGA INICIAL (Simple)!
  // Solo ejecuta la lógica de rol y carga.
  void cargarDatosIniciales() {
    _actualizarPestanaPorRol();
  }

  // --- E. MÉTODOS (Las "Órdenes") ---

  // Método de Lógica de Roles
  void _actualizarPestanaPorRol() {
    final rol = _authVM?.usuarioActual?.rol;
    // Chequeo robusto para Anónimo
    final esAnonimo = !(_authVM?.estaLogueado ?? false);

    if (_pestanaActual == 'Creadas por mí' && rol != 'guia_aprobado' && rol != 'admin') {
      _pestanaActual = 'Recomendadas';
    }
    // Si la pestaña actual era "Guardadas" y el usuario ya no está logueado, vamos a Recomendadas
    if (_pestanaActual == 'Guardadas' && esAnonimo) {
      _pestanaActual = 'Recomendadas';
    }

    // (Llamamos a cargarRutas(), que SÍ está bien aquí)
    cargarRutas();
  }

  // ORDEN 1: "Cargar las rutas"
  Future<void> cargarRutas() async {
    _estaCargando = true;
    _error = null;
    Future.microtask(() => notifyListeners()); // Avisamos (de forma segura)

    try {
      String tipoFiltro = 'recomendadas';
      if (_pestanaActual == 'Guardadas') {
        tipoFiltro = 'guardadas';
      } else if (_pestanaActual == 'Creadas por mí') {
        tipoFiltro = 'creadas_por_mi';
      }

      _rutas = await _repositorio.obtenerRutas(tipoFiltro);
      _estaCargando = false;
      notifyListeners();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ... (El resto de métodos quedan igual) ...
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

  Future<bool> crearRuta(Map<String, dynamic> datosRuta) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      await _repositorio.crearRuta(datosRuta);
      _estaCargando = false;
      notifyListeners();
      await cargarRutas();
      return true;
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
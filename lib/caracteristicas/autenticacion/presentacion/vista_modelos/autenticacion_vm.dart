// --- PIEDRA 5 (AUTENTICACIÓN): EL "CEREBRO" (VERSIÓN FINAL) ---
//
// 1. Ahora maneja Lugares Favoritos (ya lo hacía).
// 2. Ahora maneja Rutas Inscritas (ya lo hacía).
// 3. ¡NUEVO! Ahora también maneja Rutas Favoritas.

import 'package:flutter/material.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';
import '../../dominio/entidades/usuario.dart';
import '../../../../locator.dart';

class AutenticacionVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final AutenticacionRepositorio _repositorio;

  // --- B. ESTADO DE LA UI ---
  bool _estaCargando = false;
  Usuario? _usuarioActual;
  String? _error;

  // --- ¡ESTADO DEL CEREBRO! ---
  List<String> _lugaresFavoritosIds = [];
  List<String> _rutasInscritasIds = [];
  List<String> _rutasFavoritasIds = []; // <-- ¡NUEVO!

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  Usuario? get usuarioActual => _usuarioActual;
  String? get error => _error;
  bool get estaLogueado => _usuarioActual != null;

  // --- ¡GETTERS DEL CEREBRO! ---
  List<String> get lugaresFavoritosIds => _lugaresFavoritosIds;
  List<String> get rutasInscritasIds => _rutasInscritasIds;
  List<String> get rutasFavoritasIds => _rutasFavoritasIds; // <-- ¡NUEVO!

  // --- D. CONSTRUCTOR ---
  AutenticacionVM() {
    _repositorio = getIt<AutenticacionRepositorio>();
    verificarEstadoSesion();
  }

  // --- E. MÉTODOS (Las "Órdenes") ---

  Future<void> verificarEstadoSesion() async {
    _estaCargando = true;
    notifyListeners();
    _usuarioActual = await _repositorio.verificarEstadoSesion();

    if (_usuarioActual != null) {
      // (Simulación de carga)
      _lugaresFavoritosIds = ['l2']; // Mock: Lugar 2 es favorito
      _rutasInscritasIds = ['r2'];   // Mock: Ruta 2 está inscrita
      _rutasFavoritasIds = ['r2'];   // Mock: Ruta 2 es favorita
    } else {
      _limpiarDatosUsuario();
    }

    _estaCargando = false;
    notifyListeners();
  }

  Future<bool> iniciarSesion(String email, String password) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActual = await _repositorio.iniciarSesion(email, password);
      // (Simulación de carga)
      _lugaresFavoritosIds = ['l2'];
      _rutasInscritasIds = ['r2'];
      _rutasFavoritasIds = ['r2']; // <-- ¡NUEVO!
      _estaCargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    _estaCargando = true;
    notifyListeners();
    await _repositorio.cerrarSesion();
    _usuarioActual = null;
    _limpiarDatosUsuario(); // Limpiamos el cerebro
    _estaCargando = false;
    notifyListeners();
  }

  // Método privado para limpiar
  void _limpiarDatosUsuario() {
    _lugaresFavoritosIds = [];
    _rutasInscritasIds = [];
    _rutasFavoritasIds = []; // <-- ¡NUEVO!
  }

  // --- MÉTODOS DE ACCIÓN DEL CEREBRO ---

  // ORDEN 6: "Alternar un lugar favorito"
  Future<void> toggleLugarFavorito(String lugarId) async {
    if (_lugaresFavoritosIds.contains(lugarId)) {
      _lugaresFavoritosIds.remove(lugarId);
    } else {
      _lugaresFavoritosIds.add(lugarId);
    }
    // (En un futuro, aquí llamarías al repositorio para guardarlo)
    notifyListeners(); // Avisamos a todos los que escuchan
  }

  // ORDEN 7: "Alternar inscripción a una ruta"
  Future<void> toggleRutaInscrita(String rutaId) async {
    if (_rutasInscritasIds.contains(rutaId)) {
      _rutasInscritasIds.remove(rutaId);
    } else {
      _rutasInscritasIds.add(rutaId);
    }
    notifyListeners();
  }

  // --- ¡NUEVO MÉTODO DE ACCIÓN! ---
  // ORDEN 8: "Alternar una ruta favorita"
  Future<void> toggleRutaFavorita(String rutaId) async {
    if (_rutasFavoritasIds.contains(rutaId)) {
      _rutasFavoritasIds.remove(rutaId);
    } else {
      _rutasFavoritasIds.add(rutaId);
    }
    notifyListeners();
  }
  // --- FIN DE NUEVO MÉTODO ---

  // (El resto de métodos - registrarUsuario, solicitarSerGuia - quedan igual)
  Future<bool> registrarUsuario(
      String nombre, String email, String password, String dni) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActual =
      await _repositorio.registrarUsuario(nombre, email, password, dni);
      _limpiarDatosUsuario(); // Usuario nuevo, listas vacías
      _estaCargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> solicitarSerGuia(
      String experiencia, String rutaCertificado) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.solicitarSerGuia(experiencia, rutaCertificado);
      await verificarEstadoSesion();
      _estaCargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
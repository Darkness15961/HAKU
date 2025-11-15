// --- PIEDRA 5 (AUTENTICACIÓN): EL "CEREBRO" (ACOMPLADO CON ADMIN) ---
//
// (...)
// 3. (ACOMPLADO): Tiene los métodos 'aprobarGuia' y 'rechazarGuia'.
// 4. (¡NUEVO!): Añadida la lógica para 'Gestionar Cuentas'
//    (cargarUsuariosTotales y eliminarUsuario).

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
  List<String> _rutasFavoritasIds = [];

  // --- ¡NUEVO ESTADO DE ADMIN! ---
  List<Usuario> _usuariosPendientes = [];
  bool _estaCargandoAdmin = false;

  // --- ¡AÑADIDO PARA GESTIÓN DE CUENTAS! ---
  List<Usuario> _usuariosTotales = [];
  // --- FIN DE LO AÑADIDO ---

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  Usuario? get usuarioActual => _usuarioActual;
  String? get error => _error;
  bool get estaLogueado => _usuarioActual != null;
  bool get esAdmin => _usuarioActual?.rol == 'admin';

  // --- ¡GETTERS DEL CEREBRO! ---
  List<String> get lugaresFavoritosIds => _lugaresFavoritosIds;
  List<String> get rutasInscritasIds => _rutasInscritasIds;
  List<String> get rutasFavoritasIds => _rutasFavoritasIds;

  // --- ¡NUEVOS GETTERS DE ADMIN! ---
  List<Usuario> get usuariosPendientes => _usuariosPendientes;
  bool get estaCargandoAdmin => _estaCargandoAdmin;

  // --- ¡AÑADIDO PARA GESTIÓN DE CUENTAS! ---
  List<Usuario> get usuariosTotales => _usuariosTotales;
  // --- FIN DE LO AÑADIDO ---

  // --- D. CONSTRUCTOR ---
  AutenticacionVM() {
    _repositorio = getIt<AutenticacionRepositorio>();
    verificarEstadoSesion();
  }

  // --- E. MÉTODOS (Las "Órdenes") ---

  // (¡MÉTODO ACTUALIZADO!)
  Future<void> verificarEstadoSesion() async {
    _estaCargando = true;
    notifyListeners();
    _usuarioActual = await _repositorio.verificarEstadoSesion();

    if (_usuarioActual != null) {
      // (Simulación de carga)
      _lugaresFavoritosIds = ['l2'];
      _rutasInscritasIds = ['r2'];
      _rutasFavoritasIds = ['r2'];

      // ¡NUEVA LÓGICA DE ADMIN!
      if (esAdmin) {
        // Si el usuario es Admin, cargamos las solicitudes
        await cargarSolicitudesPendientes();
        // (No cargamos todas las cuentas aquí,
        // lo haremos en la página específica)
      }

    } else {
      _limpiarDatosUsuario();
    }

    _estaCargando = false;
    notifyListeners();
  }

  // (¡MÉTODO ACTUALIZADO!)
  Future<bool> iniciarSesion(String email, String password) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActual = await _repositorio.iniciarSesion(email, password);

      // (Simulación de carga)
      _lugaresFavoritosIds = ['l2'];
      _rutasInscritasIds = ['r2'];
      _rutasFavoritasIds = ['r2'];

      // ¡NUEVA LÓGICA DE ADMIN!
      if (esAdmin) {
        await cargarSolicitudesPendientes();
      }

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
    _limpiarDatosUsuario();
    _estaCargando = false;
    notifyListeners();
  }

  // Método privado para limpiar
  void _limpiarDatosUsuario() {
    _lugaresFavoritosIds = [];
    _rutasInscritasIds = [];
    _rutasFavoritasIds = [];
    _usuariosPendientes = [];
    _usuariosTotales = []; // <-- ¡ACOMPLADO!
  }

  // --- MÉTODOS DE ACCIÓN DEL CEREBRO (Turista/Guía) ---
  // (Tus métodos toggleLugarFavorito, toggleRutaInscrita,
  //  toggleRutaFavorita, registrarUsuario, solicitarSerGuia
  //  quedan 100% intactos)

  Future<void> toggleLugarFavorito(String lugarId) async {
    if (_lugaresFavoritosIds.contains(lugarId)) {
      _lugaresFavoritosIds.remove(lugarId);
    } else {
      _lugaresFavoritosIds.add(lugarId);
    }
    notifyListeners();
  }

  Future<void> toggleRutaInscrita(String rutaId) async {
    if (_rutasInscritasIds.contains(rutaId)) {
      _rutasInscritasIds.remove(rutaId);
    } else {
      _rutasInscritasIds.add(rutaId);
    }
    notifyListeners();
  }

  Future<void> toggleRutaFavorita(String rutaId) async {
    if (_rutasFavoritasIds.contains(rutaId)) {
      _rutasFavoritasIds.remove(rutaId);
    } else {
      _rutasFavoritasIds.add(rutaId);
    }
    notifyListeners();
  }

  Future<bool> registrarUsuario(
      String nombre, String email, String password, String dni) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActual =
      await _repositorio.registrarUsuario(nombre, email, password, dni);
      _limpiarDatosUsuario();
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

  // --- ¡MÉTODOS DE ACCIÓN DEL ADMIN! (Gestión de Guías) ---

  // ORDEN 6 (Admin): Cargar la lista
  Future<void> cargarSolicitudesPendientes() async {
    if (esAdmin == false) return;
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      _usuariosPendientes = await _repositorio.obtenerSolicitudesPendientes();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }

  // ORDEN 7 (Admin): Aprobar
  Future<void> aprobarGuia(String usuarioId) async {
    if (esAdmin == false) return;
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      await _repositorio.aprobarGuia(usuarioId);
      await cargarSolicitudesPendientes();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }

  // ORDEN 8 (Admin): Rechazar
  Future<void> rechazarGuia(String usuarioId) async {
    if (esAdmin == false) return;
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      await _repositorio.rechazarGuia(usuarioId);
      await cargarSolicitudesPendientes();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }

  // --- ¡AÑADIDO! MÉTODOS DE ACCIÓN DEL ADMIN (Gestión de Cuentas) ---

  // ORDEN 9 (Admin): Cargar todas las cuentas
  Future<void> cargarUsuariosTotales() async {
    if (esAdmin == false) return; // Seguridad
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      // Usaremos un nuevo método del repositorio (que aún no existe)
      _usuariosTotales = await _repositorio.obtenerTodosLosUsuarios();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }

  // ORDEN 10 (Admin): Eliminar una cuenta
  Future<void> eliminarUsuario(String usuarioId) async {
    if (esAdmin == false) return; // Seguridad
    if (usuarioId == _usuarioActual?.id) { // Doble seguridad
      _error = "No puedes eliminarte a ti mismo.";
      notifyListeners();
      return;
    }

    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      // Usaremos un nuevo método del repositorio (que aún no existe)
      await _repositorio.eliminarUsuario(usuarioId);

      // Refrescamos la lista después de eliminar
      // (Lo hacemos manualmente para ahorrar una llamada a la BD)
      _usuariosTotales.removeWhere((u) => u.id == usuarioId);

    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }
// --- FIN DE LO AÑADIDO ---

}
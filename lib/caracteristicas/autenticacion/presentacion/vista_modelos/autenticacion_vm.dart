// --- PIEDRA 5 (AUTENTICACIÓN): EL "CEREBRO" (ACOMPLADO CON ADMIN) ---
//
// 1. (ACOMPLADO): Ahora maneja el rol 'admin' al iniciar sesión.
// 2. (ACOMPLADO): Carga la lista de 'usuariosPendientes' si eres admin.
// 3. (ACOMPLADO): Tiene los métodos 'aprobarGuia' y 'rechazarGuia'.

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
  // --- FIN NUEVO ESTADO ---

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  Usuario? get usuarioActual => _usuarioActual;
  String? get error => _error;
  bool get estaLogueado => _usuarioActual != null;
  bool get esAdmin => _usuarioActual?.rol == 'admin'; // <-- ¡NUEVO GETTER!

  // --- ¡GETTERS DEL CEREBRO! ---
  List<String> get lugaresFavoritosIds => _lugaresFavoritosIds;
  List<String> get rutasInscritasIds => _rutasInscritasIds;
  List<String> get rutasFavoritasIds => _rutasFavoritasIds;

  // --- ¡NUEVOS GETTERS DE ADMIN! ---
  List<Usuario> get usuariosPendientes => _usuariosPendientes;
  bool get estaCargandoAdmin => _estaCargandoAdmin;
  // --- FIN NUEVOS GETTERS ---

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
    _usuariosPendientes = []; // <-- ¡ACOMPLADO!
  }

  // --- MÉTODOS DE ACCIÓN DEL CEREBRO (Turista/Guía) ---
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

  // (El resto de métodos - registrarUsuario, solicitarSerGuia - quedan igual)
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
      // Actualizamos el estado para que el rol cambie a 'guia_pendiente'
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

  // --- ¡NUEVOS MÉTODOS DE ACCIÓN DEL ADMIN! (ACOMPLADO) ---

  // ORDEN 6 (Admin): Cargar la lista
  Future<void> cargarSolicitudesPendientes() async {
    if (esAdmin == false) return; // Seguridad
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
    if (esAdmin == false) return; // Seguridad
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      await _repositorio.aprobarGuia(usuarioId);
      // Refrescamos la lista
      await cargarSolicitudesPendientes();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }

  // ORDEN 8 (Admin): Rechazar
  Future<void> rechazarGuia(String usuarioId) async {
    if (esAdmin == false) return; // Seguridad
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      await _repositorio.rechazarGuia(usuarioId);
      // Refrescamos la lista
      await cargarSolicitudesPendientes();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }
// --- FIN DE NUEVOS MÉTODOS ---

}
import 'package:flutter/material.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';
import '../../dominio/entidades/usuario.dart';
import '../../../../locator.dart';

class AutenticacionVM extends ChangeNotifier {
  late final AutenticacionRepositorio _repositorio;

  bool _estaCargando = false;
  Usuario? _usuarioActual;
  String? _error;

  List<String> _lugaresFavoritosIds = [];
  List<String> _rutasInscritasIds = [];
  List<String> _rutasFavoritasIds = [];

  List<Usuario> _usuariosPendientes = [];
  bool _estaCargandoAdmin = false;

  List<Usuario> _usuariosTotales = [];

  bool get estaCargando => _estaCargando;
  Usuario? get usuarioActual => _usuarioActual;
  String? get error => _error;
  bool get estaLogueado => _usuarioActual != null;
  bool get esAdmin => _usuarioActual?.rol == 'admin';

  List<String> get lugaresFavoritosIds => _lugaresFavoritosIds;
  List<String> get rutasInscritasIds => _rutasInscritasIds;
  List<String> get rutasFavoritasIds => _rutasFavoritasIds;

  List<Usuario> get usuariosPendientes => _usuariosPendientes;
  bool get estaCargandoAdmin => _estaCargandoAdmin;

  List<Usuario> get usuariosTotales => _usuariosTotales;

  AutenticacionVM() {
    _repositorio = getIt<AutenticacionRepositorio>();
    verificarEstadoSesion();
  }

  Future<void> verificarEstadoSesion() async {
    _estaCargando = true;
    notifyListeners();
    _usuarioActual = await _repositorio.verificarEstadoSesion();

    if (_usuarioActual != null) {
      _lugaresFavoritosIds = ['l2'];
      _rutasInscritasIds = ['r2'];
      _rutasFavoritasIds = ['r2'];

      if (esAdmin) {
        await cargarSolicitudesPendientes();
      }
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

      _lugaresFavoritosIds = ['l2'];
      _rutasInscritasIds = ['r2'];
      _rutasFavoritasIds = ['r2'];

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

  void _limpiarDatosUsuario() {
    _lugaresFavoritosIds = [];
    _rutasInscritasIds = [];
    _rutasFavoritasIds = [];
    _usuariosPendientes = [];
    _usuariosTotales = [];
  }

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
    String nombre,
    String email,
    String password,
    String dni,
  ) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();
    try {
      _usuarioActual = await _repositorio.registrarUsuario(
        nombre,
        email,
        password,
        dni,
      );
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
    String experiencia,
    String rutaCertificado,
  ) async {
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

  Future<void> cargarUsuariosTotales() async {
    if (esAdmin == false) return;
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      _usuariosTotales = await _repositorio.obtenerTodosLosUsuarios();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }

  Future<void> eliminarUsuario(String usuarioId) async {
    if (esAdmin == false) return;
    _estaCargandoAdmin = true;
    notifyListeners();
    try {
      await _repositorio.eliminarUsuario(usuarioId);
      await cargarUsuariosTotales();
    } catch (e) {
      _error = e.toString();
    }
    _estaCargandoAdmin = false;
    notifyListeners();
  }

  Future<void> actualizarFotoPerfil(String pathImagen) async {
    _estaCargando = true;
    notifyListeners();
    try {
      await _repositorio.actualizarFotoPerfil(_usuarioActual!.id, pathImagen);
      _usuarioActual = _usuarioActual!.copyWith(urlFotoPerfil: pathImagen);
    } catch (e) {
      _error = e.toString();
    }
    _estaCargando = false;
    notifyListeners();
  }

  Future<void> cambiarPassword(String newPassword) async {
    _estaCargando = true;
    notifyListeners();
    try {
      await _repositorio.cambiarPassword(newPassword);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  void actualizarFavoritos(List<String> nuevosIds) {
    _lugaresFavoritosIds = nuevosIds;
    notifyListeners();
  }

  Future<bool> iniciarSesionConGoogle() async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuarioActual = await _repositorio.iniciarSesionConGoogle();

      _lugaresFavoritosIds = ['l2'];
      _rutasInscritasIds = ['r2'];
      _rutasFavoritasIds = ['r2'];

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
}

import 'package:flutter/material.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';
import '../../dominio/entidades/usuario.dart';
import '../../../../locator.dart';

// --- IMPORTS PARA GOOGLE Y SUPABASE ---
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Getters
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
      // Valores iniciales de prueba (puedes cambiarlos por datos de DB)
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

  // --- FAVORITOS ---
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

  // --- REGISTRO MANUAL (Mejorado para Producción) ---
  Future<bool> registrarUsuario(
      String seudonimo,
      String email,
      String password,
      String dni,
      ) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Registro en Supabase Auth con Metadata para el Trigger SQL
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': seudonimo},
      );

      if (res.user != null) {
        // 2. Intento de actualización de DNI con seguro ante latencia del Trigger
        try {
          await Supabase.instance.client
              .from('perfiles')
              .update({'dni': dni})
              .eq('id', res.user!.id);
        } catch (e) {
          print("Aviso: El perfil se está creando vía Trigger SQL...");
        }

        // 3. Manejo de sesión: Si requiere confirmación de email, session será null
        if (res.session != null) {
          _usuarioActual = await _repositorio.verificarEstadoSesion();
        } else {
          _usuarioActual = null;
          _limpiarDatosUsuario();
        }
      }

      _estaCargando = false;
      notifyListeners();
      return true;

    } on AuthException catch (e) {
      // Captura específica para mostrar el SnackBar naranja en la vista
      if (e.code == 'user_already_exists' || e.message.contains('already registered')) {
        _error = 'user_already_exists';
      } else {
        _error = 'Error: ${e.message}';
      }
      _estaCargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Ocurrió un error inesperado.';
      _estaCargando = false;
      notifyListeners();
      return false;
    }
  }

  // --- LOGIN CON GOOGLE (Mejorado para Fusión de Cuentas) ---
  Future<bool> iniciarSesionGoogle() async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      const webClientId = '229829788638-qu38q760qutvcaa1hmtg327mkthl7sng.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);

      await googleSignIn.signOut(); // Limpia caché para forzar selección de cuenta
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _estaCargando = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;

      final AuthResponse res = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (res.user != null) {
        await verificarEstadoSesion();
      }

      _estaCargando = false;
      notifyListeners();
      return true;

    } catch (e) {
      _estaCargando = false;
      _error = "Error Google: $e";
      notifyListeners();
      return false;
    }
  }

  // --- LÓGICA DE ADMINISTRACIÓN (Se mantiene intacta) ---
  Future<bool> solicitarSerGuia(String experiencia, String rutaCertificado) async {
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
}
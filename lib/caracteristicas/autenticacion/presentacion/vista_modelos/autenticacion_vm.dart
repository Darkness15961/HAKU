import 'package:flutter/material.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';
import '../../dominio/entidades/usuario.dart';
import '../../../../locator.dart';

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

  bool get tieneNombreCompleto {
    if (_usuarioActual == null) return false;
    return _usuarioActual!.nombres != null &&
        _usuarioActual!.apellidoPaterno != null &&
        _usuarioActual!.apellidoMaterno != null &&
        _usuarioActual!.nombres!.isNotEmpty &&
        _usuarioActual!.apellidoPaterno!.isNotEmpty &&
        _usuarioActual!.apellidoMaterno!.isNotEmpty;
  }

  AutenticacionVM() {
    _repositorio = getIt<AutenticacionRepositorio>();
    verificarEstadoSesion();
  }

  Future<void> verificarEstadoSesion() async {
    _estaCargando = true;
    notifyListeners();
    _usuarioActual = await _repositorio.verificarEstadoSesion();

    if (_usuarioActual != null) {
      // CORRECCIÓN: Usamos los datos REALES del usuario, no listas inventadas ['r2']
      _rutasInscritasIds = List.from(_usuarioActual!.rutasInscritas);

      // Favoritos los dejamos vacíos por ahora (hasta que implementes su backend)
      _lugaresFavoritosIds = [];
      _rutasFavoritasIds = [];

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

      // CORRECCIÓN: Aquí también cargamos los datos reales al loguearse
      if (_usuarioActual != null) {
        _rutasInscritasIds = List.from(_usuarioActual!.rutasInscritas);
      }
      _lugaresFavoritosIds = [];
      _rutasFavoritasIds = [];

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

  // Métodos Toggle: Actualizan la lista en memoria para que la UI reaccione rápido
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
      String seudonimo,
      String email,
      String password,
      String documentoIdentidad,
      String tipoDocumento,
      String? nombres,
      String? apellidoPaterno,
      String? apellidoMaterno,
      ) async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuarioActual = await _repositorio.registrarUsuario(
        seudonimo,
        email,
        password,
        documentoIdentidad,
        tipoDocumento,
        nombres,
        apellidoPaterno,
        apellidoMaterno,
      );
      _limpiarDatosUsuario(); // Un usuario nuevo empieza limpio
      _estaCargando = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      final mensaje = e.message.toLowerCase();
      if (e.code == 'user_already_exists' ||
          mensaje.contains('already registered') ||
          mensaje.contains('ya esta registrado')) {
        _error = '⚠️ Este correo ya tiene cuenta. Intenta iniciar sesión.';
      } else {
        _error = 'Error de registro: ${e.message}';
      }
      _estaCargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      final mensajeError = e.toString().toLowerCase();
      if (mensajeError.contains('already') ||
          mensajeError.contains('exists') ||
          mensajeError.contains('unique') ||
          mensajeError.contains('constraint')) {
        _error = '⚠️ Este correo ya tiene cuenta. Intenta iniciar sesión.';
      } else {
        _error = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
      }
      _estaCargando = false;
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

  Future<bool> completarPerfil({
    required String dni,
    required String tipoDocumento,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    if (_usuarioActual == null) return false;

    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      await _repositorio.completarPerfil(
        usuarioId: _usuarioActual!.id,
        dni: dni,
        tipoDocumento: tipoDocumento,
        nombres: nombres,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
      );

      _usuarioActual = _usuarioActual!.copyWith(
        dni: dni,
        nombres: nombres,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
      );

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

  Future<bool> actualizarSeudonimo(String nuevoSeudonimo) async {
    if (_usuarioActual == null) return false;

    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      await _repositorio.actualizarSeudonimo(
        _usuarioActual!.id,
        nuevoSeudonimo,
      );

      _usuarioActual = _usuarioActual!.copyWith(seudonimo: nuevoSeudonimo);

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

  Future<void> cambiarPasswordConValidacion(
      String passwordActual,
      String passwordNueva,
      ) async {
    if (_usuarioActual == null) {
      throw Exception('No hay usuario autenticado');
    }

    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      final email = _usuarioActual!.email;
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: passwordActual,
        );
      } catch (e) {
        throw Exception('La contraseña actual es incorrecta');
      }

      await _repositorio.cambiarPassword(passwordNueva);

      _estaCargando = false;
      notifyListeners();
    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> iniciarSesionGoogle() async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      const webClientId =
          '229829788638-qu38q760qutvcaa1hmtg327mkthl7sng.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _estaCargando = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No se encontró el ID Token de Google.';
      }

      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (res.user != null) {
        await _sincronizarPerfilGoogle(res.user!);
        await verificarEstadoSesion(); // Esto carga también las rutas inscritas
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

  Future<void> _sincronizarPerfilGoogle(User supabaseUser) async {
    final datosExistentes = await Supabase.instance.client
        .from('perfiles')
        .select()
        .eq('id', supabaseUser.id)
        .maybeSingle();

    final metadata = supabaseUser.userMetadata;

    final datosPerfil = {
      'id': supabaseUser.id,
      'email': supabaseUser.email,
      'seudonimo':
      datosExistentes?['seudonimo'] ??
          metadata?['full_name'] ??
          'Usuario Google',
      'url_foto_perfil':
      datosExistentes?['url_foto_perfil'] ?? metadata?['avatar_url'],
      'rol': datosExistentes?['rol'] ?? 'turista',
      'dni': datosExistentes?['dni'],
      'nombres': datosExistentes?['nombres'],
      'apellido_paterno': datosExistentes?['apellido_paterno'],
      'apellido_materno': datosExistentes?['apellido_materno'],
    };

    await Supabase.instance.client.from('perfiles').upsert(datosPerfil);
  }
}
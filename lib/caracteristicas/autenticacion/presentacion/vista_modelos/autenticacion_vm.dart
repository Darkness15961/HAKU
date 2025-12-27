import 'package:flutter/material.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';
import '../../dominio/entidades/usuario.dart';
import '../../../../locator.dart';

// --- NUEVOS IMPORTS PARA GOOGLE (AGREGA ESTOS DOS) ---
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
      _limpiarDatosUsuario();
      _estaCargando = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      // 1. Capturamos error oficial de Supabase
      if (e.code == 'user_already_exists') {
        _error = '⚠️ Este correo ya está registrado. Prueba iniciar sesión.';
      } else {
        _error = 'Error: ${e.message}';
      }
      _estaCargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      // 2. Capturamos error genérico "Blindado"
      // Si por alguna razón el error llega como texto (String), lo revisamos también:
      final mensajeError = e.toString().toLowerCase();

      if (mensajeError.contains('user_already_exists') ||
          mensajeError.contains('registered')) {
        _error = '⚠️ Este correo ya tiene cuenta. Intenta iniciar sesión.';
      } else {
        _error = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
      }

      print("❌ Error crudo: $e"); // Esto saldrá en tu consola para debug
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

  // ===========================================================================
  //  🔽 AQUÍ COMIENZA LO NUEVO: LÓGICA DE GOOGLE (COPIA DESDE AQUÍ HACIA ABAJO)
  // ===========================================================================

  Future<bool> iniciarSesionGoogle() async {
    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Configuración: TU CLIENT ID DE WEB
      // (Reemplaza esto con el que copiaste de Google Cloud Console)
      const webClientId =
          '229829788638-qu38q760qutvcaa1hmtg327mkthl7sng.apps.googleusercontent.com';

      // 2. Google Sign In nativo
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      await googleSignIn.signOut();
      // 👆👆 Esto fuerza a que siempre te pregunte qué cuenta usar 👆👆

      final googleUser = await googleSignIn.signIn();

      // Si el usuario canceló el login en la ventanita
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

      // 3. Login en Supabase (Nivel 1: Auth)
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );

      // 4. Sincronización Manual (Nivel 2: Tabla Perfiles)
      if (res.user != null) {
        await _sincronizarPerfilGoogle(res.user!);

        // 5. ¡TRUCO! Reutilizamos tu lógica existente para cargar el usuario en la app
        // Esto asegura que _usuarioActual se llene con el formato correcto de tu Entidad
        await verificarEstadoSesion();
      }

      _estaCargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _estaCargando = false;
      _error = "Error Google: $e";
      print("❌ Error en Google Login: $e");
      notifyListeners();
      return false;
    }
  }

  // Función privada para hacer el UPSERT (Mezcla de Insertar y Actualizar)
  Future<void> _sincronizarPerfilGoogle(User supabaseUser) async {
    final metadata = supabaseUser.userMetadata;

    // Preparamos los datos
    final datosPerfil = {
      'id': supabaseUser.id, // Vital para vincular
      'email': supabaseUser.email,
      'nombre': metadata?['full_name'] ?? 'Usuario Google',
      'url_foto_perfil': metadata?['avatar_url'],
      'rol': 'turista', // Rol por defecto
      // 'dni': null,                     // Google no da DNI, lo dejamos tal cual
    };

    // Upsert: Si existe actualiza, si no existe crea.
    await Supabase.instance.client.from('perfiles').upsert(datosPerfil);
  }
}

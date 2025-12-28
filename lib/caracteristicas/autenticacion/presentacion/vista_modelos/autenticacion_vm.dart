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
        // 1. Captura OFICIAL de Supabase
        // A veces el error no viene en el 'code', sino en el 'message'
        final mensaje = e.message.toLowerCase();

        if (e.code == 'user_already_exists' ||
            mensaje.contains('already registered') ||
            mensaje.contains('ya esta registrado')) {

          // MENSAJE PRO: Damos la pista de Google
          _error = '⚠️ Este correo ya tiene cuenta (quizás usaste Google). Intenta iniciar sesión(o la opción: olvidaste contraseña).';

        } else {
          _error = 'Error de registro: ${e.message}';
        }

        _estaCargando = false;
        notifyListeners();
        return false;

      } catch (e) {
        // 2. Captura GENÉRICA "DETECTIVA" 🕵️‍♂️
        final mensajeError = e.toString().toLowerCase();

        // Imprimimos el error para que tú lo veas (opcional)
        print("❌ Error detectado: $mensajeError");

        if (mensajeError.contains('already') ||
            mensajeError.contains('exists') ||
            mensajeError.contains('registrado') ||
            mensajeError.contains('duplicate') ||
            mensajeError.contains('unique') ||
            mensajeError.contains('violation') ||
            mensajeError.contains('pk_users') ||
            // --- AQUÍ ESTÁN LAS NUEVAS VACUNAS CONTRA EL ERROR 23503 ---
            mensajeError.contains('foreign key') ||
            mensajeError.contains('constraint') ||
            mensajeError.contains('23503')) {

          _error = '⚠️ Este correo ya tiene cuenta (quizás usaste Google). Intenta iniciar sesión(o la opción: olvidaste contraseña).';

        } else {
          // Si sale algo que NO es lo anterior, mostramos el error técnico
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

    // --- LOGIN CON GOOGLE (Implementación de Jhon) ---
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


    // Función privada INTELIGENTE (Respeta tus datos antiguos)
    Future<void> _sincronizarPerfilGoogle(User supabaseUser) async {
      // 1. CONSULTA: ¿Ya existe este usuario en mi base de datos?
      final datosExistentes = await Supabase.instance.client
          .from('perfiles')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle();

      final metadata = supabaseUser.userMetadata;

      // 2. PREPARACIÓN: Usamos tus datos viejos si existen
      final datosPerfil = {
        'id': supabaseUser.id,
        'email': supabaseUser.email,

        // AQUÍ ESTÁ EL TRUCO:
        // Si ya tienes seudónimo (datosExistentes), ÚSALO. Si no, usa el de Google.
        'seudonimo': datosExistentes?['seudonimo'] ?? metadata?['full_name'] ?? 'Usuario Google',

        // Lo mismo con la foto
        'url_foto_perfil': datosExistentes?['url_foto_perfil'] ?? metadata?['avatar_url'],

        // Si ya eras Admin o Guía, no te baja de rango
        'rol': datosExistentes?['rol'] ?? 'turista',

        // Mantenemos otros datos personales para que no se borren
        'dni': datosExistentes?['dni'],
        'nombres': datosExistentes?['nombres'],
        'apellido_paterno': datosExistentes?['apellido_paterno'],
        'apellido_materno': datosExistentes?['apellido_materno'],
      };

      // 3. ACTUALIZACIÓN: Ahora sí guardamos sin miedo
      await Supabase.instance.client.from('perfiles').upsert(datosPerfil);
    }

    /*
    // Función privada para hacer el UPSERT (Mezcla de Insertar y Actualizar)
    Future<void> _sincronizarPerfilGoogle(User supabaseUser) async {
      final metadata = supabaseUser.userMetadata;

      // Preparamos los datos
      final datosPerfil = {
        'id': supabaseUser.id, // Vital para vincular
        'email': supabaseUser.email,
        'seudonimo': metadata?['full_name'] ?? 'Usuario Google',
        'url_foto_perfil': metadata?['avatar_url'],
        'rol': 'turista', // Rol por defecto
        // 'dni': null,                     // Google no da DNI, lo dejamos tal cual
      };

      // Upsert: Si existe actualiza, si no existe crea.

      await Supabase.instance.client.from('perfiles').upsert(datosPerfil);
    }

     */
  }

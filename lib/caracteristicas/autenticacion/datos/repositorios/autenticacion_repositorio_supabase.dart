import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';

class AutenticacionRepositorioSupabase implements AutenticacionRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- NUEVO: Helper para traer las maletas (inscripciones) ---
  Future<List<String>> _obtenerRutasInscritas(String userId) async {
    try {
      final data = await _supabase
          .from('inscripciones')
          .select('ruta_id')
          .eq('usuario_id', userId);

      // Convertimos la respuesta en una lista de Strings (IDs de rutas)
      return (data as List).map((e) => e['ruta_id'].toString()).toList();
    } catch (e) {
      // Si falla (ej. tabla vacía o error de red), devolvemos lista vacía para no bloquear el login
      print('⚠️ Error obteniendo inscripciones: $e');
      return [];
    }
  }

  @override
  Future<Usuario> iniciarSesion(String email, String password) async {
    try {
      // 1. Autenticación con Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) throw Exception('Error al iniciar sesión');

      // 2. Obtener datos extra de la tabla 'perfiles'
      final perfilData = await _supabase
          .from('perfiles')
          .select()
          .eq('id', res.user!.id)
          .single();

      // 3. NUEVO: Obtener las rutas inscritas
      final rutasInscritas = await _obtenerRutasInscritas(res.user!.id);

      // 4. Construir y devolver el Usuario con TODO cargado
      return _mapPerfilToUsuario(perfilData, res.session!.accessToken, rutasInscritas);
    } catch (e) {
      throw Exception(_traducirErrorAuth(e.toString()));
    }
  }

  @override
  Future<Usuario> registrarUsuario(
      String seudonimo,
      String email,
      String password,
      String documentoIdentidad,
      String tipoDocumento,
      String? nombres,
      String? apellidoPaterno,
      String? apellidoMaterno,
      ) async {
    // 1. Crear usuario en Supabase Auth
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'seudonimo': seudonimo,
        'full_name': seudonimo,
      },
    );

    if (res.user == null) throw Exception('Error al registrarse');

    // 2. Crear registro en tabla 'perfiles' (Upsert por seguridad)
    final nuevoPerfil = {
      'id': res.user!.id,
      'seudonimo': seudonimo,
      'email': email,
      'dni': documentoIdentidad,
      'tipo_documento': tipoDocumento,
      'nombres': nombres,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'rol': 'turista',
      'solicitud_estado': 'no_iniciado',
    };

    await _supabase.from('perfiles').upsert(nuevoPerfil);

    // Al registrarse, la lista de inscripciones está vacía por defecto
    return _mapPerfilToUsuario(nuevoPerfil, res.session?.accessToken ?? '', []);
  }

  @override
  Future<Usuario?> verificarEstadoSesion() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Traer perfil
      final data = await _supabase
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .single();

      // 2. NUEVO: Traer inscripciones (Importante para cuando abres la app ya logueado)
      final rutasInscritas = await _obtenerRutasInscritas(user.id);

      return _mapPerfilToUsuario(
        data,
        _supabase.auth.currentSession?.accessToken ?? '',
        rutasInscritas,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Usuario> iniciarSesionConGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://fnedjdwdtidqspshovjn.supabase.co/auth/v1/callback',
      );

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Error al iniciar sesión con Google');

      final perfilData = await _supabase
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // NUEVO: Traer inscripciones
      final rutasInscritas = await _obtenerRutasInscritas(user.id);

      if (perfilData == null) {
        final nombreCompleto =
            user.userMetadata?['full_name'] ??
                user.userMetadata?['name'] ??
                user.email?.split('@')[0] ??
                'Usuario';

        final nuevoPerfil = {
          'id': user.id,
          'nombre': nombreCompleto,
          'email': user.email!,
          'rol': 'turista',
          'solicitud_estado': 'no_iniciado',
          'url_foto_perfil':
          user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
        };

        await _supabase.from('perfiles').insert(nuevoPerfil);
        return _mapPerfilToUsuario(
          nuevoPerfil,
          _supabase.auth.currentSession?.accessToken ?? '',
          rutasInscritas, // Probablemente vacía, pero correcto
        );
      }

      return _mapPerfilToUsuario(
        perfilData,
        _supabase.auth.currentSession?.accessToken ?? '',
        rutasInscritas,
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: ${e.toString()}');
    }
  }

  // --- Helpers y Métodos Admin ---

  String _traducirErrorAuth(String errorOriginal) {
    final errorLower = errorOriginal.toLowerCase();
    if (errorLower.contains('email not confirmed')) return '⚠️ Debes confirmar tu correo. Revisa tu bandeja.';
    if (errorLower.contains('invalid login credentials') || errorLower.contains('invalid_credentials')) return 'Contraseña o correo incorrectos.';
    if (errorLower.contains('user not found')) return 'No existe una cuenta con este correo.';
    if (errorLower.contains('network') || errorLower.contains('connection')) return 'Sin conexión.';
    return 'No pudimos iniciar sesión. Verifica tus datos.';
  }

  // ACTUALIZADO: Ahora recibe la lista de rutas inscritas
  Usuario _mapPerfilToUsuario(Map<String, dynamic> data, String token, List<String> rutasInscritas) {
    return Usuario(
      id: data['id'],
      seudonimo: data['seudonimo'] ?? data['nombres'] ?? data['nombre'] ?? '',
      nombres: data['nombres'],
      apellidoPaterno: data['apellido_paterno'],
      apellidoMaterno: data['apellido_materno'],
      tipoDocumento: data['tipo_documento'],
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'turista',
      dni: data['dni'],
      urlFotoPerfil: data['url_foto_perfil'],
      solicitudEstado: data['solicitud_estado'],
      solicitudExperiencia: data['solicitud_experiencia'],
      solicitudCertificadoUrl: data['solicitud_certificado_url'],
      token: token,
      // IMPORTANTE: Aquí asignamos la lista que trajimos de la BD
      // Asegúrate que tu entidad Usuario tenga este parámetro en el constructor.
      // Si se llama diferente (ej: 'inscripciones'), cámbialo aquí.
      rutasInscritas: rutasInscritas,
    );
  }

  // --- El resto de métodos se mantienen igual, no afectan el login ---

  @override
  Future<void> solicitarSerGuia(String experiencia, String rutaCertificado) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('perfiles').update({
      'solicitud_experiencia': experiencia,
      'solicitud_certificado_url': rutaCertificado,
      'solicitud_estado': 'pendiente',
      'rol': 'guia_pendiente',
    }).eq('id', userId);
  }

  @override
  Future<List<Usuario>> obtenerSolicitudesPendientes() async {
    final data = await _supabase.from('perfiles').select().eq('solicitud_estado', 'pendiente');
    return (data as List).map((json) => _mapPerfilToUsuario(json, '', [])).toList();
  }

  @override
  Future<void> aprobarGuia(String usuarioId) async {
    await _supabase.from('perfiles').update({'rol': 'guia_aprobado', 'solicitud_estado': 'aprobado'}).eq('id', usuarioId);
  }

  @override
  Future<void> rechazarGuia(String usuarioId) async {
    await _supabase.from('perfiles').update({'rol': 'turista', 'solicitud_estado': 'rechazado'}).eq('id', usuarioId);
  }

  @override
  Future<void> cerrarSesion() async => await _supabase.auth.signOut();

  @override
  Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    final data = await _supabase.from('perfiles').select();
    return (data as List).map((json) => _mapPerfilToUsuario(json, '', [])).toList();
  }

  @override
  Future<void> eliminarUsuario(String usuarioId) async {
    await _supabase.from('perfiles').delete().eq('id', usuarioId);
  }

  @override
  Future<void> actualizarFotoPerfil(String usuarioId, String nuevaFotoUrl) async {
    await _supabase.from('perfiles').update({'url_foto_perfil': nuevaFotoUrl}).eq('id', usuarioId);
  }

  @override
  Future<void> cambiarPassword(String nuevaPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: nuevaPassword));
  }

  @override
  Future<void> actualizarSeudonimo(String usuarioId, String nuevoSeudonimo) async {
    await _supabase.from('perfiles').update({'seudonimo': nuevoSeudonimo}).eq('id', usuarioId);
  }

  @override
  Future<void> completarPerfil({
    required String usuarioId,
    required String dni,
    required String tipoDocumento,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    final perfilActual = await _supabase.from('perfiles').select('dni').eq('id', usuarioId).single();
    if (perfilActual['dni'] != null && perfilActual['dni'].toString().isNotEmpty) {
      if (perfilActual['dni'].toString() != dni) {
        throw Exception('El DNI ya está registrado y no se puede modificar');
      }
    }
    await _supabase.from('perfiles').update({
      'dni': dni,
      'tipo_documento': tipoDocumento,
      'nombres': nombres,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
    }).eq('id', usuarioId);
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';

class AutenticacionRepositorioSupabase implements AutenticacionRepositorio {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Usuario> iniciarSesion(String email, String password) async {
    try {
      // 1. Autenticación con Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) throw Exception('Error al iniciar sesión');

      // 2. Obtener datos extra de la tabla 'perfiles' (Rol, DNI, etc.)
      final perfilData = await _supabase
          .from('perfiles')
          .select()
          .eq('id', res.user!.id)
          .single();

      // 3. Construir y devolver el Usuario
      return _mapPerfilToUsuario(perfilData, res.session!.accessToken);
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
    );

    if (res.user == null) throw Exception('Error al registrarse');

    // 2. Crear registro en tabla 'perfiles' (Tu tabla personalizada)
    final nuevoPerfil = {
      'id': res.user!.id, // Vinculamos con el ID de Auth
      'seudonimo': seudonimo,
      'email': email,
      'dni': documentoIdentidad,
      'tipo_documento': tipoDocumento, // NUEVO
      'nombres': nombres, // NUEVO
      'apellido_paterno': apellidoPaterno, // NUEVO
      'apellido_materno': apellidoMaterno, // NUEVO
      'rol': 'turista', // Por defecto
      'solicitud_estado': 'no_iniciado',
    };

    await _supabase.from('perfiles').insert(nuevoPerfil);

    return _mapPerfilToUsuario(nuevoPerfil, res.session?.accessToken ?? '');
  }

  // Helper para traducir errores de autenticación al español
  String _traducirErrorAuth(String errorOriginal) {
    final errorLower = errorOriginal.toLowerCase();

    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid_credentials')) {
      return 'Credenciales de inicio de sesión inválidas';
    }

    if (errorLower.contains('email not confirmed')) {
      return 'El correo electrónico no ha sido confirmado';
    }

    if (errorLower.contains('user not found')) {
      return 'Usuario no encontrado';
    }

    if (errorLower.contains('invalid email')) {
      return 'Correo electrónico inválido';
    }

    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Error de conexión. Verifica tu internet';
    }

    if (errorLower.contains('too many requests')) {
      return 'Demasiados intentos. Intenta más tarde';
    }

    // Si no coincide con ningún error conocido, devolver mensaje genérico
    return 'Error al iniciar sesión. Verifica tus credenciales';
  }

  // Helper para convertir JSON de BD a Entidad Usuario
  Usuario _mapPerfilToUsuario(Map<String, dynamic> data, String token) {
    return Usuario(
      id: data['id'],
      seudonimo:
          data['seudonimo'] ??
          data['nombres'] ??
          data['nombre'] ??
          '', // Intenta 'seudonimo' primero
      nombres: data['nombres'], // NUEVO - puede ser null
      apellidoPaterno: data['apellido_paterno'], // NUEVO - puede ser null
      apellidoMaterno: data['apellido_materno'], // NUEVO - puede ser null
      tipoDocumento: data['tipo_documento'], // NUEVO - puede ser null
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'turista',
      dni: data['dni'],
      urlFotoPerfil: data['url_foto_perfil'],
      solicitudEstado: data['solicitud_estado'],
      solicitudExperiencia: data['solicitud_experiencia'],
      solicitudCertificadoUrl: data['solicitud_certificado_url'],
      token: token,
    );
  }

  // --- MÉTODOS DE GESTIÓN DE GUÍAS (Admin) ---

  @override
  Future<void> solicitarSerGuia(
    String experiencia,
    String rutaCertificado,
  ) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('perfiles')
        .update({
          'solicitud_experiencia': experiencia,
          'solicitud_certificado_url': rutaCertificado,
          'solicitud_estado': 'pendiente',
          'rol': 'guia_pendiente', // Cambia temporalmente
        })
        .eq('id', userId);
  }

  @override
  Future<List<Usuario>> obtenerSolicitudesPendientes() async {
    final data = await _supabase
        .from('perfiles')
        .select()
        .eq('solicitud_estado', 'pendiente');

    return (data as List).map((json) => _mapPerfilToUsuario(json, '')).toList();
  }

  @override
  Future<void> aprobarGuia(String usuarioId) async {
    await _supabase
        .from('perfiles')
        .update({
          'rol': 'guia_aprobado', // ¡Rol actualizado!
          'solicitud_estado': 'aprobado',
        })
        .eq('id', usuarioId);
  }

  @override
  Future<void> rechazarGuia(String usuarioId) async {
    await _supabase
        .from('perfiles')
        .update({
          'rol': 'turista', // Vuelve a turista
          'solicitud_estado': 'rechazado',
        })
        .eq('id', usuarioId);
  }

  @override
  Future<void> cerrarSesion() async => await _supabase.auth.signOut();

  @override
  Future<Usuario?> verificarEstadoSesion() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    // Si hay sesión, traemos el perfil actualizado
    try {
      final data = await _supabase
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .single();
      return _mapPerfilToUsuario(
        data,
        _supabase.auth.currentSession?.accessToken ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    final data = await _supabase.from('perfiles').select();
    return (data as List).map((json) => _mapPerfilToUsuario(json, '')).toList();
  }

  @override
  Future<void> eliminarUsuario(String usuarioId) async {
    // Ojo: Esto solo borra de 'perfiles'. Para borrar de Auth se requiere una Edge Function o hacerlo desde el dashboard
    await _supabase.from('perfiles').delete().eq('id', usuarioId);
  }

  @override
  Future<void> actualizarFotoPerfil(
    String usuarioId,
    String nuevaFotoUrl,
  ) async {
    await _supabase
        .from('perfiles')
        .update({'url_foto_perfil': nuevaFotoUrl})
        .eq('id', usuarioId);
  }

  @override
  Future<void> cambiarPassword(String nuevaPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: nuevaPassword));
  }

  @override
  Future<Usuario> iniciarSesionConGoogle() async {
    try {
      // 1. Iniciar sesión con Google usando Supabase OAuth
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://fnedjdwdtidqspshovjn.supabase.co/auth/v1/callback',
      );

      // 2. Esperar a que el usuario complete el flujo de OAuth
      // El navegador se abrirá automáticamente

      // 3. Verificar si el usuario actual existe después del OAuth
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Error al iniciar sesión con Google');
      }

      // 4. Buscar o crear perfil en la tabla perfiles
      final perfilData = await _supabase
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (perfilData == null) {
        // Crear perfil nuevo para usuario de Google
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
        );
      }

      // 5. Devolver usuario existente
      return _mapPerfilToUsuario(
        perfilData,
        _supabase.auth.currentSession?.accessToken ?? '',
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: ${e.toString()}');
    }
  }

  // Actualizar seudonimo/usuario
  @override
  Future<void> actualizarSeudonimo(
    String usuarioId,
    String nuevoSeudonimo,
  ) async {
    await _supabase
        .from('perfiles')
        .update({'seudonimo': nuevoSeudonimo})
        .eq('id', usuarioId);
  }

  // Completar perfil (solo si DNI es NULL)
  @override
  Future<void> completarPerfil({
    required String usuarioId,
    required String dni,
    required String tipoDocumento,
    String? nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
  }) async {
    // Verificar que DNI sea NULL antes de actualizar
    final perfilActual = await _supabase
        .from('perfiles')
        .select('dni')
        .eq('id', usuarioId)
        .single();

    if (perfilActual['dni'] != null &&
        perfilActual['dni'].toString().isNotEmpty) {
      throw Exception('El DNI ya está registrado y no se puede modificar');
    }

    // Actualizar perfil
    await _supabase
        .from('perfiles')
        .update({
          'dni': dni,
          'tipo_documento': tipoDocumento,
          'nombres': nombres,
          'apellido_paterno': apellidoPaterno,
          'apellido_materno': apellidoMaterno,
        })
        .eq('id', usuarioId);
  }
}

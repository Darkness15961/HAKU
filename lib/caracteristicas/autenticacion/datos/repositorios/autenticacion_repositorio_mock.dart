// --- PIEDRA 3 (AUTENTICACIÓN): LA "COCINA FALSA" (CON ROLES MÁGICOS) ---
//
// Esta es la versión ACTUALIZADA de nuestra "Cocina Falsa".
//
// ¡HEMOS AÑADIDO "LOGINS MÁGICOS"!
// Ahora puedes iniciar sesión con diferentes correos
// para "simular" (probar) diferentes roles.

// 1. Importamos la "Receta" (Entidad)
import '../../dominio/entidades/usuario.dart';

// 2. Importamos el "Enchufe" (Repositorio)
import '../../dominio/repositorios/autenticacion_repositorio.dart';

// 3. Creamos la "Cocina Falsa"
class AutenticacionRepositorioMock implements AutenticacionRepositorio {

  // --- "Base de Datos Falsa" de Usuarios ---
  // (Creamos los 3 roles que podemos probar)

  final Usuario _usuarioFalsoTurista = Usuario(
    id: '1',
    nombre: 'Alex Gálvez (Turista)',
    email: 'turista@test.com',
    rol: 'turista',
    urlFotoPerfil: 'https://placehold.co/100x100/333333/FFFFFF?text=AG',
    dni: '12345678',
    token: 'T123456',
  );

  final Usuario _usuarioFalsoGuia = Usuario(
    id: '2',
    nombre: 'Maria Fernanda (Guía)',
    email: 'guia@test.com',
    rol: 'guia_aprobado', // <-- ¡Rol de Guía Aprobado!
    urlFotoPerfil: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
    dni: '87654321',
    token: '123456',
  );

  final Usuario _usuarioFalsoAdmin = Usuario(
    id: '3',
    nombre: 'Admin Xplora',
    email: 'admin@test.com',
    rol: 'admin', // <-- ¡Rol de Admin!
    urlFotoPerfil: 'https://placehold.co/100x100/8B0000/FFFFFF?text=ADM',
    dni: '00000001',
    token: '123456',
  );

  // Variable para "recordar" al usuario logueado
  Usuario? _usuarioActual;

  // --- ORDEN 1: "Intentar iniciar sesión" ---
  @override
  Future<Usuario> iniciarSesion(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // --- ¡LÓGICA DE "LOGIN MÁGICO"! ---
    // (No nos importa la contraseña, solo el email para la prueba)

    // 1. Si el email es "guia@test.com"...
    if (email == 'guia@test.com') {
      _usuarioActual = _usuarioFalsoGuia; // ...te logueas como Guía
      return _usuarioFalsoGuia;
    }

    // 2. Si el email es "admin@test.com"...
    if (email == 'admin@test.com') {
      _usuarioActual = _usuarioFalsoAdmin; // ...te logueas como Admin
      return _usuarioFalsoAdmin;
    }

    // 3. Si el email es cualquier otra cosa (o "turista@test.com")...
    if (email == 'turista@test.com') {
      _usuarioActual = _usuarioFalsoTurista; // ...te logueas como Turista
      return _usuarioFalsoTurista;
    }

    // 4. Si el email no es ninguno, simulamos un error
    throw Exception('Error de inicio de sesión: Usuario o contraseña incorrectos.');
  }

  // --- ORDEN 2: "Intentar registrar un nuevo usuario" ---
  @override
  Future<Usuario> registrarUsuario(
      String nombre,
      String email,
      String password,
      String dni,
      ) async {
    await Future.delayed(const Duration(seconds: 1));
    // (Al registrarte, siempre eres "turista" por defecto)
    final nuevoUsuario = Usuario(
      id: 'temp_id_99',
      nombre: nombre,
      email: email,
      rol: 'turista',
      urlFotoPerfil: 'https://placehold.co/100x100/555555/FFFFFF?text=NU',
      dni: dni,
      token: 'TOKEN_FALSO_NUEVO_USUARIO',
    );
    _usuarioActual = nuevoUsuario;
    return nuevoUsuario;
  }

  // --- ORDEN 3: "Cerrar la sesión actual" ---
  @override
  Future<void> cerrarSesion() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _usuarioActual = null;
    print('--- ¡SESIÓN CERRADA EN EL MOCK! ---');
  }

  // --- ORDEN 4: "Verificar si ya hay una sesión guardada" ---
  @override
  Future<Usuario?> verificarEstadoSesion() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _usuarioActual;
  }

  // --- ORDEN 5: "Enviar la solicitud para ser guía" ---
  @override
  Future<void> solicitarSerGuia(
      String experiencia, String rutaCertificado) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    print('--- ¡SOLICITUD DE GUÍA RECIBIDA POR EL MOCK! ---');
    print('Experiencia: $experiencia');
    print('Certificado: $rutaCertificado');
    print('-------------------------------------------');

    // Cambiamos el "rol" del usuario actual a 'guia_pendiente'
    if (_usuarioActual != null && _usuarioActual!.rol == 'turista') {
      _usuarioActual = Usuario(
        id: _usuarioActual!.id,
        nombre: _usuarioActual!.nombre,
        email: _usuarioActual!.email,
        rol: 'guia_pendiente', // <-- ¡EL ROL CAMBIÓ!
        urlFotoPerfil: _usuarioActual!.urlFotoPerfil,
        dni: _usuarioActual!.dni,
        token: _usuarioActual!.token,
      );
      print('--- ¡ROL DEL USUARIO ACTUALIZADO A "guia_pendiente"! ---');
    }
  }
}


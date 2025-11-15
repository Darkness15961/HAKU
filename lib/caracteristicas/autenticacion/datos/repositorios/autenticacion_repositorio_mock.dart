// --- PIEDRA 3 (AUTENTICACIÓN): LA "COCINA FALSA" (ACOMPLADA CON ADMIN Y BUG CORREGIDO) ---
//
// (...)
// 2. (REGLA ACOMPLADA): 'registrarUsuario' AHORA comprueba si el email
//    ya existe en '_usuariosFalsosDB'.
// 3. (¡NUEVO!): Implementados los métodos 'obtenerTodosLosUsuarios' y 'eliminarUsuario'.

import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';

// --- "Base de Datos Falsa" de Usuarios (¡ACOMPLADA!) ---
// (Tu base de datos falsa se mantiene intacta)

final Usuario _usuarioFalsoTurista = Usuario(
  id: '1',
  nombre: 'Alex Gálvez (Turista)',
  email: 'turista@test.com',
  rol: 'turista',
  urlFotoPerfil: 'https://placehold.co/100x100/333333/FFFFFF?text=AG',
  dni: '12345678',
  token: 'T123456',
  solicitudEstado: null,
  solicitudExperiencia: null,
);

final Usuario _usuarioFalsoGuia = Usuario(
  id: '2',
  nombre: 'Maria Fernanda (Guía)',
  email: 'guia@test.com',
  rol: 'guia_aprobado',
  urlFotoPerfil: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
  dni: '87654321',
  token: 'G123456',
  solicitudEstado: 'aprobado',
  solicitudExperiencia: 'Guía certificada con 5 años de experiencia en trekking.',
);

final Usuario _usuarioFalsoAdmin = Usuario(
  id: '3',
  nombre: 'Admin Xplora',
  email: 'admin@test.com',
  rol: 'admin',
  urlFotoPerfil: 'https://placehold.co/100x100/8B0000/FFFFFF?text=ADM',
  dni: '00000001',
  token: 'A123456',
  solicitudEstado: null,
  solicitudExperiencia: null,
);

final Usuario _usuarioPendiente1 = Usuario(
  id: '101',
  nombre: 'Carlos (Pendiente)',
  email: 'carlos@test.com',
  rol: 'guia_pendiente',
  urlFotoPerfil: 'https://placehold.co/100x100/1E88E5/FFFFFF?text=CP',
  dni: '11112222',
  token: 'P123',
  solicitudEstado: 'pendiente',
  solicitudExperiencia: 'Experiencia de 2 años como guía de montaña.',
);

final Usuario _usuarioPendiente2 = Usuario(
  id: '102',
  nombre: 'Juana (Pendiente)',
  email: 'juana@test.com',
  rol: 'guia_pendiente',
  urlFotoPerfil: 'https://placehold.co/100x100/D81B60/FFFFFF?text=JP',
  dni: '33334444',
  token: 'P456',
  solicitudEstado: 'pendiente',
  solicitudExperiencia: 'Guía cultural, especializada en historia Inca.',
);

// Lista mutable que simula la "tabla" de usuarios
final Map<String, Usuario> _usuariosFalsosDB = {
  '1': _usuarioFalsoTurista,
  '2': _usuarioFalsoGuia,
  '3': _usuarioFalsoAdmin,
  '101': _usuarioPendiente1,
  '102': _usuarioPendiente2,
};
// --- FIN DE BASE DE DATOS FALSA ---


// Variable para "recordar" al usuario logueado
Usuario? _usuarioActual;

// 3. Creamos la "Cocina Falsa"
class AutenticacionRepositorioMock implements AutenticacionRepositorio {

  // --- ORDEN 1: "Intentar iniciar sesión" (¡CORREGIDO!) ---
  @override
  Future<Usuario> iniciarSesion(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    final usuarioEncontrado = _usuariosFalsosDB.values.firstWhere(
          (usuario) => usuario.email == email,
      orElse: () => throw Exception('Usuario o contraseña incorrectos.'),
    );

    _usuarioActual = usuarioEncontrado;
    return _usuarioActual!;
  }

  // --- ORDEN 2: "Intentar registrar un nuevo usuario" (¡CORREGIDO!) ---
  @override
  Future<Usuario> registrarUsuario(
      String nombre,
      String email,
      String password,
      String dni,
      ) async {
    await Future.delayed(const Duration(seconds: 1));

    final yaExiste = _usuariosFalsosDB.values.any((usuario) => usuario.email == email);
    if (yaExiste) {
      throw Exception('Ya existe un usuario con ese correo.');
    }

    final nuevoId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final nuevoUsuario = Usuario(
      id: nuevoId,
      nombre: nombre,
      email: email,
      rol: 'turista',
      urlFotoPerfil: null,
      dni: dni,
      token: 'TOKEN_FALSO_$nuevoId',
      solicitudEstado: null,
      solicitudExperiencia: null,
    );

    _usuariosFalsosDB[nuevoId] = nuevoUsuario;

    _usuarioActual = nuevoUsuario;
    return nuevoUsuario;
  }

  // --- ORDEN 3: "Cerrar la sesión actual" (se mantiene) ---
  @override
  Future<void> cerrarSesion() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _usuarioActual = null;
    print('--- ¡SESIÓN CERRADA EN EL MOCK! ---');
  }

  // --- ORDEN 4: "Verificar si ya hay una sesión guardada" (se mantiene) ---
  @override
  Future<Usuario?> verificarEstadoSesion() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _usuarioActual;
  }

  // --- ORDEN 5: "Enviar la solicitud para ser guía" (se mantiene) ---
  @override
  Future<void> solicitarSerGuia(
      String experiencia, String rutaCertificado) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_usuarioActual != null && _usuarioActual!.rol == 'turista') {
      final usuarioActualizado = Usuario(
        id: _usuarioActual!.id,
        nombre: _usuarioActual!.nombre,
        email: _usuarioActual!.email,
        rol: 'guia_pendiente',
        urlFotoPerfil: _usuarioActual!.urlFotoPerfil,
        dni: _usuarioActual!.dni,
        token: _usuarioActual!.token,
        solicitudEstado: 'pendiente',
        solicitudExperiencia: experiencia,
      );
      _usuarioActual = usuarioActualizado;
      _usuariosFalsosDB[_usuarioActual!.id] = usuarioActualizado;
      print('--- ¡ROL DEL USUARIO ACTUALIZADO A "guia_pendiente"! ---');
    } else {
      throw Exception('El usuario ya es guía o no está logueado.');
    }
  }

  // --- ÓRDENES DEL ADMIN (Gestión de Guías) ---

  @override
  Future<List<Usuario>> obtenerSolicitudesPendientes() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final pendientes = _usuariosFalsosDB.values
        .where((user) => user.solicitudEstado == 'pendiente')
        .toList();
    return pendientes;
  }

  @override
  Future<void> aprobarGuia(String usuarioId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_usuariosFalsosDB.containsKey(usuarioId)) {
      final usuarioPendiente = _usuariosFalsosDB[usuarioId]!;
      final usuarioAprobado = Usuario(
        id: usuarioPendiente.id,
        nombre: usuarioPendiente.nombre,
        email: usuarioPendiente.email,
        rol: 'guia_aprobado',
        urlFotoPerfil: usuarioPendiente.urlFotoPerfil,
        dni: usuarioPendiente.dni,
        token: usuarioPendiente.token,
        solicitudEstado: 'aprobado',
        solicitudExperiencia: usuarioPendiente.solicitudExperiencia,
      );
      _usuariosFalsosDB[usuarioId] = usuarioAprobado;
      print('Mock: Guía $usuarioId APROBADO');
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  @override
  Future<void> rechazarGuia(String usuarioId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_usuariosFalsosDB.containsKey(usuarioId)) {
      final usuarioPendiente = _usuariosFalsosDB[usuarioId]!;
      final usuarioRechazado = Usuario(
        id: usuarioPendiente.id,
        nombre: usuarioPendiente.nombre,
        email: usuarioPendiente.email,
        rol: 'turista',
        urlFotoPerfil: usuarioPendiente.urlFotoPerfil,
        dni: usuarioPendiente.dni,
        token: usuarioPendiente.token,
        solicitudEstado: 'rechazado',
        solicitudExperiencia: usuarioPendiente.solicitudExperiencia,
      );
      _usuariosFalsosDB[usuarioId] = usuarioRechazado;
      print('Mock: Guía $usuarioId RECHAZADO');
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  // --- ¡AÑADIDO! ÓRDENES PARA GESTIÓN DE CUENTAS ---

  @override
  Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simplemente devuelve todos los usuarios de la base de datos falsa
    return _usuariosFalsosDB.values.toList();
  }

  @override
  Future<void> eliminarUsuario(String usuarioId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simula la eliminación del usuario de la base de datos
    if (_usuariosFalsosDB.containsKey(usuarioId)) {
      _usuariosFalsosDB.remove(usuarioId);
      print('Mock: Usuario $usuarioId ELIMINADO');
    } else {
      throw Exception('Usuario no encontrado para eliminar');
    }
  }
// --- FIN DE LO AÑADIDO ---

}
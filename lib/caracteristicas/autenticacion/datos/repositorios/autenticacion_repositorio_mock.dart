// --- lib/caracteristicas/autenticacion/datos/repositorios/autenticacion_repositorio_mock.dart ---
// (Versión que AHORA SÍ guarda la URL del certificado)

import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/autenticacion_repositorio.dart';

// --- (Toda tu base de datos falsa de usuarios se mantiene 100% intacta) ---
final Usuario _usuarioFalsoTurista = Usuario(
  id: '1',
  nombre: 'Alex Gálvez (Turista)',
  email: 'turista@test.com',
  rol: 'turista',
  urlFotoPerfil: 'https://placehold.co/100x100/333333/FFFFFF?text=AG',
  dni: '12345678',
  token: '123456',
  solicitudEstado: null,
  solicitudExperiencia: null,
  solicitudCertificadoUrl: null, // <-- ¡Añadido por el nuevo campo!
);

final Usuario _usuarioFalsoGuia = Usuario(
  id: '2',
  nombre: 'Maria Fernanda (Guía)',
  email: 'guia@test.com',
  rol: 'guia_aprobado',
  urlFotoPerfil: 'https://placehold.co/100x100/6A5ACD/FFFFFF?text=MF',
  dni: '87654321',
  token: '123456',
  solicitudEstado: 'aprobado',
  solicitudExperiencia: 'Guía certificada con 5 años de experiencia en trekking.',
  solicitudCertificadoUrl: 'https://www.drive.google.com/fake-link/maria-fernanda', // <-- ¡Añadido!
);

final Usuario _usuarioFalsoAdmin = Usuario(
  id: '3',
  nombre: 'Admin Xplora',
  email: 'admin@test.com',
  rol: 'admin',
  urlFotoPerfil: 'https://placehold.co/100x100/8B0000/FFFFFF?text=ADM',
  dni: '00000001',
  token: '123456',
  solicitudEstado: null,
  solicitudExperiencia: null,
  solicitudCertificadoUrl: null, // <-- ¡Añadido!
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
  solicitudCertificadoUrl: 'https://www.dropbox.com/fake-link/carlos-doc', // <-- ¡Añadido!
);

final Usuario _usuarioPendiente2 = Usuario(
  id: '102',
  nombre: 'Juana (Pendiente)',
  email: 'juana@test.com',
  rol: 'guia_pendiente',
  urlFotoPerfil: 'https://placehold.co/100x100/D81B60/FFFFFF?text=JP',
  dni: '33334444',
  token: '123456',
  solicitudEstado: 'pendiente',
  solicitudExperiencia: 'Guía cultural, especializada en historia Inca.',
  solicitudCertificadoUrl: 'https://www.drive.google.com/fake-link/juana-peru', // <-- ¡Añadido!
);

final Map<String, Usuario> _usuariosFalsosDB = {
  '1': _usuarioFalsoTurista,
  '2': _usuarioFalsoGuia,
  '3': _usuarioFalsoAdmin,
  '101': _usuarioPendiente1,
  '102': _usuarioPendiente2,
};
// --- FIN DE BASE DE DATOS FALSA ---


Usuario? _usuarioActual;

class AutenticacionRepositorioMock implements AutenticacionRepositorio {

  // --- (Tu función 'iniciarSesion' corregida se mantiene intacta) ---
  @override
  Future<Usuario> iniciarSesion(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    // 1. Buscamos al usuario por email
    final usuarioEncontrado = _usuariosFalsosDB.values.firstWhere(
          (usuario) => usuario.email == email,
      orElse: () => throw Exception('Usuario o contraseña incorrectos.'),
    );

    // 2. Validamos la contraseña
    if (password != '123456') {
      throw Exception('Usuario o contraseña incorrectos.');
    }

    // 3. Si ambos son correctos, iniciamos sesión
    _usuarioActual = usuarioEncontrado;
    return _usuarioActual!;
  }

  // --- (El resto de tus funciones: registrar, cerrarSesion, verificarEstadoSesion... se mantienen intactas) ---
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
      solicitudCertificadoUrl: null, // <-- ¡Añadido!
    );

    _usuariosFalsosDB[nuevoId] = nuevoUsuario;

    _usuarioActual = nuevoUsuario;
    return nuevoUsuario;
  }

  @override
  Future<void> cerrarSesion() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _usuarioActual = null;
    print('--- ¡SESIÓN CERRADA EN EL MOCK! ---');
  }

  @override
  Future<Usuario?> verificarEstadoSesion() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _usuarioActual;
  }

  // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
  @override
  Future<void> solicitarSerGuia(
      String experiencia, String rutaCertificado) async { // <-- 'rutaCertificado' se recibe
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
        solicitudExperiencia: experiencia, // <-- Se guarda la experiencia
        solicitudCertificadoUrl: rutaCertificado, // <-- ¡AHORA SÍ SE GUARDA LA URL!
      );
      _usuarioActual = usuarioActualizado;
      _usuariosFalsosDB[_usuarioActual!.id] = usuarioActualizado;
      print('--- ¡ROL DEL USUARIO ACTUALIZADO A "guia_pendiente"! ---');
    } else {
      throw Exception('El usuario ya es guía o no está logueado.');
    }
  }

  // --- (Todas las demás funciones de Admin... se mantienen intactas) ---
  @override
  Future<List<Usuario>> obtenerSolicitudesPendientes() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final pendientes = _usuariosFalsosDB.values
        .where((user) => user.solicitudEstado == 'pendiente')
        .toList();
    return pendientes;
  }
  // ... (aprobarGuia, rechazarGuia, obtenerTodosLosUsuarios, eliminarUsuario) ...
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
        solicitudCertificadoUrl: usuarioPendiente.solicitudCertificadoUrl, // <-- Se mantiene
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
        solicitudCertificadoUrl: usuarioPendiente.solicitudCertificadoUrl, // <-- Se mantiene
      );
      _usuariosFalsosDB[usuarioId] = usuarioRechazado;
      print('Mock: Guía $usuarioId RECHAZADO');
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  @override
  Future<List<Usuario>> obtenerTodosLosUsuarios() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _usuariosFalsosDB.values.toList();
  }

  @override
  Future<void> eliminarUsuario(String usuarioId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_usuariosFalsosDB.containsKey(usuarioId)) {
      _usuariosFalsosDB.remove(usuarioId);
      print('Mock: Usuario $usuarioId ELIMINADO');
    } else {
      throw Exception('Usuario no encontrado para eliminar');
    }
  }
}
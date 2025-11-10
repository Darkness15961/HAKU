// --- PIEDRA 7 (PERFIL): EL "MENÚ" DE PERFIL (ACOMPLADO CON STRING? NULABLE) ---
//
// 1. (BUG CORREGIDO): El 'CircleAvatar' ahora comprueba si
//    'usuario.urlFotoPerfil' es nulo ('String?') antes de usarlo
//    en 'NetworkImage'.
// 2. (UX MEJORADA): Si la foto es nula, muestra las iniciales.
// 3. (ACOMPLADO): Usa los botones 'mis-favoritos' y 'mis-rutas'.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- MVVM: IMPORTACIONES ---
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
// ¡Necesitamos RutasVM solo para el botón de "Mis Rutas Creadas"!
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';


class PerfilPagina extends StatelessWidget {
  const PerfilPagina({super.key});

  // --- Lógica de Acciones ---
  Future<void> _cerrarSesion(BuildContext context) async {
    await context.read<AutenticacionVM>().cerrarSesion();
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (watch) SOLAMENTE al "Cerebro" y a RutasVM (para el botón de Guía)
    final vmAuth = context.watch<AutenticacionVM>();
    final vmRutas = context.watch<RutasVM>(); // Para el botón de "Creadas por mí"

    final colorPrimario = Theme.of(context).colorScheme.primary;

    // Si el "Mesero" está "cargando"
    // Ahora solo dependemos de AuthVM, la carga es más rápida.
    if (vmAuth.estaCargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- Lógica Principal: ¿ESTÁ LOGUEADO? ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: colorPrimario,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: vmAuth.estaLogueado
          ? _buildPerfilLogueado(context, vmAuth, vmRutas, colorPrimario) // Vista 1: Logueado
          : _buildPerfilNoLogueado(context, colorPrimario), // Vista 2: Anónimo
    );
  }

  // --- WIDGETS DE VISTA ---

  // --- VISTA 1: El Perfil del Usuario LOGUEADO ---
  Widget _buildPerfilLogueado(
      BuildContext context,
      AutenticacionVM vmAuth,
      RutasVM vmRutas, // <-- Añadido
      Color colorPrimario
      ) {
    final usuario = vmAuth.usuarioActual!;
    final textTheme = Theme.of(context).textTheme;

    // (La lógica de filtrado ya no se hace aquí, se hará en las nuevas páginas)

    // Lógica para mostrar el rol de forma amigable
    String rolDisplay;
    Color rolColor;
    switch (usuario.rol) {
      case 'admin':
        rolDisplay = 'Administrador 👑';
        rolColor = Colors.red.shade700;
        break;
      case 'guia_aprobado':
        rolDisplay = 'Guía Turístico Certificado ✅';
        rolColor = Colors.green.shade700;
        break;
      case 'guia_pendiente':
        rolDisplay = 'Guía (Solicitud Pendiente 🟡)';
        rolColor = Colors.orange.shade700;
        break;
      case 'guia_rechazado':
        rolDisplay = 'Guía (Solicitud Rechazada 🔴)';
        rolColor = Colors.red.shade700;
        break;
      default: // 'turista'
        rolDisplay = 'Turista 👤';
        rolColor = Colors.blueGrey.shade600;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER (Foto, Nombre, Rol) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorPrimario,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [

                // --- ¡AQUÍ ESTÁ LA CORRECCIÓN DEL BUG! ---
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  // 1. Comprueba si la URL NO es nula Y NO está vacía
                  backgroundImage: (usuario.urlFotoPerfil != null && usuario.urlFotoPerfil!.isNotEmpty)
                      ? NetworkImage(usuario.urlFotoPerfil!) // Si es válida, úsala
                      : null, // Si es nula, no pongas imagen de fondo

                  // 2. Si la URL ES nula O está vacía, muestra las iniciales
                  child: (usuario.urlFotoPerfil == null || usuario.urlFotoPerfil!.isEmpty)
                      ? Text(
                    usuario.nombre.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: colorPrimario, fontSize: 32, fontWeight: FontWeight.bold),
                  )
                      : null, // Si hay imagen de fondo, no muestres nada encima
                ),
                // --- FIN DE LA CORRECCIÓN ---

                const SizedBox(height: 12),
                Text(
                  usuario.nombre,
                  style: textTheme.headlineSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Chip(
                  label: Text(rolDisplay,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white)),
                  backgroundColor: rolColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- ¡SECCIÓN CORREGIDA: Botones de Listas! ---
          _buildTituloSeccion('Mi Actividad'),
          _buildOpcion(
            context: context,
            icon: Icons.favorite, // Icono lleno
            titulo: 'Mis Lugares Favoritos',
            subtitulo: 'Ver los lugares que guardaste',
            color: Colors.red.shade700,
            onTap: () {
              // ¡BOTÓN ACTIVADO!
              context.push('/mis-favoritos');
            },
          ),
          _buildOpcion(
            context: context,
            icon: Icons.check_circle, // Icono lleno
            titulo: 'Mis Rutas Registradas',
            subtitulo: 'Ver las rutas a las que te inscribiste',
            color: Colors.green.shade700,
            onTap: () {
              // ¡BOTÓN ACTIVADO!
              context.push('/mis-rutas');
            },
          ),

          const Divider(thickness: 1, height: 24, indent: 16, endIndent: 16),

          // --- TUS OPCIONES DE GESTIÓN (Intactas) ---
          _buildTituloSeccion('Gestión'),

          // CASO 1: Es un Guía Aprobado
          if (usuario.rol == 'guia_aprobado')
            _buildOpcion(
              context: context,
              icon: Icons.add_road,
              titulo: 'Mis Rutas Creadas',
              subtitulo: 'Gestionar las rutas que publicaste',
              color: Colors.blue.shade700,
              onTap: () {
                context.read<RutasVM>().cambiarPestana('Creadas por mí');
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegando a Mis Rutas Creadas... (Próximamente)'))
                );
              },
            ),

          // CASO 2: Es un Turista
          if (usuario.rol == 'turista')
            _buildOpcion(
              context: context,
              icon: Icons.assignment_ind_outlined,
              titulo: 'Solicitar ser Guía',
              subtitulo: 'Envía tu solicitud para crear rutas',
              color: Colors.blue.shade700,
              onTap: () {
                context.push('/solicitar-guia');
              },
            ),

          // CASO 3: Es un Guía Pendiente
          if (usuario.rol == 'guia_pendiente')
            ListTile(
              leading: Icon(Icons.hourglass_top, color: Colors.orange.shade700),
              title: const Text('Solicitud de Guía en Revisión', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Estamos validando tus datos. ¡Gracias por tu paciencia!'),
              isThreeLine: true,
            ),

          // CASO 4: Es un Guía Rechazado
          if (usuario.rol == 'guia_rechazado')
            _buildOpcion(
              context: context,
              icon: Icons.error_outline,
              titulo: 'Solicitud Rechazada',
              subtitulo: 'Toca para revisar y enviar de nuevo',
              color: Colors.red.shade700,
              onTap: () {
                context.push('/solicitar-guia');
              },
            ),

          // CASO 5: Es un Administrador
          if (vmAuth.esAdmin)
            _buildOpcion(
              context: context,
              icon: Icons.admin_panel_settings,
              titulo: 'Panel de Administrador',
              subtitulo: 'Gestionar solicitudes de guías',
              color: Colors.purple.shade700,
              onTap: () {
                // ¡ACOMPLADO! Navega al panel de admin
                context.push('/panel-admin');
              },
            ),

          const Divider(),

          // --- Botón de Cerrar Sesión ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              onPressed: () => _cerrarSesion(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // --- VISTA 2: El Perfil del Usuario ANÓNIMO ---
  Widget _buildPerfilNoLogueado(BuildContext context, Color colorPrimario) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Bienvenido Anónimo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para guardar tus lugares favoritos y acceder a tus rutas reservadas.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white),
              child: const Text('Iniciar Sesión'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/registro'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: colorPrimario)),
              child:
              Text('Crear Cuenta', style: TextStyle(color: colorPrimario)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOpcion({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitulo),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
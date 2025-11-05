// --- PIEDRA 1 (BLOQUE 4): EL "MENÚ" 4 (PERFIL) ---
//
// Esta es la versión ACTUALIZADA.
// El botón "Solicitar ser Guía" ahora
// SÍ navega a la pantalla del formulario.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// 1. Importamos el "Mesero de Seguridad" (AuthVM)
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class PerfilPagina extends StatelessWidget {
  const PerfilPagina({super.key});

  // --- Lógica de Acciones ---

  // Función para "Cerrar Sesión"
  Future<void> _cerrarSesion(BuildContext context) async {
    // Le damos la "ORDEN 4" al "Mesero de Seguridad"
    await context.read<AutenticacionVM>().cerrarSesion();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada con éxito.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (watch) al "Mesero" (AuthVM)
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // Si el "Mesero" está "cargando"
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
      ),
      body: vmAuth.estaLogueado
          ? _buildPerfilLogueado(context, vmAuth, colorPrimario) // Vista 1: Logueado
          : _buildPerfilNoLogueado(context, colorPrimario), // Vista 2: Anónimo
    );
  }

  // --- WIDGETS DE VISTA ---

  // --- VISTA 1: El Perfil del Usuario LOGUEADO ---
  Widget _buildPerfilLogueado(
      BuildContext context, AutenticacionVM vmAuth, Color colorPrimario) {
    final usuario = vmAuth.usuarioActual!;
    final textTheme = Theme.of(context).textTheme;

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
      default: // 'turista'
        rolDisplay = 'Turista 👤';
        rolColor = Colors.blueGrey.shade600;
    }

    return SingleChildScrollView(
      child: Column(
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
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(usuario.urlFotoPerfil),
                  backgroundColor: Colors.white,
                ),
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

          // --- OPCIONES DE GESTIÓN (Tu Diseño) ---
          _buildOpcion(
            context: context,
            icon: Icons.favorite_border,
            titulo: 'Mis Lugares Favoritos',
            subtitulo: 'Ver lugares que has guardado',
            onTap: () {
              // TODO: context.push('/mis-favoritos')
            },
          ),
          _buildOpcion(
            context: context,
            icon: Icons.alt_route,
            titulo: 'Mis Rutas Registradas',
            subtitulo: 'Tours a los que te has inscrito',
            onTap: () {
              // TODO: context.push('/mis-rutas')
            },
          ),

          // --- ¡LÓGICA DE ROLES (Tu Petición)! ---

          // CASO 1: Es un Guía Aprobado
          if (usuario.rol == 'guia_aprobado')
            _buildOpcion(
              context: context,
              icon: Icons.add_road,
              titulo: 'Mis Rutas Creadas',
              subtitulo: 'Gestionar las rutas que publicaste',
              color: Colors.green.shade700,
              onTap: () {
                // (Esto lo conectaremos al "Mesero de Rutas")
                // vmRutas.cambiarPestana('Creadas por mí');
                // (Y luego navegar a la pestaña 2)
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
                // --- ¡ARREGLO! (Paso 6 - Bloque 5) ---
                //
                // "Encendemos" el botón.
                // Ya no muestra un SnackBar, ahora
                // usa el "GPS" para ir a la "dirección"
                // del formulario que ya creamos.
                context.push('/solicitar-guia');
                // --- FIN DEL ARREGLO ---
              },
            ),

          // CASO 3: Es un Guía Pendiente
          if (usuario.rol == 'guia_pendiente')
            ListTile(
              leading: Icon(Icons.hourglass_top, color: Colors.orange.shade700),
              title: const Text('Solicitud de Guía en Revisión', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Estamos validando tus datos. ¡Gracias por tu paciencia!'),
              onTap: () {
                // (Opcional) Podemos llevarlo a una pantalla
                // que muestre el estado de su solicitud
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
            // Botón de Login
            ElevatedButton(
              onPressed: () => context.push('/login'), // Va al "GPS"
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colorPrimario),
              child: const Text('Iniciar Sesión',
                  style: TextStyle(color: Colors.white)),
            ),
            // Botón de Registro
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/registro'), // Va al "GPS"
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

  // Widget Reutilizable para Opciones del Perfil
  Widget _buildOpcion({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color color = Colors.black87, // Color por defecto
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


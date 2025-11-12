// --- PIEDRA 12 (ADMIN): EL "ENTORNO" (DASHBOARD PRINCIPAL) ---
//
// 1. (BUG NAVEGACIÓN CORREGIDO): El botón 'Cerrar Sesión' ahora
//    usa 'await' y luego 'context.go('/perfil')' para redirigir
//    a la página de perfil (como anónimo).
// 2. (BUG UI CORREGIDO): Se añadió 'automaticallyImplyLeading: false'
//    al AppBar para ocultar la flecha de "atrás".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class AdminDashboardPagina extends StatelessWidget {
  const AdminDashboardPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // Obtenemos las estadísticas del "Cerebro"
    final int guiasPendientes = vmAuth.usuariosPendientes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,

        // --- ¡CORREGIDO! ---
        // Esto deshabilita la flecha de "atrás" automática
        automaticallyImplyLeading: false,
        // --- FIN DE CORRECCIÓN ---

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              // 1. Esperamos a que la sesión se cierre
              await context.read<AutenticacionVM>().cerrarSesion();

              // 2. Comprobamos que el widget siga "vivo"
              if (!context.mounted) return;

              // --- ¡CORREGIDO! ---
              // 3. Navegamos a la página de Perfil (ahora como anónimo)
              context.go('/perfil');
              // --- FIN DE LA CORRECCIÓN ---
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sección de Estadísticas ---
            Text(
              'Resumen del Sistema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  titulo: 'Solicitudes Pendientes',
                  valor: guiasPendientes.toString(),
                  icono: Icons.pending_actions,
                  color: Colors.orange.shade700,
                  // Al tocar, refresca la lista
                  onTap: () => context.read<AutenticacionVM>().cargarSolicitudesPendientes(),
                ),
                // (Aquí puedes añadir más tarjetas de estadísticas en el futuro)
              ],
            ),

            const Divider(height: 40),

            // --- Sección de Herramientas de Gestión ---
            Text(
              'Herramientas de Gestión',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1. Botón de Gestionar Guías
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Guías',
              subtitulo: 'Aprobar o rechazar solicitudes pendientes.',
              icono: Icons.assignment_ind,
              color: Colors.orange.shade700,
              onTap: () {
                // ¡Navega a la página que renombramos!
                context.push('/admin/gestion-guias'); // <-- Esta ruta está BIEN
              },
            ),

            // 2. Botón de Gestionar Lugares (Placeholder)
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Lugares',
              subtitulo: 'Crear, editar o eliminar lugares turísticos.',
              icono: Icons.place,
              color: Colors.blue.shade700,
              onTap: () {
                // (A futuro)
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Módulo de Lugares (Próximamente)'))
                );
              },
            ),

            // 3. Botón de Gestionar Cuentas (Placeholder)
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Cuentas',
              subtitulo: 'Ver y editar todos los usuarios (Turistas/Guías).',
              icono: Icons.people,
              color: Colors.grey.shade700,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Módulo de Cuentas (Próximamente)'))
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares de Diseño ---

  Widget _buildStatCard(BuildContext context, {
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icono, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valor,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        titulo,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGestionOpcion(BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text(subtitulo, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
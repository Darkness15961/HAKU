// --- PIEDRA 12 (ADMIN): EL "ENTORNO" (DASHBOARD PRINCIPAL) ---
//
// (...)
// 4. (¡HABILITADO!): El botón 'Gestionar Lugares' ahora navega.
// 5. (¡CORREGIDO!): 'Gestionar Lugares' ahora apunta al nuevo sub-menú.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../vista_modelos/admin_hakuparadas_vm.dart';

class AdminDashboardPagina extends StatelessWidget {
  const AdminDashboardPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    final int guiasPendientes = vmAuth.usuariosPendientes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,

        automaticallyImplyLeading: false,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await context.read<AutenticacionVM>().cerrarSesion();
              if (!context.mounted) return;
              context.go('/perfil');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NAVEGACIÓN PRINCIPAL (SALIDA AMIGABLE) ---
            _buildIrALaAppCard(context),
            const SizedBox(height: 24),

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
                  onTap: () => context.read<AutenticacionVM>().cargarSolicitudesPendientes(),
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  titulo: 'Hakuparadas Nuevas',
                  valor: context.watch<AdminHakuparadasVM>().pendientes.length.toString(),
                  icono: Icons.add_location_alt,
                  color: Colors.teal.shade700,
                  onTap: () {}, 
                ),
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
                context.push('/admin/gestion-guias');
              },
            ),

            // 2. Botón de Gestionar Contenido (Lugares, Provincias, etc.)
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Contenido',
              subtitulo: 'Gestionar lugares, provincias y categorías.',
              icono: Icons.place,
              color: Colors.blue.shade700,
              onTap: () {
                context.push('/admin/gestion-contenido');
              },
            ),

            // 3. Botón de Gestionar Cuentas
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Cuentas',
              subtitulo: 'Ver y eliminar todos los usuarios.',
              icono: Icons.people,
              color: Colors.indigo.shade600,
              onTap: () {
                context.push('/admin/gestion-cuentas');
              },
            ),
            
            // 4. Botón de Gestionar Hakuparadas
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Hakuparadas',
              subtitulo: 'Aprobar sugerencias de guías y turistas.',
              icono: Icons.check_circle_outline,
              color: Colors.teal.shade600,
              onTap: () {
                context.push('/admin/gestion-hakuparadas');
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares de Diseño ---

  Widget _buildIrALaAppCard(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorPrimario.withValues(alpha: 0.8),
            colorPrimario,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorPrimario.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/inicio'),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ir a la Aplicación',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Explora el mapa y las rutas como usuario',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                  backgroundColor: color.withValues(alpha: 0.1),
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
          backgroundColor: color.withValues(alpha: 0.1),
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
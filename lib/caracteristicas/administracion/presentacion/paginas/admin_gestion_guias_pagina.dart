// --- CARACTERISTICAS/ADMINISTRACION/PRESENTACION/PAGINAS/ADMIN_GESTION_GUIAS_PAGINA.DART ---
//
// 1. (BUG CORREGIDO): Se eliminó la llave '}' extra al final.
// 2. (ESTABLE): Mantiene toda la lógica de aprobación/rechazo.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/dominio/entidades/usuario.dart';

class AdminGestionGuiasPagina extends StatelessWidget { // <-- El nombre coincide con app_rutas
  const AdminGestionGuiasPagina({super.key});

  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (watch) al "Cerebro"
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Guías'), // <-- Título actualizado
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        // (Quitamos el botón de logout de aquí, ya que está en el Dashboard)
      ),
      body: Stack(
        children: [
          // Contenido principal
          _buildContent(context, vmAuth),

          // Overlay de Carga (Spinner)
          if (vmAuth.estaCargandoAdmin)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // Widget para construir el contenido (lista o mensaje)
  Widget _buildContent(BuildContext context, AutenticacionVM vmAuth) {
    if (vmAuth.usuariosPendientes.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<AutenticacionVM>().cargarSolicitudesPendientes(),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text(
                    '¡Todo en orden!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No hay solicitudes de guías pendientes de aprobación.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Si SÍ hay solicitudes, muestra la lista
    return RefreshIndicator(
      onRefresh: () => context.read<AutenticacionVM>().cargarSolicitudesPendientes(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: vmAuth.usuariosPendientes.length,
        itemBuilder: (context, index) {
          final usuario = vmAuth.usuariosPendientes[index];
          return _buildSolicitudCard(context, usuario, vmAuth);
        },
      ),
    );
  }

  // Tarjeta para cada solicitud pendiente
  Widget _buildSolicitudCard(BuildContext context, Usuario usuario, AutenticacionVM vmAuth) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de Información del Usuario
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: (usuario.urlFotoPerfil != null && usuario.urlFotoPerfil!.isNotEmpty)
                      ? NetworkImage(usuario.urlFotoPerfil!)
                      : null,
                  child: (usuario.urlFotoPerfil == null || usuario.urlFotoPerfil!.isEmpty)
                      ? Text(usuario.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        usuario.email,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Información de la Solicitud
            const Text(
              'DATOS DE LA SOLICITUD:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              usuario.solicitudExperiencia ?? 'El usuario no proporcionó detalles de experiencia.',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              'DNI: ${usuario.dni ?? 'No especificado'}',
              style: const TextStyle(fontSize: 14),
            ),

            TextButton.icon(
              icon: const Icon(Icons.description, size: 18),
              label: const Text('Ver Certificado (Simulado)'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Abriendo certificado... (Simulado)'))
                );
              },
            ),

            const SizedBox(height: 16),

            // Fila de Botones de Acción
            Row(
              children: [
                // Botón Rechazar
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade700),
                    ),
                    onPressed: () {
                      vmAuth.rechazarGuia(usuario.id);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Botón Aprobar
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      vmAuth.aprobarGuia(usuario.id);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} // <-- ¡LA LLAVE EXTRA FUE ELIMINADA DE AQUÍ!
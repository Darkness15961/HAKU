// --- lib/caracteristicas/administracion/presentacion/paginas/admin_gestion_guias_pagina.dart ---
// (Versión con diseño mejorado y el botón de certificado FUNCIONAL)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/dominio/entidades/usuario.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- ¡IMPORTANTE! Añade esto

class AdminGestionGuiasPagina extends StatelessWidget {
  const AdminGestionGuiasPagina({super.key});

  Future<void> _recargar(BuildContext context) async {
    // Leemos el VM con 'read' (sin escuchar) porque estamos en una función
    await context.read<AutenticacionVM>().cargarSolicitudesPendientes();
  }

  @override
  Widget build(BuildContext context) {
    // "Escuchamos" (watch) al "Cerebro"
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Guías'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Contenido principal
          RefreshIndicator(
            onRefresh: () => _recargar(context),
            child: _buildContent(context, vmAuth),
          ),

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
      // Mensaje de "No hay pendientes" (tu código original, que está perfecto)
      return ListView( // Envuelto en ListView para que el RefreshIndicator funcione
        padding: const EdgeInsets.all(24.0),
        physics: const AlwaysScrollableScrollPhysics(), // Permite refrescar
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
      );
    }

    // Si SÍ hay solicitudes, muestra la lista rediseñada
    return ListView.builder(
      padding: const EdgeInsets.all(8.0), // Padding general
      itemCount: vmAuth.usuariosPendientes.length,
      itemBuilder: (context, index) {
        final usuario = vmAuth.usuariosPendientes[index];
        return _buildSolicitudCard(context, usuario, vmAuth);
      },
    );
  }

  // --- ¡TARJETA REDISEÑADA CON EXPANSIONTILE! ---
  Widget _buildSolicitudCard(BuildContext context, Usuario usuario, AutenticacionVM vmAuth) {

    // --- Lógica del Certificado ---
    final String? urlCertificado = usuario.solicitudCertificadoUrl;
    final bool tieneCertificado = (urlCertificado != null && urlCertificado.isNotEmpty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Importante para que el ExpansionTile se vea bien
      child: ExpansionTile(
        // --- ESTA ES LA PARTE QUE SIEMPRE SE VE (HEADER) ---
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: (usuario.urlFotoPerfil != null && usuario.urlFotoPerfil!.isNotEmpty)
              ? NetworkImage(usuario.urlFotoPerfil!)
              : null,
          child: (usuario.urlFotoPerfil == null || usuario.urlFotoPerfil!.isEmpty)
              ? Text(usuario.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(
          usuario.nombre,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          usuario.email,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),

        // --- ESTO SE MUESTRA AL EXPANDIR ---
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATOS DE LA SOLICITUD:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // DNI
                Row(
                  children: [
                    Icon(Icons.person_pin, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'DNI: ${usuario.dni ?? 'No especificado'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Experiencia
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.article_outlined, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        usuario.solicitudExperiencia ?? 'Sin detalles de experiencia.',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // --- SECCIÓN DE DOCUMENTACIÓN (AHORA FUNCIONAL) ---
                const Text(
                  'DOCUMENTACIÓN:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4),

                TextButton.icon(
                  icon: Icon(Icons.description, size: 18, color: tieneCertificado ? Theme.of(context).colorScheme.primary : Colors.grey),
                  label: Text(
                    tieneCertificado ? 'Ver Certificado' : 'Sin Certificado',
                    style: TextStyle(color: tieneCertificado ? Theme.of(context).colorScheme.primary : Colors.grey),
                  ),
                  // Si no hay certificado, el botón se deshabilita (onPressed: null)
                  onPressed: tieneCertificado ? () async {
                    final uri = Uri.parse(urlCertificado!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo abrir el enlace: $urlCertificado'), backgroundColor: Colors.red),
                      );
                    }
                  } : null,
                ),

                const SizedBox(height: 16),

                // Fila de Botones de Acción (tu lógica intacta)
                Row(
                  children: [
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
          )
        ],
      ),
    );
  }
}
// --- CARACTERISTICAS/ADMINISTRACION/PRESENTACION/PAGINAS/ADMIN_GESTION_CONTENIDO_PAGINA.DART ---
//
// Esta es la NUEVA página que sirve como "sub-menú" para
// gestionar Lugares, Provincias y Categorías.
//
// 1. (¡HABILITADO!): El botón 'Gestionar Provincias' ahora navega
//    a la nueva página '/admin/gestion-provincias'.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';

class AdminGestionContenidoPagina extends StatelessWidget {
  const AdminGestionContenidoPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Contenido'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona qué deseas gestionar:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // 1. Botón de Gestionar Lugares
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Lugares',
              subtitulo: 'Crear, editar o eliminar lugares turísticos.',
              icono: Icons.place,
              color: Colors.blue.shade700,
              onTap: () {
                context.push('/admin/gestion-lugares');
              },
            ),

            // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
            // 2. Botón de Gestionar Provincias (Habilitado)
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Provincias',
              subtitulo: 'Crear o editar las provincias.',
              icono: Icons.map_outlined,
              color: Colors.green.shade700,
              onTap: () {
                // Ahora navega a la nueva página
                context.push('/admin/gestion-provincias');
              },
            ),
            // --- FIN DE LA CORRECCIÓN ---

            // 3. Botón de Gestionar Categorías
            _buildGestionOpcion(
              context,
              titulo: 'Gestionar Categorías',
              subtitulo: 'Crear o editar las categorías (ej. "Naturaleza").',
              icono: Icons.category_outlined,
              color: Colors.purple.shade700,
              onTap: () {
                // TODO: Navegar a /admin/gestion-categorias
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Módulo de Categorías (Próximamente)'))
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // (Widget auxiliar de diseño copiado de admin_dashboard_pagina.dart)
  Widget _buildGestionOpcion(BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
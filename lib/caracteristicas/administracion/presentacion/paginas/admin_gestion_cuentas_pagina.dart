// --- CARACTERISTICAS/ADMINISTRACION/PRESENTACION/PAGINAS/ADMIN_GESTION_CUENTAS_PAGINA.DART ---
//
// Esta es la nueva página para gestionar (ver y eliminar) todos los usuarios.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/dominio/entidades/usuario.dart';

class AdminGestionCuentasPagina extends StatefulWidget {
  const AdminGestionCuentasPagina({super.key});

  @override
  State<AdminGestionCuentasPagina> createState() => _AdminGestionCuentasPaginaState();
}

class _AdminGestionCuentasPaginaState extends State<AdminGestionCuentasPagina> {
  @override
  void initState() {
    super.initState();
    // Cargamos la lista de todos los usuarios al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usaremos un nuevo método que añadiremos al VM
      context.read<AutenticacionVM>().cargarUsuariosTotales();
    });
  }

  // --- Lógica de Acciones ---
  void _eliminarUsuario(BuildContext context, Usuario usuario) {
    // Pedimos confirmación antes de una acción destructiva
    _mostrarDialogoEliminar(context, usuario);
  }

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Cuentas'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Usaremos la nueva lista 'usuariosTotales' del VM
          _buildContent(context, vmAuth, vmAuth.usuariosTotales),

          // Overlay de Carga (Spinner)
          if (vmAuth.estaCargandoAdmin)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // Widget para construir el contenido (lista o mensaje)
  Widget _buildContent(BuildContext context, AutenticacionVM vmAuth, List<Usuario> usuarios) {
    if (usuarios.isEmpty && !vmAuth.estaCargandoAdmin) {
      return RefreshIndicator(
        onRefresh: () => vmAuth.cargarUsuariosTotales(),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, color: Colors.grey, size: 80),
                  SizedBox(height: 16),
                  Text(
                    'No hay usuarios registrados',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cuando los usuarios se registren, aparecerán aquí.',
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

    // Si SÍ hay usuarios, muestra la lista
    return RefreshIndicator(
      onRefresh: () => vmAuth.cargarUsuariosTotales(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final usuario = usuarios[index];
          // No queremos que el admin se pueda eliminar a sí mismo
          final bool esUsuarioActual = usuario.id == vmAuth.usuarioActual?.id;
          return _buildUsuarioCard(context, usuario, esUsuarioActual);
        },
      ),
    );
  }

  // Tarjeta para cada usuario
  Widget _buildUsuarioCard(BuildContext context, Usuario usuario, bool esUsuarioActual) {

    // Asignar color según el rol para identificarlo fácil
    Color rolColor;
    IconData rolIcon;
    switch (usuario.rol) {
      case 'admin':
        rolColor = Colors.purple;
        rolIcon = Icons.admin_panel_settings;
        break;
      case 'guia_aprobado':
        rolColor = Colors.green;
        rolIcon = Icons.assignment_ind;
        break;
      case 'guia_pendiente':
        rolColor = Colors.orange;
        rolIcon = Icons.pending_actions;
        break;
      default: // 'turista'
        rolColor = Colors.blue;
        rolIcon = Icons.person;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: rolColor.withValues(alpha: 0.1),
              child: Icon(rolIcon, color: rolColor),
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
                  Text(
                    'Rol: ${usuario.rol}',
                    style: TextStyle(fontSize: 12, color: rolColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Botón de Eliminar
            // Deshabilitado si es el admin actual
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: esUsuarioActual ? Colors.grey : Colors.red.shade700,
              ),
              tooltip: esUsuarioActual ? 'No puedes eliminarte a ti mismo' : 'Eliminar Usuario',
              onPressed: esUsuarioActual ? null : () {
                _eliminarUsuario(context, usuario);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo de confirmación
  void _mostrarDialogoEliminar(BuildContext context, Usuario usuario) {
    final vmAuth = context.read<AutenticacionVM>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar Usuario?'),
        content: Text('Estás a punto de eliminar permanentemente a "${usuario.nombre}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sí, Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Llamamos al nuevo método del VM
              vmAuth.eliminarUsuario(usuario.id);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}
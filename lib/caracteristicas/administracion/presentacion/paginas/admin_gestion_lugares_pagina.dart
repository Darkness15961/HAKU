// --- CARACTERISTICAS/ADMINISTRACION/PRESENTACION/PAGINAS/ADMIN_GESTION_LUGARES_PAGINA.DART ---
//
// Esta es la nueva página para gestionar (ver, editar, eliminar)
// todos los lugares turísticos.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';

class AdminGestionLugaresPagina extends StatefulWidget {
  const AdminGestionLugaresPagina({super.key});

  @override
  State<AdminGestionLugaresPagina> createState() => _AdminGestionLugaresPaginaState();
}

class _AdminGestionLugaresPaginaState extends State<AdminGestionLugaresPagina> {
  @override
  void initState() {
    super.initState();
    // Cargamos la lista de todos los lugares al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LugaresVM>().cargarTodosLosLugares();
    });
  }

  // --- Lógica de Acciones ---
  void _eliminarLugar(BuildContext context, Lugar lugar) {
    // Pedimos confirmación
    _mostrarDialogoEliminar(context, lugar);
  }

  void _editarLugar(BuildContext context, Lugar lugar) {
    // Navega a la página de crear/editar, pasando el lugar
    context.push('/admin/crear-lugar', extra: lugar);
  }

  void _crearLugar(BuildContext context) {
    // Navega a la página de crear/editar, pero sin pasar datos
    context.push('/admin/crear-lugar');
  }

  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Lugares'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _buildContent(context, vmLugares, vmLugares.lugaresTotales),
          // Overlay de Carga (Spinner)
          if (vmLugares.estaCargandoGestion)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      // Botón flotante para AÑADIR un nuevo lugar
      floatingActionButton: FloatingActionButton(
        onPressed: () => _crearLugar(context),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  // Widget para construir el contenido (lista o mensaje)
  Widget _buildContent(BuildContext context, LugaresVM vmLugares, List<Lugar> lugares) {
    if (lugares.isEmpty && !vmLugares.estaCargandoGestion) {
      return RefreshIndicator(
        onRefresh: () => vmLugares.cargarTodosLosLugares(),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_outlined, color: Colors.grey, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay lugares registrados',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa el botón (+) para añadir el primer lugar.',
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

    // Si SÍ hay lugares, muestra la lista
    return RefreshIndicator(
      onRefresh: () => vmLugares.cargarTodosLosLugares(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding para el FAB
        itemCount: lugares.length,
        itemBuilder: (context, index) {
          final lugar = lugares[index];
          return _buildLugarCard(context, lugar);
        },
      ),
    );
  }

  // Tarjeta para cada lugar
  Widget _buildLugarCard(BuildContext context, Lugar lugar) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Imagen del Lugar
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                lugar.urlImagen,
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 80,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lugar.nombre,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Usamos la info desnormalizada (copiada)
                  Text(
                    '${lugar.categoria} • ${lugar.provinciaId}', // (El mock de lugar no tiene provinciaNombre)
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Botones de Acción
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
              tooltip: 'Editar Lugar',
              onPressed: () => _editarLugar(context, lugar),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
              tooltip: 'Eliminar Lugar',
              onPressed: () => _eliminarLugar(context, lugar),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo de confirmación para eliminar
  void _mostrarDialogoEliminar(BuildContext context, Lugar lugar) {
    final vmLugares = context.read<LugaresVM>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar Lugar?'),
        content: Text('Estás a punto de eliminar permanentemente "${lugar.nombre}". Esta acción no se puede deshacer.'),
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
              vmLugares.eliminarLugar(lugar.id);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}
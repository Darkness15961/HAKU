// --- CARACTERISTICAS/ADMINISTRACION/PRESENTACION/PAGINAS/ADMIN_GESTION_PROVINCIAS_PAGINA.DART ---
//
// Esta es la nueva página para gestionar (ver, editar, eliminar)
// todas las provincias.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';

class AdminGestionProvinciasPagina extends StatefulWidget {
  const AdminGestionProvinciasPagina({super.key});

  @override
  State<AdminGestionProvinciasPagina> createState() => _AdminGestionProvinciasPaginaState();
}

class _AdminGestionProvinciasPaginaState extends State<AdminGestionProvinciasPagina> {
  @override
  void initState() {
    super.initState();
    // Re-cargamos la lista de provincias por si acaso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LugaresVM>().cargarTodasLasProvincias();
    });
  }

  // --- Lógica de Acciones ---
  void _eliminarProvincia(BuildContext context, Provincia provincia) {
    _mostrarDialogoEliminar(context, provincia);
  }

  void _editarProvincia(BuildContext context, Provincia provincia) {
    context.push('/admin/crear-provincia', extra: provincia);
  }

  void _crearProvincia(BuildContext context) {
    context.push('/admin/crear-provincia');
  }

  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Provincias'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Usamos el getter 'provinciasFiltradas' que ya existe
          _buildContent(context, vmLugares, vmLugares.provinciasFiltradas),
          if (vmLugares.estaCargandoGestion)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _crearProvincia(context),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LugaresVM vmLugares, List<Provincia> provincias) {
    if (provincias.isEmpty && !vmLugares.estaCargandoGestion) {
      return RefreshIndicator(
        onRefresh: () => vmLugares.cargarTodasLasProvincias(),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, color: Colors.grey, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay provincias registradas',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa el botón (+) para añadir la primera provincia.',
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

    return RefreshIndicator(
      onRefresh: () => vmLugares.cargarTodasLasProvincias(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: provincias.length,
        itemBuilder: (context, index) {
          final provincia = provincias[index];
          return _buildProvinciaCard(context, provincia);
        },
      ),
    );
  }

  Widget _buildProvinciaCard(BuildContext context, Provincia provincia) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                provincia.urlImagen,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provincia.nombre,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provincia.placesCount} lugares • ${provincia.categories.join(", ")}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
              tooltip: 'Editar Provincia',
              onPressed: () => _editarProvincia(context, provincia),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
              tooltip: 'Eliminar Provincia',
              onPressed: () => _eliminarProvincia(context, provincia),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEliminar(BuildContext context, Provincia provincia) {
    final vmLugares = context.read<LugaresVM>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar Provincia?'),
        content: Text('Estás a punto de eliminar "${provincia.nombre}". Asegúrate de que no haya lugares asociados a esta provincia antes de eliminarla.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Sí, Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Envolvemos la llamada en un try-catch
              try {
                await vmLugares.eliminarProvincia(provincia.id);
                if (mounted) Navigator.of(dialogContext).pop();
              } catch (e) {
                // Si el mock (o Firebase) lanza un error
                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
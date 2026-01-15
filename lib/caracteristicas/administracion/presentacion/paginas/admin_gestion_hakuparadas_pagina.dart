import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vista_modelos/admin_hakuparadas_vm.dart';
import '../../../mapa/dominio/entidades/hakuparada.dart';

class AdminGestionHakuparadasPagina extends StatelessWidget {
  const AdminGestionHakuparadasPagina({super.key});

  @override
  Widget build(BuildContext context) {
    // Ya proveído en main.dart
    return const _PaginaContenido();
  }
}

class _PaginaContenido extends StatelessWidget {
  const _PaginaContenido();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminHakuparadasVM>();
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Gestionar Hakuparadas"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Pendientes", icon: Icon(Icons.pending_actions)),
              Tab(text: "Publicadas", icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: vm.estaCargando 
            ? const Center(child: CircularProgressIndicator()) 
            : TabBarView(
                children: [
                  // TAB 1: PENDIENTES
                  _buildLista(context, vm, vm.pendientes, esPendiente: true),
                  
                  // TAB 2: VERIFICADAS
                  _buildLista(context, vm, vm.verificadas, esPendiente: false),
                ],
              ),
      ),
    );
  }

  Widget _buildLista(BuildContext context, AdminHakuparadasVM vm, List<Hakuparada> lista, {required bool esPendiente}) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(esPendiente ? Icons.check : Icons.public_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              esPendiente ? "¡Todo al día! No hay pendientes." : "No hay paradas publicadas aún.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (ctx, i) {
        final item = lista[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // 1. Cabecera con Foto y Estado
              Stack(
                children: [
                   Container(
                     height: 150,
                     width: double.infinity,
                     decoration: BoxDecoration(
                       borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                       image: DecorationImage(
                         image: NetworkImage(item.fotoReferencia),
                         fit: BoxFit.cover,
                       ),
                     ),
                   ),
                   Positioned(
                     top: 8, right: 8,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                       decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                       child: Text(item.categoria, style: const TextStyle(color: Colors.white, fontSize: 12)),
                     ),
                   ),
                ],
              ),
              
              // 2. Info
              ListTile(
                title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("GPS: ${item.latitud.toStringAsFixed(4)}, ${item.longitud.toStringAsFixed(4)}\n\n${item.descripcion}"),
                isThreeLine: true,
              ),
              
              const Divider(height: 1),
              
              // 3. Acciones
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!esPendiente)
                      IconButton(
                        icon: Icon(
                          item.visible ? Icons.visibility : Icons.visibility_off, 
                          color: item.visible ? Colors.green : Colors.grey
                        ),
                        tooltip: item.visible ? "Visible (Toca para ocultar)" : "Oculto (Toca para activar)",
                        onPressed: () => vm.toggleVisibilidad(item.id, item.visible),
                      ),
                    if (esPendiente)
                      FilledButton.icon(
                        onPressed: () => vm.aprobarHakuparada(item.id),
                        icon: const Icon(Icons.check),
                        label: const Text("APROBAR"),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      
                    const SizedBox(width: 8),
                    
                    OutlinedButton.icon(
                      onPressed: () => _confirmarEliminar(context, vm, item),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: Text(esPendiente ? "RECHAZAR" : "ELIMINAR", style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmarEliminar(BuildContext context, AdminHakuparadasVM vm, Hakuparada item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Estás seguro?"),
        content: Text("Vas a eliminar permanentemente '${item.nombre}'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.eliminarHakuparada(item.id);
            },
            child: const Text("Sí, borrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

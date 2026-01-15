import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../vista_modelos/mis_hakuparadas_vm.dart';
import 'package:xplore_cusco/caracteristicas/mapa/dominio/entidades/hakuparada.dart';

class MisHakuparadasPagina extends StatelessWidget {
  const MisHakuparadasPagina({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MisHakuparadasVM(),
      child: const _CuerpoPagina(),
    );
  }
}

class _CuerpoPagina extends StatelessWidget {
  const _CuerpoPagina();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisHakuparadasVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mis Hakuparadas"),
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Pendientes", icon: Icon(Icons.access_time)),
              Tab(text: "Aprobadas", icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: vm.estaCargando
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildLista(context, vm.misPendientes, esPendiente: true),
                  _buildLista(context, vm.misAprobadas, esPendiente: false),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/crear-hakuparada'),
          icon: const Icon(Icons.add_location_alt),
          label: const Text("Sugerir Nueva"),
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLista(BuildContext context, List<Hakuparada> lista, {required bool esPendiente}) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esPendiente ? Icons.pending_actions : Icons.map,
              size: 60,
              color: Colors.grey[300]
            ),
            const SizedBox(height: 16),
            Text(
              esPendiente 
                  ? "No tienes sugerencias pendientes." 
                  : "Aún no tienes paradas aprobadas.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), // bottom padding for FAB
      itemCount: lista.length,
      itemBuilder: (ctx, i) {
        final item = lista[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.fotoReferencia,
                width: 60, height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
              ),
            ),
            title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.categoria, style: TextStyle(color: Theme.of(context).primaryColor)),
                const SizedBox(height: 4),
                Text(
                  esPendiente ? "Esperando revisión..." : "¡Ya está en el mapa!",
                  style: TextStyle(
                    fontSize: 12, 
                    color: esPendiente ? Colors.orange[700] : Colors.green[700],
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

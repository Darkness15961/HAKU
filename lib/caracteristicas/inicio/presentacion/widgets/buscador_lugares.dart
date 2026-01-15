import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../dominio/entidades/lugar.dart';
import '../vista_modelos/lugares_vm.dart';

class BuscadorLugares extends SearchDelegate {
  final LugaresVM vmLugares;

  BuscadorLugares({required this.vmLugares});

  @override
  String get searchFieldLabel => 'Buscar destinos...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _construirResultados(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _construirResultados(context);
  }

  Widget _construirResultados(BuildContext context) {
    // Si la consulta está vacía, mostrar sugerencias (populares o nada)
    if (query.isEmpty) {
      return _construirSugerenciasVacias(context);
    }

    // Filtrar lugares
    final resultados = vmLugares.lugaresTotales.where((lugar) {
      final nombreLower = lugar.nombre.toLowerCase();
      final queryLower = query.toLowerCase();
      return nombreLower.contains(queryLower);
    }).toList();

    if (resultados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron lugares para "$query"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: resultados.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final lugar = resultados[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              lugar.urlImagen,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image),
            ),
          ),
          title: Text(
            lugar.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            lugar.descripcion,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            // Cerrar el buscador y navegar
            close(context, null); // Importante cerrar primero
            context.push('/inicio/detalle-lugar', extra: lugar);
          },
        );
      },
    );
  }

  Widget _construirSugerenciasVacias(BuildContext context) {
    // Mostrar lugares populares como sugerencia inicial
    final sugerencias = vmLugares.lugaresPopulares;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sugerencias.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Lugares Populares',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: sugerencias.length,
            itemBuilder: (context, index) {
              final lugar = sugerencias[index];
              return ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.amber),
                title: Text(lugar.nombre),
                onTap: () {
                  query = lugar.nombre;
                  showResults(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

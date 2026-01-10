import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import 'route_location.dart';

class SelectorLugaresRuta extends StatefulWidget {
  final List<RouteLocation> locations;
  final Function(List<RouteLocation>) onLocationsChanged;

  const SelectorLugaresRuta({
    super.key,
    required this.locations,
    required this.onLocationsChanged,
  });

  @override
  State<SelectorLugaresRuta> createState() => _SelectorLugaresRutaState();
}

class _SelectorLugaresRutaState extends State<SelectorLugaresRuta> {
  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final List<RouteLocation> newList = List.from(widget.locations);
    final RouteLocation item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    widget.onLocationsChanged(newList);
  }

  void _eliminarLugar(int index) {
    final List<RouteLocation> newList = List.from(widget.locations);
    newList.removeAt(index);
    widget.onLocationsChanged(newList);
  }

  void _mostrarSelectorLugares() {
    final vmLugares = context.read<LugaresVM>();
    final lugaresDisponibles = vmLugares.lugaresTotales;
    List<String> idsSeleccionados = widget.locations
        .map((rl) => rl.lugar.id)
        .toList();

    Set<String> seleccionTemporal = idsSeleccionados.toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  // Header del Modal
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seleccione Lugares',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lugaresDisponibles.length,
                      itemBuilder: (context, index) {
                        final lugar = lugaresDisponibles[index];
                        final estaSeleccionado = seleccionTemporal.contains(
                          lugar.id,
                        );
                        return CheckboxListTile(
                          title: Text(lugar.nombre),
                          value: estaSeleccionado,
                          onChanged: (bool? seleccionado) {
                            setModalState(() {
                              if (seleccionado == true) {
                                seleccionTemporal.add(lugar.id);
                              } else {
                                seleccionTemporal.remove(lugar.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  // Footer del Modal
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Confirmar (${seleccionTemporal.length}) Lugares',
                      ),
                      onPressed: () {
                        // Reconstruimos la lista de objetos RouteLocation
                        final newLocations = seleccionTemporal.map((id) {
                            final lugarEncontrado = lugaresDisponibles
                                .firstWhere((l) => l.id == id);
                            return RouteLocation(lugar: lugarEncontrado);
                          }).toList();
                        
                        widget.onLocationsChanged(newLocations);
                        Navigator.of(modalContext).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lugares en la Ruta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            TextButton.icon(
              onPressed: _mostrarSelectorLugares,
              icon: const Icon(Icons.add),
              label: const Text('Gestionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.locations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Debes seleccionar al menos un lugar para crear la ruta.',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.locations.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final loc = widget.locations[index];
              return Card(
                key: ValueKey(loc.lugar.id), // Clave única para reorderable
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(loc.lugar.urlImagen),
                    onBackgroundImageError: (_, __) {},
                    child: Text('${index + 1}'),
                  ),
                  title: Text(loc.lugar.nombre),
                  // SUBTITULO ELIMINADO
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => _eliminarLugar(index),
                      ),
                      const Icon(Icons.drag_handle, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

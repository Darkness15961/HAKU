// --- PIEDRA 3 (BLOQUE 5): EL "MENÚ" 3 (MAPA) (¡ARREGLADO!) ---
//
// 1. Ahora es un "StatefulWidget"
// 2. Llama a "cargarDatosIniciales()" en el "initState"
//    para "despertar" al "Mesero" perezoso y romper el bucle.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/mapa_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';

// --- ¡ARREGLO! (Convertido a StatefulWidget) ---
class MapaPagina extends StatefulWidget {
  const MapaPagina({super.key});

  @override
  State<MapaPagina> createState() => _MapaPaginaState();
}

class _MapaPaginaState extends State<MapaPagina> {
  // --- Estado Local de la UI ---
  GoogleMapController? _mapController;
  String? _selectedFavoriteId;

  // --- ¡ARREGLO! (Añadimos initState) ---
  //
  // "initState" se ejecuta UNA SOLA VEZ cuando
  // esta pantalla (pestaña) se "construye".
  @override
  void initState() {
    super.initState();
    // Le damos la "primera orden" al "Mesero"
    // para que cargue los datos (y rompa el bucle)
    Future.microtask(() {
      // "context.read" es para "dar una orden"
      context.read<MapaVM>().cargarDatosIniciales();
    });
  }
  // --- FIN DEL ARREGLO ---

  // --- Lógica de Navegación (de tu "molde") ---
  void _panToPlace(Lugar lugar) {
    if (_mapController == null) return;
    setState(() {
      _selectedFavoriteId = lugar.id;
    });
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lugar.latitud, lugar.longitud),
        14.0,
      ),
    );
  }

  void _navigateToDetail(Lugar lugar) {
    context.push('/detalle-lugar', extra: lugar);
  }

  void _centerOnCusco(MapaVM vmMapa) {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(vmMapa.posicionInicialCusco),
    );
    setState(() { _selectedFavoriteId = null; });
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // (El resto del código de "build"
    // es exactamente el mismo que ya teníamos)

    final vmMapa = context.watch<MapaVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Interactivo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorPrimario,
        elevation: 0,
      ),
      body: vmMapa.estaCargando
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: vmMapa.posicionInicialCusco,
            markers: vmMapa.marcadores,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
          ),

          Positioned(
            left: 16,
            bottom: vmMapa.mostrarCarrusel ? 200 : 100,
            child: FloatingActionButton(
              onPressed: () => _centerOnCusco(vmMapa),
              backgroundColor: colorPrimario,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location, size: 28),
            ),
          ),

          if (vmMapa.mostrarCarrusel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFavoritesCarousel(
                context,
                vmMapa.lugaresFavoritos,
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Sin cambios) ---
  Widget _buildFavoritesCarousel(
      BuildContext context, List<Lugar> lugaresFavoritos) {
    return Container(
      height: 180,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Mis Lugares Favoritos',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lugaresFavoritos.length,
              itemBuilder: (context, index) {
                final lugar = lugaresFavoritos[index];
                final isSelected = lugar.id == _selectedFavoriteId;
                return _buildFavoriteCard(context, lugar, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Lugar lugar, bool isSelected) {
    return GestureDetector(
      onTap: () => _panToPlace(lugar),
      child: Container(
        width: 150,
        margin: EdgeInsets.only(
            left: 16,
            right: (context.read<MapaVM>().lugaresFavoritos.last == lugar)
                ? 16
                : 0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 3 : 1,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  lugar.urlImagen,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Center(
                        child: Icon(Icons.image_search,
                            size: 30, color: Colors.grey[400])),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _navigateToDetail(lugar),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  lugar.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
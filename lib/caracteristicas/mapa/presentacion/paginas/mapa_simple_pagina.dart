// --- CARACTERISTICAS/MAPA/PRESENTACION/PAGINAS/MAPA_SIMPLE_PAGINA.DART ---
//
// Esta es una nueva página de mapa simple que se usa para mostrar
// la ubicación de un lugar específico y PERMITE retroceder.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';

class MapaSimplePagina extends StatelessWidget {
  final Lugar lugar;

  const MapaSimplePagina({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    // 1. Define la posición inicial de la cámara
    final CameraPosition _posicionLugar = CameraPosition(
      target: LatLng(lugar.latitud, lugar.longitud),
      zoom: 15, // Un zoom más cercano
    );

    // 2. Crea el marcador para el lugar
    final Set<Marker> _marcador = {
      Marker(
        markerId: MarkerId(lugar.id),
        position: LatLng(lugar.latitud, lugar.longitud),
        infoWindow: InfoWindow(
          title: lugar.nombre,
          snippet: lugar.categoria,
        ),
      ),
    };

    return Scaffold(
      // 3. El AppBar que SÍ tiene flecha de retroceso
      appBar: AppBar(
        title: Text(lugar.nombre),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // 4. El cuerpo es solo el mapa
      body: GoogleMap(
        initialCameraPosition: _posicionLugar,
        markers: _marcador,
        mapType: MapType.satellite, // Lo ponemos en satélite para que se vea mejor
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }
}
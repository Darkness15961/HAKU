// --- CARACTERISTICAS/MAPA/PRESENTACION/PAGINAS/MAPA_SIMPLE_PAGINA.DART ---
// Versión: OpenStreetMap + Caché Propio
//
// Este archivo es el "Visor Sencillo".
// Solo recibe un Lugar y muestra su ubicación con un pin rojo.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Motor OSM
import 'package:latlong2/latlong.dart';      // Coordenadas
import 'package:cached_network_image/cached_network_image.dart'; // Para la foto del pin

// Entidad
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';

// NUESTRO MOTOR DE CACHÉ (Asegúrate de importar esto)
import '../widgets/cached_tile_provider.dart';

class MapaSimplePagina extends StatelessWidget {
  final Lugar lugar;

  const MapaSimplePagina({super.key, required this.lugar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar
      appBar: AppBar(
        title: Text(lugar.nombre),
        // Usamos colores por defecto del tema para no complicar
      ),

      // 2. El Mapa
      body: FlutterMap(
        options: MapOptions(
          // Centramos el mapa en las coordenadas del lugar
          initialCenter: LatLng(lugar.latitud, lugar.longitud),
          initialZoom: 15.0,
        ),
        children: [
          // A. Capa de Azulejos (Con Caché)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.xplorecusco.app',
            // Usamos el mismo motor de caché que creamos en el Paso 2
            tileProvider: CachedTileProvider(),
          ),

          // B. Capa de Marcadores (El Pin)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lugar.latitud, lugar.longitud),
                width: 60,
                height: 60,
                alignment: Alignment.center, // Centrado sobre el punto
                child: _buildPin(lugar),
              ),
            ],
          ),

          // C. Créditos
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }

  // Pin sencillo con la foto del lugar
  Widget _buildPin(Lugar lugar) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))
            ],
            // Foto con caché
            image: DecorationImage(
              image: CachedNetworkImageProvider(lugar.urlImagen),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Triangulito del pin
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
              width: 10,
              height: 8,
              color: Colors.red
          ),
        ),
      ],
    );
  }
}

// Clase para dibujar el piquito del pin (Misma que usas en el mapa principal)

class _TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final ui.Path path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}
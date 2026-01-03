import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Motor OSM
import 'package:latlong2/latlong.dart';      // Coordenadas
import 'package:go_router/go_router.dart';

class SelectorUbicacionPagina extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const SelectorUbicacionPagina({super.key, this.ubicacionInicial});

  @override
  State<SelectorUbicacionPagina> createState() =>
      _SelectorUbicacionPaginaState();
}

class _SelectorUbicacionPaginaState extends State<SelectorUbicacionPagina> {
  LatLng? _ubicacionSeleccionada;
  late LatLng _centroInicial;

  @override
  void initState() {
    super.initState();
    _centroInicial = widget.ubicacionInicial ?? const LatLng(-13.5167, -71.9781);

    if (widget.ubicacionInicial != null) {
      _ubicacionSeleccionada = widget.ubicacionInicial;
    }
  }

  void _onTapMapa(TapPosition tapPosition, LatLng point) {
    setState(() {
      _ubicacionSeleccionada = point;
    });
  }

  void _confirmarSeleccion() {
    if (_ubicacionSeleccionada != null) {
      context.pop(_ubicacionSeleccionada);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toca el mapa para marcar una ubicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmarSeleccion,
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _centroInicial,
              initialZoom: 15.0,
              onTap: _onTapMapa,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.xplorecusco.app',
              ),
              if (_ubicacionSeleccionada != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionSeleccionada!,
                      width: 60,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              ),
            ],
          ),
          if (_ubicacionSeleccionada != null)
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: ElevatedButton(
                onPressed: _confirmarSeleccion,
                child: const Text('Confirmar Ubicación'),
              ),
            ),
        ],
      ),
    );
  }
}
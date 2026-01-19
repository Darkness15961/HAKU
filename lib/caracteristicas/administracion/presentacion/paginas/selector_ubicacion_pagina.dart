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
  final MapController _mapController = MapController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _centroInicial = widget.ubicacionInicial ?? const LatLng(-13.5167, -71.9781);

    if (widget.ubicacionInicial != null) {
      _ubicacionSeleccionada = widget.ubicacionInicial;
      _latCtrl.text = widget.ubicacionInicial!.latitude.toString();
      _lngCtrl.text = widget.ubicacionInicial!.longitude.toString();
    }
  }
  
  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onTapMapa(TapPosition tapPosition, LatLng point) {
    setState(() {
      _ubicacionSeleccionada = point;
      // También actualizamos los inputs visualmente
      _latCtrl.text = point.latitude.toStringAsFixed(6);
      _lngCtrl.text = point.longitude.toStringAsFixed(6);
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

  void _buscarPorCoordenadasSeparadas() {
    final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.').trim());
    final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.').trim());

    if (lat != null && lng != null) {
      final nuevoPunto = LatLng(lat, lng);
      
      setState(() {
         _ubicacionSeleccionada = nuevoPunto;
      });
      _mapController.move(nuevoPunto, 16.0);
      
      FocusScope.of(context).unfocus();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordenadas inválidas. Solo números.')),
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
            mapController: _mapController,
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
          
          // Panel de Búsqueda de Coordenadas
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pegar Coordenadas (desde Google Maps)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Latitud (o pegar todo aquí)',
                              hintText: '-13.51...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            onChanged: (val) {
                              // LOGICA "SMART PASTE": Si el usuario pega "lat, lung", lo separamos solo
                              if (val.contains(',')) {
                                final partes = val.split(',');
                                if (partes.length == 2) {
                                  _latCtrl.text = partes[0].trim();
                                  _lngCtrl.text = partes[1].trim();
                                  _buscarPorCoordenadasSeparadas(); // Auto-buscar
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _lngCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Longitud',
                              hintText: '-71.97...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _buscarPorCoordenadasSeparadas,
                          style: IconButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.search, color: Colors.white),
                          tooltip: 'Ubicar',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_ubicacionSeleccionada != null)
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: ElevatedButton(
                onPressed: _confirmarSeleccion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirmar Ubicación'),
              ),
            ),
        ],
      ),
    );
  }
}
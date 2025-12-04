import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

class SelectorUbicacionPagina extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const SelectorUbicacionPagina({super.key, this.ubicacionInicial});

  @override
  State<SelectorUbicacionPagina> createState() => _SelectorUbicacionPaginaState();
}

class _SelectorUbicacionPaginaState extends State<SelectorUbicacionPagina> {
  LatLng? _ubicacionSeleccionada;
  late CameraPosition _posicionInicial;

  @override
  void initState() {
    super.initState();
    // Si recibimos una ubicación, la usamos. Si no, default a Cusco Plaza de Armas
    final lat = widget.ubicacionInicial?.latitude ?? -13.5167;
    final lng = widget.ubicacionInicial?.longitude ?? -71.9781;
    
    _posicionInicial = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 15,
    );

    if (widget.ubicacionInicial != null) {
      _ubicacionSeleccionada = widget.ubicacionInicial;
    }
  }

  void _onTapMapa(LatLng position) {
    setState(() {
      _ubicacionSeleccionada = position;
    });
  }

  void _confirmarSeleccion() {
    if (_ubicacionSeleccionada != null) {
      context.pop(_ubicacionSeleccionada);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor toca el mapa para seleccionar una ubicación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmarSeleccion,
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _posicionInicial,
            onTap: _onTapMapa,
            markers: _ubicacionSeleccionada != null
                ? {
                    Marker(
                      markerId: const MarkerId('seleccion'),
                      position: _ubicacionSeleccionada!,
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_ubicacionSeleccionada != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ubicación Seleccionada',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_ubicacionSeleccionada!.latitude.toStringAsFixed(5)}\nLng: ${_ubicacionSeleccionada!.longitude.toStringAsFixed(5)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _confirmarSeleccion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirmar Ubicación'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

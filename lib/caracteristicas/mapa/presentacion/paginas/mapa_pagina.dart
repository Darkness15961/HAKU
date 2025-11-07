// --- PIEDRA 7 (MAPA): EL "MENÚ" DE MAPA (SOLUCIÓN MEDIADORA) ---
//
// Se vuelve StatefulWidget para "despertar" al MapaVM.
// En initState, le pasa las dependencias (LugaresVM y AuthVM).
//
// --- CAMBIOS ---
// - Corregido 'lugar.urlImagenPrincipal' a 'lugar.urlImagen'
//   para coincidir con la entidad Lugar.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/mapa_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';

// --- Convertimos de StatelessWidget a StatefulWidget ---
class MapaPagina extends StatefulWidget {
  const MapaPagina({super.key});

  @override
  State<MapaPagina> createState() => _MapaPaginaState();
}

class _MapaPaginaState extends State<MapaPagina> {
  // --- LÓGICA DE CARGA MEDIADORA (NUEVO) ---
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // 1. Obtenemos los VMs (sin escuchar)
      final vmAuth = context.read<AutenticacionVM>();
      final vmLugares = context.read<LugaresVM>();
      final vmMapa = context.read<MapaVM>();

      // 2. Le pasamos las dependencias al MapaVM
      vmMapa.cargarDatosIniciales(vmLugares, vmAuth);
    });
  }

  // (Coordenadas de Cusco)
  final CameraPosition _posicionInicial = const CameraPosition(
    target: LatLng(-13.52264, -71.96734),
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    // Escuchamos al MapaVM
    final vmMapa = context.watch<MapaVM>();

    return Scaffold(
      body: Stack(
        children: [
          // El Mapa
          vmMapa.estaCargando
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: _posicionInicial,
            markers: vmMapa.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // El carrusel de favoritos (solo si no está cargando)
          if (!vmMapa.estaCargando && vmMapa.favoritos.isNotEmpty)
            _buildCarruselFavoritos(vmMapa.favoritos),
        ],
      ),
    );
  }

  // Widget para el carrusel
  Widget _buildCarruselFavoritos(List<Lugar> favoritos) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.8),
          itemCount: favoritos.length,
          itemBuilder: (context, index) {
            final lugar = favoritos[index];
            return InkWell(
              onTap: () {
                // TODO: Navegar al detalle del lugar
                // context.push('/detalle-lugar', extra: lugar);
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    Image.network(
                      // --- ¡CORREGIDO! ---
                      lugar.urlImagen,
                      width: 100,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 100, height: 120, color: Colors.grey[200]),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lugar.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lugar.categoria,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
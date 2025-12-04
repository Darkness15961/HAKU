import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/mapa_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';

class MapaPagina extends StatefulWidget {
  const MapaPagina({super.key});

  @override
  State<MapaPagina> createState() => _MapaPaginaState();
}

class _MapaPaginaState extends State<MapaPagina> {
  final CameraPosition _posicionInicial = const CameraPosition(
    target: LatLng(-13.52264, -71.96734), // Cusco
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vmMapa = context.read<MapaVM>();
        final vmLugares = context.read<LugaresVM>();
        final vmAuth = context.read<AutenticacionVM>();
        final vmRutas = context.read<RutasVM>();
        vmMapa.actualizarDependencias(vmLugares, vmAuth, vmRutas);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vmMapa = context.watch<MapaVM>();
    final double topPadding = MediaQuery.of(context).padding.top;

    // Marcadores + Mi Ubicación
    final Set<Marker> allMarkers = {
      ...vmMapa.markers,
      if (vmMapa.currentLocation != null)
        Marker(
          markerId: const MarkerId("user_position"),
          position: vmMapa.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          zIndex: 2,
          infoWindow: const InfoWindow(title: "Yo"),
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // 1. EL MAPA DE FONDO
          GoogleMap(
            initialCameraPosition: _posicionInicial,
            markers: allMarkers,
            polylines: vmMapa.polylines,
            mapType: vmMapa.currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true, // Habilitar zoom con gestos y botones
            compassEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              if (mounted) vmMapa.setNewMapController(controller);
            },
            onTap: (_) => vmMapa.cerrarDetalle(),
          ),

          // 2. SPINNER DE CARGA
          if (vmMapa.estaCargando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // 3. FILTROS FLOTANTES (Superior)
          Positioned(
            top: topPadding + 10,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(context, 'Explorar Todo', 0, vmMapa),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, '📸 Mis Recuerdos', 1, vmMapa),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, '❤️ Por Visitar', 2, vmMapa),
                ],
              ),
            ),
          ),

          // 4. BOTONES LATERALES (Derecha)
          Positioned(
            top: topPadding + 80,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_type',
                  backgroundColor: Colors.white,
                  child: Icon(
                    vmMapa.currentMapType == MapType.normal
                        ? Icons.satellite_alt
                        : Icons.map_outlined,
                    color: Colors.black87,
                  ),
                  onPressed: vmMapa.toggleMapType,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'gps',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                  onPressed: vmMapa.enfocarMiUbicacion,
                ),
                const SizedBox(height: 20),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                  onPressed: vmMapa.zoomIn,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                  onPressed: vmMapa.zoomOut,
                ),
              ],
            ),
          ),

          // 5. CAPA DE FONDO OSCURO (Animación FADE)
          // Esta capa solo oscurece, no contiene la foto
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: vmMapa.lugarSeleccionado != null
                  ? GestureDetector(
                      onTap: () => vmMapa.cerrarDetalle(),
                      child: Container(
                        key: const ValueKey('background_overlay'),
                        color: Colors.black.withOpacity(0.6),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // 6. CAPA DE LA POLAROID (Animación SCALE/CRECER)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              reverseDuration: const Duration(milliseconds: 300),
              // Curva "Rebote" para que se sienta que crece con energía
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInBack,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: vmMapa.lugarSeleccionado != null
                  ? _buildPolaroidCard(
                      context,
                      vmMapa.lugarSeleccionado!,
                      vmMapa,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    int index,
    MapaVM vm,
  ) {
    final bool isSelected = vm.filtroActual == index;
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => vm.cambiarFiltro(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorPrimario : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // --- DISEÑO POLAROID FINAL (Centrado) ---
  Widget _buildPolaroidCard(BuildContext context, Lugar lugar, MapaVM vm) {
    // Usamos Key para que AnimatedSwitcher sepa que es el mismo widget
    return Center(
      key: ValueKey(lugar.id),
      child: Transform.rotate(
        angle: -0.05, // Inclinación "casual"
        child: Stack(
          clipBehavior: Clip
              .none, // Para que el botón de cerrar pueda salirse si queremos
          children: [
            Container(
              width:
                  MediaQuery.of(context).size.width *
                  0.80, // Ancho de la Polaroid
              // Padding asimétrico: Mucho espacio abajo para "escribir"
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  4,
                ), // Bordes casi rectos (papel)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. LA FOTO (Cuadrada)
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Image.network(
                        lugar.urlImagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. TEXTO MANUSCRITO (Nombre)
                  Text(
                    lugar.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Serif', // Fuente clásica
                      fontStyle: FontStyle.italic, // Simula escritura
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. DETALLES PEQUEÑOS
                  Text(
                    " • ${lugar.rating} ★",
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. BOTÓN "VER DETALLES" (Discreto)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navegar al detalle real
                        context.push('/inicio/detalle-lugar', extra: lugar);
                        // Opcional: Cerrar el popup después de navegar
                        // vm.cerrarDetalle();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Ver Detalles del Recuerdo"),
                    ),
                  ),
                ],
              ),
            ),

            // Botón de cerrar (X) flotando en la esquina
            Positioned(
              top: -10,
              right: -10,
              child: GestureDetector(
                onTap: () => vm.cerrarDetalle(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

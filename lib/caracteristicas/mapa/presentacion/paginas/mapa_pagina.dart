

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Para navegar al login

// ViewModel
import '../vista_modelos/mapa_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';

// WIDGETS
import '../widgets/tarjeta_polaroid.dart';
import '../widgets/filtro_chip.dart';
import '../widgets/cached_tile_provider.dart';

class MapaPagina extends StatefulWidget {
  const MapaPagina({super.key});

  @override
  State<MapaPagina> createState() => _MapaPaginaState();
}

class _MapaPaginaState extends State<MapaPagina> with TickerProviderStateMixin {
  late AnimationController _cardAnimController;
  late Animation<double> _cardScaleAnimation;
  bool _verRelieve = false;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardScaleAnimation = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOutBack,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vmMapa = context.read<MapaVM>();
        vmMapa.actualizarDependencias(
            context.read<LugaresVM>(),
            context.read<AutenticacionVM>(),
            context.read<RutasVM>()
        );
      }
    });
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  void _alternarTipoMapa() {
    setState(() => _verRelieve = !_verRelieve);
  }  String _obtenerUrlMapa() {
    return _verRelieve
        ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }



  // --- NUEVA FUNCIÓN: DIÁLOGO DE BLOQUEO ---
  // Muestra la ventana idéntica a tu captura de pantalla
  void _mostrarDialogoBloqueo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Ícono del Candado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA), // Cian clarito
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Color(0xFF00BCD4), size: 32),
              ),
              const SizedBox(height: 16),

              // 2. Título
              const Text(
                "Acción Requerida",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BCD4)
                ),
              ),
              const SizedBox(height: 12),

              // 3. Texto descriptivo
              const Text(
                "Necesitas iniciar sesión o crear una cuenta para acceder a tus recuerdos y favoritos.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 24),

              // 4. Botones
              Column(
                children: [
                  // Botón "Seguir Explorando" (Cierra el diálogo)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Seguir Explorando",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Botón "Iniciar Sesión" (Te lleva al login)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Cierra diálogo
                        context.push('/login'); // Navega al login
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text("Iniciar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Función auxiliar para verificar login antes de cambiar filtro
  void _intentarCambiarFiltro(int indice) {
    final mapaVM = context.read<MapaVM>();
    final authVM = context.read<AutenticacionVM>();

    if (indice == 0) {
      // "Explorar" siempre es público
      mapaVM.cambiarFiltro(0);
    } else {
      // "Recuerdos" (1) y "Favoritos" (2) requieren Login
      if (authVM.usuarioActual != null) {
        mapaVM.cambiarFiltro(indice);
      } else {
        _mostrarDialogoBloqueo(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapaVM = context.watch<MapaVM>();
    final theme = Theme.of(context);

    if (mapaVM.lugarSeleccionado != null && !_cardAnimController.isCompleted) {
      _cardAnimController.forward();
    } else if (mapaVM.lugarSeleccionado == null && _cardAnimController.isCompleted) {
      _cardAnimController.reverse();
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA
          FlutterMap(
            mapController: mapaVM.mapController,
            options: MapOptions(
              initialCenter: const LatLng(-13.5167, -71.9781),
              initialZoom: 13.0,
              onTap: (_, __) {
                if (mapaVM.lugarSeleccionado != null) {
                  _cardAnimController.reverse().then((_) => mapaVM.cerrarDetalle());
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _obtenerUrlMapa(),
                userAgentPackageName: 'com.xplorecusco.app',
                subdomains: const ['a', 'b', 'c'],
                tileProvider: CachedTileProvider(),
              ),
              if (mapaVM.polylines.isNotEmpty) PolylineLayer(polylines: mapaVM.polylines),
              MarkerLayer(markers: mapaVM.markers),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap | OpenTopoMap')],
              ),
            ],
          ),

          // 2. CARGA
          if (mapaVM.estaCargando)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),

          // 3. BARRA FILTROS (CON VERIFICACIÓN DE LOGIN)
          Positioned(
            top: 50, left: 0, right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Filtro 0: Explorar (Público)
                  FiltroChip(
                      label: "Explorar",
                      icon: Icons.map,
                      isSelected: mapaVM.filtroActual == 0,
                      onTap: () => _intentarCambiarFiltro(0) // <--- Cambio aquí
                  ),
                  const SizedBox(width: 8),

                  // Filtro 1: Recuerdos (Privado)
                  FiltroChip(
                      label: "Recuerdos",
                      icon: Icons.photo_camera,
                      isSelected: mapaVM.filtroActual == 1,
                      onTap: () => _intentarCambiarFiltro(1) // <--- Cambio aquí
                  ),
                  const SizedBox(width: 8),

                  // Filtro 2: Favoritos (Privado)
                  FiltroChip(
                      label: "Por Visitar",
                      icon: Icons.favorite,
                      isSelected: mapaVM.filtroActual == 2,
                      onTap: () => _intentarCambiarFiltro(2) // <--- Cambio aquí
                  ),
                ],
              ),
            ),
          ),

          // 4. BOTONES FLOTANTES
          Positioned(
            right: 16,
            bottom: mapaVM.lugarSeleccionado != null ? 350 : 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "btn_layers",
                  onPressed: _alternarTipoMapa,
                  backgroundColor: Colors.white,
                  child: Icon(_verRelieve ? Icons.landscape : Icons.layers, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "btn_gps",
                  onPressed: () => mapaVM.enfocarMiUbicacion(),
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "btn_zoom_in",
                  onPressed: () => mapaVM.zoomIn(),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "btn_zoom_out",
                  onPressed: () => mapaVM.zoomOut(),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
              ],
            ),
          ),

          // 5. TARJETA POLAROID
          if (mapaVM.lugarSeleccionado != null)
            Positioned(
              bottom: 30, left: 20, right: 20,
              child: ScaleTransition(
                scale: _cardScaleAnimation,
                child: TarjetaPolaroid(
                  lugar: mapaVM.lugarSeleccionado!,
                  onCerrar: () {
                    _cardAnimController.reverse().then((_) => mapaVM.cerrarDetalle());
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
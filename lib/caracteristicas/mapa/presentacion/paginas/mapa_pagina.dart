// --- CARACTERISTICAS/MAPA/PRESENTACION/PAGINAS/MAPA_PAGINA.DART ---
// Versión: FINAL (Con Filtro de Rutas y Carrusel OSRM)

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

// Entidades (¡Importante para leer las rutas!)
import '../../../rutas/dominio/entidades/ruta.dart';

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
        // Le pasamos RutasVM también
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
  }

  String _obtenerUrlMapa() {
    return _verRelieve
        ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  // --- DIÁLOGO DE BLOQUEO (Tu código original) ---
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7FA), // Cian clarito
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Color(0xFF00BCD4), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Acción Requerida",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BCD4)
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Necesitas iniciar sesión o crear una cuenta para acceder a tus recuerdos, favoritos y rutas.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Seguir Explorando",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/login');
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

  // --- LÓGICA DE FILTROS ACTUALIZADA ---
  void _intentarCambiarFiltro(int indice) {
    final mapaVM = context.read<MapaVM>();
    final authVM = context.read<AutenticacionVM>();

    if (indice == 0) {
      // "Explorar" siempre es público
      mapaVM.cambiarFiltro(0);
    } else {
      // 1: Recuerdos, 2: Favoritos, 3: Rutas -> Requieren Login
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
    final rutasVM = context.watch<RutasVM>(); // <--- ESCUCHAMOS RUTAS
    final theme = Theme.of(context);

    // Animación de tarjeta
    if (mapaVM.lugarSeleccionado != null && !_cardAnimController.isCompleted) {
      _cardAnimController.forward();
    } else if (mapaVM.lugarSeleccionado == null && _cardAnimController.isCompleted) {
      _cardAnimController.reverse();
    }

    // Calculamos la posición de los botones flotantes
    // Si hay tarjeta (Polaroid) o Carrusel de Rutas, subimos los botones.
    double bottomPositionButtons = 120;
    if (mapaVM.lugarSeleccionado != null) {
      bottomPositionButtons = 350; // Altura para Polaroid
    } else if (mapaVM.filtroActual == 3) {
      bottomPositionButtons = 200; // Altura para Carrusel de Rutas
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
              // Pintamos la Línea Azul OSRM (si existe)
              if (mapaVM.polylines.isNotEmpty) PolylineLayer(polylines: mapaVM.polylines),
              MarkerLayer(markers: mapaVM.markers),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('OpenStreetMap | OpenTopoMap')],
              ),
            ],
          ),

          // 2. LOADING
          if (mapaVM.estaCargando)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),

          // 3. BARRA DE FILTROS (Con el nuevo botón "Rutas")
          Positioned(
            top: 50, left: 0, right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FiltroChip(
                      label: "Explorar",
                      icon: Icons.map,
                      isSelected: mapaVM.filtroActual == 0,
                      onTap: () => _intentarCambiarFiltro(0)
                  ),
                  const SizedBox(width: 8),
                  FiltroChip(
                      label: "Recuerdos",
                      icon: Icons.photo_camera,
                      isSelected: mapaVM.filtroActual == 1,
                      onTap: () => _intentarCambiarFiltro(1)
                  ),
                  const SizedBox(width: 8),
                  FiltroChip(
                      label: "Por Visitar",
                      icon: Icons.favorite,
                      isSelected: mapaVM.filtroActual == 2,
                      onTap: () => _intentarCambiarFiltro(2)
                  ),
                  const SizedBox(width: 8),
                  // --- ¡NUEVO FILTRO DE RUTAS! ---
                  FiltroChip(
                      label: "Mis Rutas",
                      icon: Icons.alt_route, // Icono de ruta
                      isSelected: mapaVM.filtroActual == 3,
                      onTap: () => _intentarCambiarFiltro(3)
                  ),
                ],
              ),
            ),
          ),

          // 4. BOTONES FLOTANTES (Posición dinámica)
          Positioned(
            right: 16,
            bottom: bottomPositionButtons,
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

          // 5. CONTENIDO INFERIOR: TARJETA POLAROID O CARRUSEL DE RUTAS
          if (mapaVM.lugarSeleccionado != null)
          // A) MOSTRAR POLAROID (Prioridad Alta)
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
            )
          else if (mapaVM.filtroActual == 3)
          // B) MOSTRAR CARRUSEL DE RUTAS (Si el filtro es 3)
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: _buildCarruselRutas(context, mapaVM, rutasVM),
            ),
        ],
      ),
    );
  }

  // --- NUEVO WIDGET: CARRUSEL DE RUTAS ---
  Widget _buildCarruselRutas(BuildContext context, MapaVM mapaVM, RutasVM rutasVM) {
    final misRutas = rutasVM.misRutasInscritas;

    if (misRutas.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: const Text(
          "No tienes rutas inscritas.\n¡Ve a Explorar e inscríbete en una!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 140, // Altura del carrusel
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: misRutas.length,
        itemBuilder: (context, index) {
          final ruta = misRutas[index];
          return GestureDetector(
            onTap: () {
              // AL TOCAR: Pintamos la ruta en el mapa
              final lugaresVM = context.read<LugaresVM>();
              mapaVM.enfocarRutaEnMapa(ruta, lugaresVM.lugaresTotales);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                image: DecorationImage(
                  image: NetworkImage(ruta.urlImagenPrincipal),
                  fit: BoxFit.cover,
                  // Oscurecemos un poco la imagen para que se lea el texto
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      ruta.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.directions_car, color: Colors.cyanAccent, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          ruta.distanciaMetros > 0
                              ? "${(ruta.distanciaMetros / 1000).toStringAsFixed(1)} km"
                              : "Ver recorrido",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
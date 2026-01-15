import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para ImageFilter
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// ViewModels
import '../vista_modelos/mapa_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';

// Entidades
import '../../../rutas/dominio/entidades/ruta.dart';

// Widgets
import '../widgets/tarjeta_polaroid.dart';
import '../widgets/filtro_chip.dart';
import '../widgets/cached_tile_provider.dart';
import '../widgets/indicador_scroll.dart';
import '../widgets/panel_rutas.dart';

class MapaPagina extends StatefulWidget {
  const MapaPagina({super.key});

  @override
  State<MapaPagina> createState() => _MapaPaginaState();
}

class _MapaPaginaState extends State<MapaPagina> with TickerProviderStateMixin {
  late AnimationController _cardAnimController;
  late Animation<double> _cardScaleAnimation;

  late PageController _pageController;
  double _currentPageValue = 0.0;

  bool _verRelieve = false;
  int _subFiltroRuta = 0;
  bool _isRutasExpanded = false; // Nuevo estado para expansión
  final ScrollController _filtrosScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _cardScaleAnimation = CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutBack);


    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vmMapa = context.read<MapaVM>();
        vmMapa.updateDependencies(
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
    _filtrosScrollController.dispose();
    super.dispose();
  }

  void _alternarTipoMapa() => setState(() => _verRelieve = !_verRelieve);

  String _obtenerUrlMapa() {
    return _verRelieve
        ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  void _intentarCambiarFiltro(int indice) {
    final mapaVM = context.read<MapaVM>();
    final authVM = context.read<AutenticacionVM>();

    if (indice == 0) {
      mapaVM.setFiltro(0);
    } else {
      if (authVM.usuarioActual != null) {
        mapaVM.setFiltro(indice);
        if (indice == 3) setState(() => _subFiltroRuta = 0);
      } else {
        _mostrarDialogoBloqueo(context);
      }
    }
  }

  void _mostrarDialogoBloqueo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Acción Requerida"),
        content: const Text("Necesitas iniciar sesión para ver esta sección."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); context.push('/login'); },
            child: const Text("Iniciar Sesión"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapaVM = context.watch<MapaVM>();
    final rutasVM = context.watch<RutasVM>();
    final authVM = context.watch<AutenticacionVM>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;
        final isLandscape = screenWidth > screenHeight;
        final size = Size(screenWidth, screenHeight);


        // --- CÁLCULO VIEWPORT CARRUSEL ---
        // Adapta el ancho de las tarjetas ("Efecto Chicle" corregido)
        // Portrait (~380px): 340/380 = 0.9 | Landscape (~800px): 340/800 = 0.42
        final double carruselViewportFraction = (340.0 / screenWidth).clamp(0.4, 0.9);

        // ANIMACIÓN DE TARJETA
        if (mapaVM.lugarSeleccionado != null && !_cardAnimController.isCompleted) {
          _cardAnimController.forward();
        } else if (mapaVM.lugarSeleccionado == null && _cardAnimController.isCompleted) {
          _cardAnimController.reverse();
        }

        // LÓGICA DE RUTAS
         List<Ruta> rutasAMostrar = [];
        if (mapaVM.filtroActual == 3) {
          if (_subFiltroRuta == 0) {
            rutasAMostrar = rutasVM.misRutasInscritas;
          } else {
            final uid = authVM.usuarioActual?.id;
            if (uid != null) {
              rutasAMostrar = rutasVM.rutasFiltradas.where((r) => r.guiaId == uid).toList();
            }
          }
        }

        // Si cambiamos de filtro y no es rutas, colapsamos por seguridad
        if (mapaVM.filtroActual != 3 && _isRutasExpanded) {
             _isRutasExpanded = false;
        }

        // --- POSICIONAMIENTO DINÁMICO DE BOTONES FLOTANTES ---
        double bottomButtons = 140; // Base un poco más arriba (+20px)
        double rightButtons = 16;

        if (isLandscape) {
          // EN LANDSCAPE
          if (_isRutasExpanded) {
             bottomButtons = size.height * 0.7 + 30; 
          } else if (mapaVM.filtroActual == 3) {
             // Carrusel visible (ahora más pequeño: 110px).
             // Botones: 110 + 20 margen = 130px.
             bottomButtons = 140; // Dejamos 140 para asegurar "aire"
          } else if (mapaVM.lugarSeleccionado != null) {
             // Subimos un poco más de 20 a 50
             bottomButtons = 50;
          } else {
             bottomButtons = 50;
          }
        } else {
          // EN PORTRAIT
          if (_isRutasExpanded) {
             bottomButtons = size.height * 0.7 + 30;
          } else if (mapaVM.filtroActual == 3) {
             // Carrusel visible (ahora 140px).
             // Botones: 140 + 20 (margen) + bottomBar (si hay) -> Pongamos 180 + safeArea
             bottomButtons = 260; // Subimos más (+20px respecto al anterior 240)
          } else if (mapaVM.lugarSeleccionado != null) {
             // Polaroid visible.
             bottomButtons = 380; // +20px
          } else {
             // Estado normal
             bottomButtons = 160; // +20px base
          }
        }

        return Scaffold(
          resizeToAvoidBottomInset: false, // Evitar problemas con teclado si hubiera
          body: Stack(
            children: [
              // 1. MAPA
              FlutterMap(
                mapController: mapaVM.mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-13.5167, -71.9781),
                  initialZoom: 13.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Evitar rotación accidental
                  ),
                  onTap: (_, __) {
                    if (mapaVM.lugarSeleccionado != null) {
                      _cardAnimController.reverse().then((_) => mapaVM.cerrarDetalle());
                    }
                  },
                ),
                children: [
                   TileLayer(
                    urlTemplate: _obtenerUrlMapa(),
                    userAgentPackageName: 'com.xplorecusco.app',
                    tileProvider: CachedTileProvider(),
                  ),
                  if (mapaVM.polylines.isNotEmpty) ...[
                    PolylineLayer(polylines: mapaVM.polylines),
                  ],

                  // 1.5 CAPA DE HAKUPARADAS (Debajo de los principales)
                  MarkerLayer(markers: mapaVM.hakuparadaMarkers), // ✅ NUEVA CAPA
                    
                  // CAPA DE MARCADORES PRINCIPALES
                  MarkerLayer(
                    markers: [
                      if (mapaVM.currentLocation != null)
                        Marker(
                          point: mapaVM.currentLocation!,
                          width: 25,
                          height: 25,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                            ),
                          ),
                        ),
                      ...mapaVM.markers,
                    ],
                  ),
                ],
              ),

              if (mapaVM.estaCargando) const Center(child: CircularProgressIndicator()),

              // 2. FILTROS SUPERIORES (Adaptable)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 0, 
                right: isLandscape ? 80 : 0, 
                child: IndicadorScroll( // Envolvemos con el nuevo indicador
                  scrollController: _filtrosScrollController,
                  child: SingleChildScrollView(
                    controller: _filtrosScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        FiltroChip(label: "Explorar", icon: Icons.map_outlined, isSelected: mapaVM.filtroActual == 0, onTap: () => _intentarCambiarFiltro(0)),
                        const SizedBox(width: 8),
                        // [REMOVIDO: Toggle Hakuparadas movido a FAB]
                        FiltroChip(label: "Recuerdos", icon: Icons.camera_alt_outlined, isSelected: mapaVM.filtroActual == 1, onTap: () => _intentarCambiarFiltro(1)),
                        const SizedBox(width: 8),
                        FiltroChip(label: "Por Visitar", icon: Icons.bookmark_outline, isSelected: mapaVM.filtroActual == 2, onTap: () => _intentarCambiarFiltro(2)),
                        const SizedBox(width: 8),
                        FiltroChip(label: "Mis Rutas", icon: Icons.alt_route_outlined, isSelected: mapaVM.filtroActual == 3, onTap: () => _intentarCambiarFiltro(3)),
                      ],
                    ),
                  ),
                ),
              ),

// --- Z. ALERTA HAKUPARADA (RADAR) ---
              // La ponemos antes de los botones para que no se superpongan feo
              if (mapaVM.mostrarAlertaHakuparada && mapaVM.hakuparadaCercana != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 70, // Debajo de los filtros
                  left: 20,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                        ],
                        border: Border.all(color: const Color(0xFF00BCD4), width: 2), // Borde Cyan
                      ),
                      child: Row(
                        children: [
                          // 1. Icono Vibrante (Radar)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.radar, color: Color(0xFF00BCD4)),
                          ),
                          const SizedBox(width: 12),

                          // 2. Textos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    "¡Estás cerca!",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600]
                                    )
                                ),
                                Text(
                                  mapaVM.hakuparadaCercana!.nombre,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  mapaVM.hakuparadaCercana!.categoria,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF00BCD4)
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Botón Cerrar (X)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => mapaVM.cerrarAlertaHakuparada(),
                            tooltip: "Cerrar aviso",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. BOTONES FLOTANTES
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                right: rightButtons,
                bottom: bottomButtons,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TOGGLE HAKUPARADAS (Ahora como botón flotante mini)
                    if (mapaVM.filtroActual == 0) ...[
                      FloatingActionButton.small(
                        heroTag: "btn_toggle_hakuparadas",
                        onPressed: () => mapaVM.toggleHakuparadas(),
                        backgroundColor: mapaVM.mostrarHakuparadasEnMapa ? const Color(0xFF00BCD4) : Colors.white,
                        foregroundColor: mapaVM.mostrarHakuparadasEnMapa ? Colors.white : Colors.grey[700],
                        tooltip: mapaVM.mostrarHakuparadasEnMapa ? "Modo: Siempre Visible" : "Modo: Inteligente (Zoom)",
                        child: Icon(mapaVM.mostrarHakuparadasEnMapa ? Icons.visibility : Icons.visibility_off),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildFloatingBtn("btn_layers", _verRelieve ? Icons.landscape_rounded : Icons.layers_rounded, _alternarTipoMapa, false),
                    const SizedBox(height: 12),
                    
                    // BOTÓN DE ZOOM IN
                    // BOTÓN GPS
                    FloatingActionButton.small(
                      heroTag: "btn_gps",
                      onPressed: () async {
                        final error = await mapaVM.enfocarMiUbicacion();
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      backgroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Más redondeado
                      child: Icon(Icons.my_location_rounded, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 12),

                    _buildFloatingBtn("btn_zoom_in", Icons.add_rounded, () => mapaVM.zoomIn(), false),
                    const SizedBox(height: 8),
                    _buildFloatingBtn("btn_zoom_out", Icons.remove_rounded, () => mapaVM.zoomOut(), false),
                  ],
                ),
              ),

              // 4. ELEMENTOS INFERIORES / LATERALES (Responsivo)
              
              // --- A. TARJETA POLAROID (DETALLE LUGAR) ---
              if (mapaVM.lugarSeleccionado != null)
                Positioned(
                  // En landscape: Izquierda | En portrait: Abajo
                  bottom: isLandscape ? 20 : 40,
                  left: isLandscape ? 20 : 20,
                  right: isLandscape ? null : 20, // En landscape tiene ancho fijo implicito por el widget
                  top: isLandscape ? 80 : null, // En landscape centrado verticalmente aprox
                  child: Align( // Align necesario para landscape
                    alignment: isLandscape ? Alignment.centerLeft : Alignment.bottomCenter,
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
                )
                
                // --- B. CARRUSEL DE RUTAS ("MIS RUTAS") OPTIMIZADO ---
                // Ahora encapsulado en un widget limpio e independiente
                else if (mapaVM.filtroActual == 3) // Sin '...' ni [] extra, directo al widget
                   PanelRutas(
                     viewportFraction: carruselViewportFraction, // Control preciso del tamaño de tarjetas
                     rutas: rutasAMostrar,
                     isExpanded: _isRutasExpanded,
                     onExpandChanged: (val) => setState(() => _isRutasExpanded = val),
                     subFiltro: _subFiltroRuta,
                     onSubFiltroChanged: (val) {
                       setState(() => _subFiltroRuta = val);
                       mapaVM.limpiarRutaPintada();
                     },
                     onLimpiarRuta: () => mapaVM.limpiarRutaPintada(),
                     isLimpiarVisible: mapaVM.polylines.isNotEmpty,
                     onRutaSelected: (ruta) {
                        final lugaresVM = context.read<LugaresVM>();
                        mapaVM.enfocarRutaEnMapa(ruta, lugaresVM.lugaresTotales);
                        // Opcional: Colapsar al seleccionar si estamos en modo lista
                        if (_isRutasExpanded) setState(() => _isRutasExpanded = false);
                     },
                   ),
            ],
          ),
        );
      }
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFloatingBtn(String tag, IconData icon, VoidCallback onTap, bool isPrimary) {
    return FloatingActionButton.small(
      heroTag: tag,
      onPressed: onTap,
      backgroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: isPrimary ? Theme.of(context).colorScheme.primary : Colors.black87),
    );
  }
}

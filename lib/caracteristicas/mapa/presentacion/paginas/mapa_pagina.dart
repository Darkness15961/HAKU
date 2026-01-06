import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

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

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _cardScaleAnimation = CurvedAnimation(parent: _cardAnimController, curve: Curves.easeOutBack);

    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page ?? 0;
      });
    });

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
    _pageController.dispose();
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
      mapaVM.cambiarFiltro(0);
    } else {
      if (authVM.usuarioActual != null) {
        mapaVM.cambiarFiltro(indice);
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
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final size = MediaQuery.of(context).size;

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

        // --- POSICIONAMIENTO DINÁMICO ---
        double bottomButtons = isLandscape ? 20 : 120; // Más abajo en landscape
        double rightButtons = 16;
        
        // Ajustamos si hay elementos superpuestos
        if (mapaVM.lugarSeleccionado != null) {
          bottomButtons = isLandscape ? 20 : 350; // En landscape, los botones se quedan abajo derecha
          // En landscape la tarjeta polaroid va a la izquierda
        } else if (mapaVM.filtroActual == 3) {
          bottomButtons = isLandscape ? size.height * 0.4 : 220;
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
                  if (mapaVM.polylines.isNotEmpty)
                    PolylineLayer(polylines: mapaVM.polylines),
                    
                  // CAPA DE MARCADORES
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
                right: isLandscape ? 80 : 0, // Dejar espacio a botones si están arriba en landscape (opcional)
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      FiltroChip(label: "Explorar", icon: Icons.map_outlined, isSelected: mapaVM.filtroActual == 0, onTap: () => _intentarCambiarFiltro(0)),
                      const SizedBox(width: 8),
                      FiltroChip(label: "Recuerdos", icon: Icons.camera_alt_outlined, isSelected: mapaVM.filtroActual == 1, onTap: () => _intentarCambiarFiltro(1)),
                      const SizedBox(width: 8),
                      FiltroChip(label: "Por Visitar", icon: Icons.bookmark_outline, isSelected: mapaVM.filtroActual == 2, onTap: () => _intentarCambiarFiltro(2)),
                      const SizedBox(width: 8),
                      FiltroChip(label: "Mis Rutas", icon: Icons.alt_route_outlined, isSelected: mapaVM.filtroActual == 3, onTap: () => _intentarCambiarFiltro(3)),
                    ],
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
                    _buildFloatingBtn("btn_layers", _verRelieve ? Icons.landscape_rounded : Icons.layers_rounded, _alternarTipoMapa, false),
                    const SizedBox(height: 12),
                    
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
                
              // --- B. CARRUSEL DE RUTAS ("MIS RUTAS") ---
              else if (mapaVM.filtroActual == 3) ...[
                // Switch (Inscritas/Creadas)
                 Positioned(
                  bottom: isLandscape ? 20 : 210, // En landscape lo ponemos abajo izquierda alineado con carrusel si queremos, o arriba
                  left: 0, 
                  right: isLandscape ? null : 0,
                  top: isLandscape ? 80 : null, // Landscape: Arriba a la izquierda
                  child: Container(
                    padding: isLandscape ? const EdgeInsets.only(left: 20) : EdgeInsets.zero,
                    alignment: isLandscape ? Alignment.topLeft : Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSwitchModerno(),
                        if (mapaVM.polylines.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => mapaVM.limpiarRutaPintada(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),

                // Carrusel
                Positioned(
                  bottom: 30, // Margen inferior
                  left: 0, 
                  right: isLandscape ? 60 : 0, // En landscape dejamos espacio a la derecha par botones
                  child: _buildCarruselRutasAnimado(context, mapaVM, rutasAMostrar, isLandscape),
                ),
              ],
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

  Widget _buildSwitchModerno() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSwitchOption("Inscritas", 0),
              const SizedBox(width: 4),
              _buildSwitchOption("Creadas", 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(String label, int index) {
    final isSelected = _subFiltroRuta == index;
    return GestureDetector(
      onTap: () async {
        setState(() => _subFiltroRuta = index);
        context.read<MapaVM>().limpiarRutaPintada();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- CARRUSEL MEJORADO (OSRM + UI PRO) ---
  Widget _buildCarruselRutasAnimado(BuildContext context, MapaVM mapaVM, List<Ruta> rutas, bool isLandscape) {
    // Altura ajustada: más bajita en landscape si es necesario
    final double carruselHeight = isLandscape ? 130 : 160; 


    if (rutas.isEmpty) {
      return Container(
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(30), 
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                _subFiltroRuta == 0 ? "No tienes rutas inscritas" : "No has creado rutas",
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: carruselHeight,
      child: PageView.builder(
        controller: _pageController, // Nota: si cambias viewportFraction dinámicamente, recrea el controller en build o usa key
        // Para simplificar, asumiremos viewport fijo o reusamos el controller con cuidado. 
        // Mejor práctica: Usar un controller nuevo si cambia la orientación, pero por ahora mantenemos el existente 0.85
        // y ajustamos padding en la card.
        itemCount: rutas.length,
        itemBuilder: (context, index) {
          final ruta = rutas[index];

          // Efecto de escala
          double scale = 1.0;
          if (_pageController.hasClients && _pageController.position.haveDimensions) {
            double page = _pageController.page ?? 0;
            double diff = (page - index).abs();
            scale = (1 - (diff * 0.15)).clamp(0.85, 1.0);
          } else {
             scale = (index == _currentPageValue.round()) ? 1.0 : 0.85;
          }

          return Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                final lugaresVM = context.read<LugaresVM>();
                mapaVM.enfocarRutaEnMapa(ruta, lugaresVM.lugaresTotales);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5), // Espacio entre cards
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15), 
                      blurRadius: 12, 
                      offset: const Offset(0, 6)
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // 1. Imagen de Fondo
                      Positioned.fill(
                        child: Image.network(
                          ruta.urlImagenPrincipal,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(color: Colors.grey.shade200),
                        ),
                      ),
                      
                      // 2. Gradiente Profesional
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.9),
                              ],
                              stops: const [0.4, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // 3. Contenido Informativo (OSRM)
                      Positioned(
                        bottom: 16, left: 16, right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Título
                            Text(
                              ruta.nombre,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                            const SizedBox(height: 8),
                            
                            // Badges de Información (Distancia / Tiempo)
                            Row(
                              children: [
                                _InfoBadge(
                                  icon: Icons.directions_walk_rounded,
                                  text: "${(ruta.distanciaMetros / 1000).toStringAsFixed(1)} km",
                                  color: Colors.cyanAccent,
                                ),
                                const SizedBox(width: 12),
                                _InfoBadge(
                                  icon: Icons.timer_rounded,
                                  // Conversión simple de segundos a texto (Ej: 3600 -> 1h)
                                  text: _formatearDuracion(ruta.duracionSegundos),
                                  color: Colors.orangeAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // 4. Indicador "Ver Ruta"

                      Positioned(
                        top: 12, right: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Ver Mapa", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 4),
                                  Icon(Icons.visibility_outlined, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  String _formatearDuracion(double segundos) {
    if (segundos <= 0) return "-- min";
    final int minutes = (segundos / 60).round();
    if (minutes < 60) {
      return "$minutes min";
    } else {
      final int hours = (minutes / 60).floor();
      final int mins = minutes % 60;
      return "${hours}h ${mins}m";
    }
  }
}

// Widget auxiliar privado
class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBadge({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
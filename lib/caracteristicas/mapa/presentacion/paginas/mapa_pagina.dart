import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para ImageFilter
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
import '../widgets/indicador_scroll.dart';

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
                // 1. Panel Expandible (Fondo)
                // Lo ponemos PRIMERO para que quede DETRÁS del switch flotante
                _buildPanelRutas(context, mapaVM, rutasAMostrar, isLandscape, size),

                // 2. Switch (Inscritas/Creadas) (Frente)
                 AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  bottom: _isRutasExpanded 
                      ? (size.height * 0.7) - 50 
                      : (isLandscape ? 110 : 130), // Exactamente encima de 100/120 panel height
                  left: isLandscape ? 20 : 0, // Landscape: Pegado a la izquierda pero con margen
                  right: isLandscape ? null : 0,
                  top: null, // Quitamos top en landscape para manejarlo por bottom que es más seguro para carruseles
                  child: Container(
                    padding: isLandscape ? EdgeInsets.zero : EdgeInsets.zero, // Padding ya manejado por posición
                    alignment: isLandscape ? Alignment.bottomLeft : Alignment.center,
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
    // DISEÑO SENIOR: Blanco Sólido + Sombra suave. Fuera "niebla".
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, // Blanco sólido "Clean"
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200), // Borde fino
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flecha de Expansión (Clean, sin fondo extra, el padre ya es blanco)
          GestureDetector(
            onTap: () => setState(() => _isRutasExpanded = !_isRutasExpanded),
            child: Container(
              color: Colors.transparent, 
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Icon(
                _isRutasExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                color: Colors.black87, // Icono negro/gris fuerte
                size: 22,
              ),
            ),
          ),
          _buildSwitchOption("Inscritas", 0),
          const SizedBox(width: 2), // Menos espacio, más compacto
          _buildSwitchOption("Creadas", 1),
        ],
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
          // Invertido: Fondo oscuro al seleccionar para estilo "Pill"
          color: isSelected ? Colors.black87 : Colors.transparent, 
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            // Texto blanco si seleccionado, gris oscuro si no
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- CARRUSEL MEJORADO (OSRM + UI PRO) ---
  Widget _buildCarruselRutasAnimado(BuildContext context, MapaVM mapaVM, List<Ruta> rutas, bool isLandscape) {
    // Altura ajustada: más bajita en landscape si es necesario
    // Altura ajustada: Modo Compacto "Pro" para no obstruir el mapa
    final double carruselHeight = isLandscape ? 90 : 110; 

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
                margin: const EdgeInsets.only(bottom: 15, left: 5, right: 5), // Un poco más de margen bottom para la sombra
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white, // Fondo blanco limpio
                  boxShadow: [
                    // Sombra premium suave
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08), 
                      blurRadius: 15, 
                      offset: const Offset(0, 8)
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      // 1. Imagen - 40% del ancho (Solicitado por Diseño)
                      Expanded(
                        flex: 4, 
                        child: Image.network(
                          ruta.urlImagenPrincipal,
                          fit: BoxFit.cover,
                          height: double.infinity, // Cubrir toda la altura
                          errorBuilder: (_,__,___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                      
                      // 2. Información "Rich Content" - 60% restante
                      Expanded(
                        flex: 6,
                        child: Row(
                          children: [
                            // Columna de Info (Toma el espacio disponible del 60%)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Padding ajustado
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center, // Centrado verticalmente
                                  children: [
                                    // A. Título y Rating
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ruta.nombre,
                                            style: const TextStyle(
                                              color: Colors.black87, 
                                              fontSize: 13, // Un pelín más pequeño para asegurar fit
                                              fontWeight: FontWeight.w800,
                                              height: 1.1,
                                            ),
                                            maxLines: 2, 
                                            overflow: TextOverflow.ellipsis
                                          ),
                                        ),
                                        if (ruta.rating > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4.0),
                                            child: Text("★${ruta.rating}", style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // B. Categoría (Compact Tag)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        ruta.categoria.toUpperCase(),
                                        style: TextStyle(fontSize: 8, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // C. Métricas (Fila única compacta)
                                    Row(
                                      children: [
                                        Icon(Icons.directions_walk, size: 10, color: Colors.blueGrey.shade400),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${(ruta.distanciaMetros / 1000).toStringAsFixed(1)}km",
                                          style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.schedule, size: 10, color: Colors.blueGrey.shade400),
                                        const SizedBox(width: 2),
                                        Text(
                                          _formatearDuracion(ruta.duracionSegundos),
                                          style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // 3. Chevron (Parte derecha del bloque 60%)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
                            ),
                          ],
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

  // --- PANEL RUTAS EXPANDIBLE ---
  Widget _buildPanelRutas(BuildContext context, MapaVM mapaVM, List<Ruta> rutas, bool isLandscape, Size screenSize) {
    // Alturas
    // Alturas
    // Ajustado para coincidir con el carrusel compacto (110 + 10 padding = 120 aprox)
    final double collapsedHeight = isLandscape ? 100 : 120;
    final double expandedHeight = screenSize.height * 0.7; // 70% de la pantalla
    
    // Si está expandido ocupamos una posición fija desde abajo, si no, es solo el carrusel
    // Usamos AnimatedPositioned para que se deslice suave
    
    final double bottomPos = 0; // Siempre anclado abajo
    final double height = _isRutasExpanded ? expandedHeight : collapsedHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: bottomPos,
      left: 0,
      right: isLandscape ? 60 : 0, // Respetar botones laterales en landscape
      height: height,
      child: Stack(
        children: [
          // Fondo del Panel (Solo visible al expandir para dar contraste)
          if (_isRutasExpanded)
            GestureDetector(
              onTap: () => setState(() => _isRutasExpanded = false), // Cerrar al tocar fuera (técnicamente el fondo)
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)]
                ),
              ),
            ),

          // Contenido
          Column(
            children: [
              // Eliminamos el botón Handle superior ya que ahora está en el switch
              const SizedBox(height: 10), // Un pequeño padding superior

              // Lista o Carrusel
              Expanded(
                child: _isRutasExpanded
                    ? _buildListaExpandida(rutas, mapaVM)
                    : IndicadorScroll( // Agregamos indicadores al carrusel
                        scrollController: _pageController,
                        showArrows: true,
                        child: _buildCarruselRutasAnimado(context, mapaVM, rutas, isLandscape),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaExpandida(List<Ruta> rutas, MapaVM mapaVM) {
    if (rutas.isEmpty) return const SizedBox();
    
    return ListView.builder(
      // Padding superior para que el Switch flotante no tape el primer elemento
      // Padding inferior para el Safe Area
      padding: EdgeInsets.fromLTRB(16, 60, 16, MediaQuery.of(context).padding.bottom + 20),
      physics: const BouncingScrollPhysics(),
      itemCount: rutas.length,
      itemBuilder: (context, index) {
        final ruta = rutas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ruta.urlImagenPrincipal,
                width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: Colors.grey.shade200, width: 60, height: 60),
              ),
            ),
            title: Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
               children: [
                 Icon(Icons.directions_walk, size: 14, color: Colors.grey),
                 Text(" ${(ruta.distanciaMetros/1000).toStringAsFixed(1)}km ", style: const TextStyle(fontSize: 12)),
                 const SizedBox(width: 8),
                 Icon(Icons.timer, size: 14, color: Colors.grey),
                 Text(" ${_formatearDuracion(ruta.duracionSegundos)}", style: const TextStyle(fontSize: 12)),
               ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.map, color: Colors.blueAccent),
              onPressed: () {
                 final lugaresVM = context.read<LugaresVM>();
                 mapaVM.enfocarRutaEnMapa(ruta, lugaresVM.lugaresTotales);
                 setState(() => _isRutasExpanded = false); // Colapsar al elegir
              },
            ),
          ),
        );
      },
    );
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
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

    if (mapaVM.lugarSeleccionado != null && !_cardAnimController.isCompleted) {
      _cardAnimController.forward();
    } else if (mapaVM.lugarSeleccionado == null && _cardAnimController.isCompleted) {
      _cardAnimController.reverse();
    }

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

    double bottomPositionButtons = 120;
    if (mapaVM.lugarSeleccionado != null) bottomPositionButtons = 350;
    else if (mapaVM.filtroActual == 3) bottomPositionButtons = 220;

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
                } else {
                  // mapaVM.limpiarRutaPintada(); // Opcional
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

              // CAPA DE MARCADORES (Con tu ubicación añadida)
              MarkerLayer(
                markers: [
                  // 1. Marcador de "YO" (Puntito Azul)
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
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                        ),
                      ),
                    ),

                  // 2. Los marcadores normales (Lugares)
                  ...mapaVM.markers,
                ],
              ),
            ],
          ),

          if (mapaVM.estaCargando) const Center(child: CircularProgressIndicator()),

          // 2. FILTROS SUPERIORES
          Positioned(
            top: 60, left: 0, right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FiltroChip(label: "Explorar", icon: Icons.map, isSelected: mapaVM.filtroActual == 0, onTap: () => _intentarCambiarFiltro(0)),
                  const SizedBox(width: 8),
                  FiltroChip(label: "Recuerdos", icon: Icons.photo_camera, isSelected: mapaVM.filtroActual == 1, onTap: () => _intentarCambiarFiltro(1)),
                  const SizedBox(width: 8),
                  FiltroChip(label: "Por Visitar", icon: Icons.favorite, isSelected: mapaVM.filtroActual == 2, onTap: () => _intentarCambiarFiltro(2)),
                  const SizedBox(width: 8),
                  FiltroChip(label: "Mis Rutas", icon: Icons.alt_route, isSelected: mapaVM.filtroActual == 3, onTap: () => _intentarCambiarFiltro(3)),
                ],
              ),
            ),
          ),

          // 3. BOTONES FLOTANTES (Con alerta GPS)
          Positioned(
            right: 16, bottom: bottomPositionButtons,
            child: Column(
              children: [
                _buildFloatingBtn("btn_layers", _verRelieve ? Icons.landscape : Icons.layers, _alternarTipoMapa, false),
                const SizedBox(height: 8),

                // BOTÓN GPS MEJORADO
                FloatingActionButton.small(
                  heroTag: "btn_gps",
                  onPressed: () async {
                    // Llamamos a la función que devuelve el error
                    final error = await mapaVM.enfocarMiUbicacion();
                    if (error != null && context.mounted) {
                      // Si hubo error (GPS apagado, etc), mostramos mensaje
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                ),

                const SizedBox(height: 8),
                _buildFloatingBtn("btn_zoom_in", Icons.add, () => mapaVM.zoomIn(), false),
                const SizedBox(height: 8),
                _buildFloatingBtn("btn_zoom_out", Icons.remove, () => mapaVM.zoomOut(), false),
              ],
            ),
          ),

          // 4. PANELES INFERIORES
          if (mapaVM.lugarSeleccionado != null)
            Positioned(
              bottom: 40, left: 20, right: 20,
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
          else if (mapaVM.filtroActual == 3) ...[
            // Switch Moderno + Botón Cerrar (CORREGIDO)
            Positioned(
              bottom: 180,
              left: 0, right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSwitchModerno(),
                    // Si hay una ruta pintada (línea azul), mostramos la X para borrarla
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
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),

            // Carrusel (MÁS PEQUEÑO)
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: _buildCarruselRutasAnimado(context, mapaVM, rutasAMostrar),
            ),
          ],
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildFloatingBtn(String tag, IconData icon, VoidCallback onTap, bool isPrimary) {
    return FloatingActionButton.small(
      heroTag: tag,
      onPressed: onTap,
      backgroundColor: Colors.white,
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
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
      onTap: () {
        setState(() => _subFiltroRuta = index);
        // Al cambiar de pestaña, limpiamos la ruta anterior como pediste
        context.read<MapaVM>().limpiarRutaPintada();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCarruselRutasAnimado(BuildContext context, MapaVM mapaVM, List<Ruta> rutas) {
    if (rutas.isEmpty) {
      return Container(
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Text(
            _subFiltroRuta == 0 ? "No tienes rutas inscritas" : "No has creado rutas",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        itemCount: rutas.length,
        itemBuilder: (context, index) {
          final ruta = rutas[index];

          double scale = 1.0;
          if (_pageController.hasClients && _pageController.position.haveDimensions) {
            double diff = (_currentPageValue - index);
            scale = (1 - (diff.abs() * 0.15)).clamp(0.85, 1.0);
          } else {
            scale = (index == 0) ? 1.0 : 0.85;
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
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  image: DecorationImage(image: NetworkImage(ruta.urlImagenPrincipal), fit: BoxFit.cover),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.5, 1.0]),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white30)),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 14),
                      ),
                    ),
                    Positioned(
                      bottom: 12, left: 12, right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ruta.nombre, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          // Simplificamos la info para el tamaño reducido
                          Row(
                            children: [
                              Icon(Icons.timeline, color: Colors.cyanAccent, size: 12),
                              const SizedBox(width: 4),
                              Text("${(ruta.distanciaMetros / 1000).toStringAsFixed(1)} km", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
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
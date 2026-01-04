import 'package:flutter/material.dart';
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

class MapaPagina extends StatefulWidget {
  const MapaPagina({super.key});

  @override
  State<MapaPagina> createState() => _MapaPaginaState();
}

class _MapaPaginaState extends State<MapaPagina> with TickerProviderStateMixin {
  late AnimationController _cardAnimController;
  late Animation<double> _cardScaleAnimation;
  bool _verRelieve = false;

  // 0: Inscritas (Turista), 1: Creadas (Guía)
  int _subFiltroRuta = 0;

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

    // Carga inicial de dependencias
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
  }

  String _obtenerUrlMapa() {
    return _verRelieve
        ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  // Lógica para cambiar filtro principal
  void _intentarCambiarFiltro(int indice) {
    final mapaVM = context.read<MapaVM>();
    final authVM = context.read<AutenticacionVM>();

    if (indice == 0) {
      mapaVM.cambiarFiltro(0);
    } else {
      if (authVM.usuarioActual != null) {
        mapaVM.cambiarFiltro(indice);
        // Si entramos a 'Mis Rutas', reseteamos a 'Inscritas' por defecto
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
    final theme = Theme.of(context);

    // Animación de tarjeta Polaroid
    if (mapaVM.lugarSeleccionado != null && !_cardAnimController.isCompleted) {
      _cardAnimController.forward();
    } else if (mapaVM.lugarSeleccionado == null && _cardAnimController.isCompleted) {
      _cardAnimController.reverse();
    }

    // PREPARAR LAS LISTAS DE RUTAS
    List<Ruta> rutasAMostrar = [];
    if (mapaVM.filtroActual == 3) {
      if (_subFiltroRuta == 0) {
        // Inscritas
        rutasAMostrar = rutasVM.misRutasInscritas;
      } else {
        // Creadas (filtramos localmente)
        final uid = authVM.usuarioActual?.id;
        if (uid != null) {
          // CAMBIO AQUÍ: De 'rutasTotales' a 'rutas'
          // Intenta con este nombre:
          rutasAMostrar = rutasVM.rutasFiltradas.where((r) => r.guiaId == uid).toList();
        }
      }
    }

    // Altura dinámica de los botones flotantes
    double bottomPositionButtons = 120;
    if (mapaVM.lugarSeleccionado != null) bottomPositionButtons = 350;
    else if (mapaVM.filtroActual == 3) bottomPositionButtons = 260;

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
                // Si tocamos el mapa vacío, limpiamos todo
                if (mapaVM.lugarSeleccionado != null) {
                  _cardAnimController.reverse().then((_) => mapaVM.cerrarDetalle());
                } else {
                  mapaVM.limpiarRutaPintada(); // <--- ESTO NECESITA ESTAR EN EL VM
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _obtenerUrlMapa(),
                userAgentPackageName: 'com.xplorecusco.app',
                tileProvider: CachedTileProvider(),
              ),
              // Línea OSRM (Ruta Azul)
              if (mapaVM.polylines.isNotEmpty)
                PolylineLayer(polylines: mapaVM.polylines),

              MarkerLayer(markers: mapaVM.markers),
            ],
          ),

          if (mapaVM.estaCargando)
            const Center(child: CircularProgressIndicator()),

          // 2. FILTROS SUPERIORES
          Positioned(
            top: 50, left: 0, right: 0,
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

          // 3. BOTONES FLOTANTES
          Positioned(
            right: 16, bottom: bottomPositionButtons,
            child: Column(
              children: [
                FloatingActionButton.small(heroTag: "btn_layers", onPressed: _alternarTipoMapa, backgroundColor: Colors.white, child: Icon(_verRelieve ? Icons.landscape : Icons.layers, color: Colors.black87)),
                const SizedBox(height: 8),
                FloatingActionButton.small(heroTag: "btn_gps", onPressed: () => mapaVM.enfocarMiUbicacion(), backgroundColor: Colors.white, child: Icon(Icons.my_location, color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                FloatingActionButton.small(heroTag: "btn_zoom_in", onPressed: () => mapaVM.zoomIn(), backgroundColor: Colors.white, child: const Icon(Icons.add, color: Colors.black87)),
                const SizedBox(height: 8),
                FloatingActionButton.small(heroTag: "btn_zoom_out", onPressed: () => mapaVM.zoomOut(), backgroundColor: Colors.white, child: const Icon(Icons.remove, color: Colors.black87)),
              ],
            ),
          ),

          // 4. PANELES INFERIORES
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
            )
          else if (mapaVM.filtroActual == 3) ...[
            // Switch Inscritas/Creadas
            Positioned(
              bottom: 180, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSubFiltroItem("Inscritas", 0, theme),
                      const SizedBox(width: 4),
                      _buildSubFiltroItem("Creadas", 1, theme),
                    ],
                  ),
                ),
              ),
            ),
            // Carrusel de Nubes (Rutas)
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: _buildCarruselRutas(context, mapaVM, rutasAMostrar),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubFiltroItem(String label, int index, ThemeData theme) {
    final isSelected = _subFiltroRuta == index;
    return GestureDetector(
      onTap: () {
        setState(() => _subFiltroRuta = index);
        context.read<MapaVM>().limpiarRutaPintada(); // Limpia al cambiar tab
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildCarruselRutas(BuildContext context, MapaVM mapaVM, List<Ruta> rutas) {
    if (rutas.isEmpty) {
      return Container(
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Text(_subFiltroRuta == 0 ? "No tienes rutas inscritas" : "No has creado rutas", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: rutas.length,
        itemBuilder: (context, index) {
          final ruta = rutas[index];
          return GestureDetector(
            onTap: () {
              // AQUÍ LLAMAMOS A LA FUNCIÓN QUE PINTA
              final lugaresVM = context.read<LugaresVM>();
              mapaVM.enfocarRutaEnMapa(ruta, lugaresVM.lugaresTotales);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                image: DecorationImage(image: NetworkImage(ruta.urlImagenPrincipal), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ruta.nombre, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text("${(ruta.distanciaMetros / 1000).toStringAsFixed(1)} km", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
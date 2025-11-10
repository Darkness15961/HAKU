// --- PIEDRA 7 (MAPA): EL "MENÚ" DE MAPA (VERSIÓN FINAL CON TIPO DE MAPA) ---
//
// 1. (BUG TIPO DE MAPA CORREGIDO): El widget 'GoogleMap' AHORA SÍ
//    lee el estado 'vmMapa.currentMapType' para cambiar el relieve.
// 2. (UX FINAL): Todos los botones están ordenados y funcionales.

import 'dart:async';
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
import '../../../rutas/dominio/entidades/ruta.dart';

class MapaPagina extends StatefulWidget {
  const MapaPagina({super.key});

  @override
  State<MapaPagina> createState() => _MapaPaginaState();
}

class _MapaPaginaState extends State<MapaPagina> {
  final CameraPosition _posicionInicial = const CameraPosition(
    target: LatLng(-13.52264, -71.96734),
    zoom: 12,
  );

  // --- Controladores (se mantienen) ---
  late PageController _lugaresPageController;
  late PageController _rutasPageController;
  Timer? _lugaresTimer;
  Timer? _rutasTimer;
  int _lugaresCount = 0;
  int _rutasCount = 0;

  @override
  void initState() {
    super.initState();
    _lugaresPageController = PageController(viewportFraction: 0.85);
    _rutasPageController = PageController(viewportFraction: 0.85);

    // Llama a actualizarDependencias
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
  void dispose() {
    _lugaresPageController.dispose();
    _rutasPageController.dispose();
    _lugaresTimer?.cancel();
    _rutasTimer?.cancel();
    super.dispose();
  }

  // --- Lógica de Timers (se mantiene) ---
  void _startLugaresTimer(int count) {
    if (count <= 1) return;
    _lugaresCount = count;
    _lugaresTimer?.cancel();
    _lugaresTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_lugaresPageController.hasClients || !mounted) return;
      int nextPage = _lugaresPageController.page!.round() + 1;
      if (nextPage >= _lugaresCount) nextPage = 0;
      _lugaresPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }
  void _stopLugaresTimer() { _lugaresTimer?.cancel(); }
  void _startRutasTimer(int count) {
    if (count <= 1) return;
    _rutasCount = count;
    _rutasTimer?.cancel();
    _rutasTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_rutasPageController.hasClients || !mounted) return;
      int nextPage = _rutasPageController.page!.round() + 1;
      if (nextPage >= _rutasCount) nextPage = 0;
      _rutasPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }
  void _stopRutasTimer() { _rutasTimer?.cancel(); }


  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final vmMapa = context.watch<MapaVM>();
    final vmAuth = context.watch<AutenticacionVM>();
    final vmLugares = context.read<LugaresVM>();

    // Lógica de Marcador de Ubicación Actual
    final Set<Marker> allMarkers = {
      ...vmMapa.markers,
      if (vmMapa.currentLocation != null)
        Marker(
          markerId: const MarkerId("user_position"),
          position: vmMapa.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "Mi Ubicación"),
        ),
    };

    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // El Mapa
          GoogleMap(
            initialCameraPosition: _posicionInicial,

            // --- ¡ACOMPLADO! ---
            markers: allMarkers,
            polylines: vmMapa.polylines,
            mapType: vmMapa.currentMapType, // <-- ¡AQUÍ ESTÁ LA CORRECCIÓN!
            // --- FIN ---

            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,

            onMapCreated: (GoogleMapController controller) {
              if (mounted) {
                vmMapa.setNewMapController(controller);
              }
            },
          ),

          // Spinner de Carga
          if (vmMapa.estaCargando)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // --- 1. BOTONES DE FILTRO (Posición Corregida) ---
          Positioned(
            top: topPadding + 10,
            left: 10,
            right: 10,
            child: _buildBotonesFiltro(context, vmMapa, vmAuth),
          ),

          // --- 2. BOTÓN LIMPIAR (Fila 2: Izquierda) ---
          if (vmMapa.markers.isNotEmpty || vmMapa.polylines.isNotEmpty)
            Positioned(
              top: topPadding + 70,
              left: 10,
              child: FloatingActionButton.small(
                onPressed: () {
                  context.read<MapaVM>().limpiarMarcadores();
                },
                backgroundColor: Colors.white,
                heroTag: 'clean_btn',
                child: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
              ),
            ),

          // --- 3. BOTÓN CENTRAR UBICACIÓN (Fila 2: Derecha) ---
          Positioned(
            top: topPadding + 70,
            right: 10,
            child: FloatingActionButton.small(
              onPressed: () async {
                try {
                  await context.read<MapaVM>().enfocarMiUbicacion();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
                    );
                  }
                }
              },
              backgroundColor: Colors.white,
              heroTag: 'center_btn',
              child: Icon(Icons.near_me, color: Theme.of(context).colorScheme.primary),
            ),
          ),

          // --- 4. BOTONES DE ZOOM PERSONALIZADOS (Fila 3: Derecha) ---
          Positioned(
            top: topPadding + 130,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn_btn',
                  onPressed: () {
                    context.read<MapaVM>().zoomIn();
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut_btn',
                  onPressed: () {
                    context.read<MapaVM>().zoomOut();
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.remove, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),

          // --- 5. ¡NUEVO! BOTÓN TIPO DE MAPA (Fila 3: Izquierda) ---
          Positioned(
            top: topPadding + 130, // Fila 3: Izquierda (espejo de Zoom)
            left: 10,
            child: FloatingActionButton.small(
              heroTag: 'mapType_btn',
              onPressed: () {
                context.read<MapaVM>().toggleMapType(); // Llama al VM
              },
              backgroundColor: Colors.white,
              child: Icon(
                // Cambia el ícono según el tipo de mapa
                  vmMapa.currentMapType == MapType.normal ? Icons.satellite_alt : Icons.map,
                  color: Theme.of(context).colorScheme.primary
              ),
            ),
          ),


          // 6. CARRUSEL CONDICIONAL (Posición Abajo)
          if (vmMapa.carruselActual != TipoCarrusel.ninguno)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildCarruselDinamico(context, vmMapa, vmLugares.lugaresTotales),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Sin cambios) ---

  Widget _buildBotonesFiltro(BuildContext context, MapaVM vmMapa, AutenticacionVM vmAuth) {
    final bool mostrandoLugares = vmMapa.carruselActual == TipoCarrusel.lugares;
    final bool mostrandoRutas = vmMapa.carruselActual == TipoCarrusel.rutas;

    void handleTap(Function loggedInAction) {
      if (!mounted) return;
      if (vmAuth.estaLogueado) {
        _stopLugaresTimer();
        _stopRutasTimer();
        loggedInAction();
      } else {
        _showLoginRequiredModal(context, 'ver tus listas personalizadas');
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.favorite, size: 18),
            label: const Text('Favoritos'),
            onPressed: () => handleTap(() {
              if (mostrandoLugares) {
                vmMapa.mostrarTodosLosLugares();
              } else {
                vmMapa.mostrarCarruselLugares();
              }
            }),
            style: FilledButton.styleFrom(
              backgroundColor: mostrandoLugares ? Theme.of(context).colorScheme.primary : Colors.white,
              foregroundColor: mostrandoLugares ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Mis Rutas'),
            onPressed: () => handleTap(() {
              if (mostrandoRutas) {
                vmMapa.mostrarTodosLosLugares();
              } else {
                vmMapa.mostrarCarruselRutas();
              }
            }),
            style: FilledButton.styleFrom(
              backgroundColor: mostrandoRutas ? Theme.of(context).colorScheme.primary : Colors.white,
              foregroundColor: mostrandoRutas ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    if (!mounted) return;
    final colorPrimario = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Acción Requerida 🔒'),
          content: Text('Necesitas iniciar sesión o crear una cuenta para $action.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir Explorando', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimario),
              child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarruselDinamico(BuildContext context, MapaVM vmMapa, List<Lugar> lugaresTotales) {
    if (vmMapa.carruselActual == TipoCarrusel.lugares) {
      _startLugaresTimer(vmMapa.lugaresFiltrados.length);
      return _buildCarruselLugares(vmMapa.lugaresFiltrados);
    } else if (vmMapa.carruselActual == TipoCarrusel.rutas) {
      _startRutasTimer(vmMapa.rutasFiltradas.length);
      return _buildCarruselRutas(vmMapa.rutasFiltradas, lugaresTotales);
    }
    return const SizedBox.shrink();
  }

  Widget _buildCarruselLugares(List<Lugar> lugares) {
    if (lugares.isEmpty) {
      _stopLugaresTimer();
      return _buildEmptyCarouselCard("No tienes lugares favoritos guardados.");
    }
    return Container(
      height: 120,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            _stopLugaresTimer();
          }
          return false;
        },
        child: PageView.builder(
          controller: _lugaresPageController,
          itemCount: lugares.length,
          itemBuilder: (context, index) {
            final lugar = lugares[index];
            return _buildLugarCard(context, lugar);
          },
        ),
      ),
    );
  }

  Widget _buildCarruselRutas(List<Ruta> rutas, List<Lugar> lugaresTotales) {
    if (rutas.isEmpty) {
      _stopRutasTimer();
      return _buildEmptyCarouselCard("No estás inscrito en ninguna ruta.");
    }
    return Container(
      height: 120,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            _stopRutasTimer();
          }
          return false;
        },
        child: PageView.builder(
          controller: _rutasPageController,
          itemCount: rutas.length,
          itemBuilder: (context, index) {
            final ruta = rutas[index];
            return _buildRutaCard(context, ruta, lugaresTotales);
          },
        ),
      ),
    );
  }

  Widget _buildLugarCard(BuildContext context, Lugar lugar) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          GestureDetector(
            onTap: () { if (mounted) context.push('/detalle-lugar', extra: lugar); },
            child: Image.network(
              lugar.urlImagen,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 100, height: 120, color: Colors.grey[200], child: Icon(Icons.place, color: Colors.grey[400])),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () { if (mounted) context.read<MapaVM>().enfocarLugarEnMapa(lugar); },
                    child: Text(
                      lugar.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lugar.categoria,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRutaCard(BuildContext context, Ruta ruta, List<Lugar> lugaresTotales) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          GestureDetector(
            onTap: () { if (mounted) context.push('/detalle-ruta', extra: ruta); },
            child: Image.network(
              ruta.urlImagenPrincipal,
              width: 100,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 100, height: 120, color: Colors.grey[200], child: Icon(Icons.map, color: Colors.grey[400])),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () { if (mounted) context.read<MapaVM>().enfocarRutaEnMapa(ruta, lugaresTotales); },
                    child: Text(
                      ruta.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Por: ${ruta.guiaNombre}",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyCarouselCard(String message) {
    return Center(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
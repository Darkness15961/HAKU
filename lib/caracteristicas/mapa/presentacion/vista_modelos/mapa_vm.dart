// --- CARACTERISTICAS/MAPA/PRESENTACION/VISTA_MODELOS/MAPA_VM.DART ---
// Versión: OpenStreetMap (FlutterMap) Final


import 'dart:ui' as ui;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

// VMs
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';

// Entidades
import '../../../inicio/dominio/entidades/lugar.dart';
import '../../../rutas/dominio/entidades/ruta.dart';

// Key Global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

enum TipoCarrusel { ninguno, lugares, rutas }

class MapaVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  LugaresVM? _lugaresVM;
  AutenticacionVM? _authVM;
  RutasVM? _rutasVM;

  // --- B. ESTADO ---
  bool _estaCargando = false;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  String? _error;
  bool _cargaInicialRealizada = false;

  final MapController mapController = MapController();

  Lugar? _lugarSeleccionado;
  int _filtroActual = 0; // 0: Todos, 1: Recuerdos, 2: Favoritos
  TipoCarrusel _carruselActual = TipoCarrusel.ninguno;
  List<Lugar> _lugaresFiltrados = [];

  // GPS
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentLocation;

  // --- GETTERS ---
  bool get estaCargando => _estaCargando;
  List<Marker> get markers => _markers;
  List<Polyline> get polylines => _polylines;
  String? get error => _error;
  Lugar? get lugarSeleccionado => _lugarSeleccionado;
  int get filtroActual => _filtroActual;
  LatLng? get currentLocation => _currentLocation;
  TipoCarrusel get carruselActual => _carruselActual;

  MapaVM();

  // --- INICIALIZACIÓN ---
  void actualizarDependencias(LugaresVM lugaresVM, AutenticacionVM authVM, RutasVM rutasVM) {
    if (_cargaInicialRealizada) {
      if (_authVM?.usuarioActual != authVM.usuarioActual) {
        _lugaresVM = lugaresVM;
        _authVM = authVM;
        _rutasVM = rutasVM;
        _actualizarListasYMarcadores();
      }
      return;
    }
    _lugaresVM = lugaresVM;
    _authVM = authVM;
    _rutasVM = rutasVM;

    if (lugaresVM.estaCargandoInicio || authVM.estaCargando) {
      _estaCargando = true;
      notifyListeners();
      lugaresVM.addListener(_onDependenciasReady);
      authVM.addListener(_onDependenciasReady);
      return;
    }
    _iniciarCargaLogica();
  }

  void _onDependenciasReady() {
    if (_cargaInicialRealizada) return;
    if (!(_lugaresVM?.estaCargandoInicio ?? true) && !(_authVM?.estaCargando ?? true)) {
      _iniciarCargaLogica();
      _lugaresVM?.removeListener(_onDependenciasReady);
      _authVM?.removeListener(_onDependenciasReady);
    }
  }

  void _iniciarCargaLogica() {
    _cargaInicialRealizada = true;
    _estaCargando = false;
    _lugaresVM?.addListener(_actualizarListasYMarcadores);
    _authVM?.addListener(_actualizarListasYMarcadores);
    _actualizarListasYMarcadores();
    iniciarSeguimientoUbicacion();
  }

  // --- LÓGICA DE MARCADORES ---
  void _actualizarListasYMarcadores() {
    if (!_cargaInicialRealizada || _lugaresVM == null || _authVM == null) return;
    _estaCargando = true;
    notifyListeners();

    try {
      final todosLosLugares = _lugaresVM!.lugaresTotales;
      final idsFavoritos = _authVM!.lugaresFavoritosIds;

      if (_filtroActual == 0) {
        _lugaresFiltrados = todosLosLugares;
      } else if (_filtroActual == 1) {
        final recuerdos = _lugaresVM!.misRecuerdos;
        _lugaresFiltrados = recuerdos.map((r) => Lugar(
          id: 'recuerdo_${r.id}',
          nombre: r.nombreRuta,
          descripcion: r.comentario ?? 'Recuerdo',
          urlImagen: r.fotoUrl,
          latitud: r.latitud,
          longitud: r.longitud,
          rating: 5.0,
          provinciaId: '0',
          usuarioId: '',
          horario: '',
          reviewsCount: 0,
          videoTiktokUrl: '',
        )).toList();
      } else if (_filtroActual == 2) {
        _lugaresFiltrados = todosLosLugares.where((l) => idsFavoritos.contains(l.id)).toList();
      }

      if (_carruselActual != TipoCarrusel.rutas) {
        _markers.clear();
        _polylines.clear();
        for (var lugar in _lugaresFiltrados) {
          if (lugar.latitud != 0 && lugar.longitud != 0) {
            _markers.add(_crearWidgetMarcador(lugar));
          }
        }
      }
      _estaCargando = false;
      notifyListeners();
    } catch (e) {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // --- WIDGETS DE MARCADORES ---
  Marker _crearWidgetMarcador(Lugar lugar) {
    final esRecuerdo = _filtroActual == 1;
    final esFavorito = _filtroActual == 2;

    return Marker(
      point: LatLng(lugar.latitud, lugar.longitud),
      width: esRecuerdo ? 70 : 60,
      height: esRecuerdo ? 70 : 60,

      // CAMBIO CLAVE AQUÍ:
      // Usa 'Alignment.center' para que la foto quede justo encima del lugar.
      // O usa 'Alignment.bottomCenter' si quieres que el "piquito" del pin toque el suelo.
      alignment: Alignment.center,

      child: GestureDetector(
        onTap: () => _manejarTapMarcador(lugar),
        child: esRecuerdo
            ? _buildPolaroidMarker(lugar)
            : _buildPinMarker(lugar, esFavorito),
      ),
    );
  }

  Widget _buildPolaroidMarker(Lugar lugar) {
    return Transform.rotate(
      angle: 0.1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                lugar.urlImagen,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPinMarker(Lugar lugar, bool esFavorito) {
    return Column(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: esFavorito ? Colors.red : const Color(0xFF00BCD4), width: 3),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
            image: DecorationImage(image: NetworkImage(lugar.urlImagen), fit: BoxFit.cover),
          ),
        ),
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(width: 10, height: 8, color: esFavorito ? Colors.red : const Color(0xFF00BCD4)),
        ),
      ],
    );
  }

  void _manejarTapMarcador(Lugar lugar) {
    if (_filtroActual == 0) {
      final context = navigatorKey.currentContext;
      if (context != null) context.push('/inicio/detalle-lugar', extra: lugar);
    } else {
      _lugarSeleccionado = lugar;
      notifyListeners();
    }
  }

  // --- ACCIONES ---
  void cerrarDetalle() {
    _lugarSeleccionado = null;
    notifyListeners();
  }

  void cambiarFiltro(int nuevoFiltro) {
    _filtroActual = nuevoFiltro;
    _carruselActual = TipoCarrusel.ninguno;
    _actualizarListasYMarcadores();
  }

  void enfocarLugarEnMapa(Lugar lugar) {
    mapController.move(LatLng(lugar.latitud, lugar.longitud), 15.0);
    _lugarSeleccionado = lugar;
    notifyListeners();
  }

  void enfocarRutaEnMapa(Ruta ruta, List<Lugar> todosLosLugares) {
    final lugaresRuta = todosLosLugares.where((l) => ruta.lugaresIncluidosIds.contains(l.id)).toList();
    if (lugaresRuta.isEmpty) return;

    _markers.clear();
    _polylines.clear();
    final points = <LatLng>[];

    for (var lugar in lugaresRuta) {
      _markers.add(_crearWidgetMarcador(lugar));
      points.add(LatLng(lugar.latitud, lugar.longitud));
    }

    _polylines.add(Polyline(points: points, strokeWidth: 5.0, color: const Color(0xFF00BCD4)));

    if (points.isNotEmpty) {
      double sumLat = 0, sumLng = 0;
      for (var p in points) { sumLat += p.latitude; sumLng += p.longitude; }
      mapController.move(LatLng(sumLat / points.length, sumLng / points.length), 13.0);
    }
    _carruselActual = TipoCarrusel.rutas;
    notifyListeners();
  }

  Future<void> enfocarMiUbicacion() async {
    if (_currentLocation != null) {
      mapController.move(_currentLocation!, 16.0);
    } else {
      await iniciarSeguimientoUbicacion();
      if (_currentLocation != null) mapController.move(_currentLocation!, 16.0);
    }
  }

  Future<bool> iniciarSeguimientoUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        notifyListeners();
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> zoomIn() async {
    mapController.move(mapController.camera.center, mapController.camera.zoom + 1);
  }

  Future<void> zoomOut() async {
    mapController.move(mapController.camera.center, mapController.camera.zoom - 1);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _lugaresVM?.removeListener(_onDependenciasReady);
    _authVM?.removeListener(_onDependenciasReady);
    _lugaresVM?.removeListener(_actualizarListasYMarcadores);
    _authVM?.removeListener(_actualizarListasYMarcadores);
    super.dispose();
  }
}
// --- CLASE CLIPPER CORREGIDA Y BLINDADA ---
// Usamos 'ui.Path' en TODO para que no quede duda alguna.

class _TriangleClipper extends CustomClipper<ui.Path> { // <--- Agregado ui.
  @override
  ui.Path getClip(Size size) { // <--- Agregado ui.
    final ui.Path path = ui.Path(); // <--- Agregado ui.

    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false; // <--- Agregado ui.
}
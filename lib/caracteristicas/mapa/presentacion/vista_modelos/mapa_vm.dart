// --- PIEDRA 5 (MAPA): EL "SUPER-MESERO" (VERSIÓN FINAL CON LÓGICA DE RUTA CORREGIDA) ---
//
// 1. (BUG DE RUTA CORREGIDO): 'enfocarRutaEnMapa' AHORA compara
//    usando 'lugar.id' contra 'ruta.lugaresIncluidosIds'.
//    Esto soluciona el bug que te redirigía a Cusco.
// 2. (ESTABLE): Mantiene la lógica de Polilíneas, Zoom y GPS.
// 3. (ESTABLE): Mantiene la corrección del bucle de carga.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// VMs (se mantienen)
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';

// Entidades (se mantienen)
import '../../../inicio/dominio/entidades/lugar.dart';
import '../../../rutas/dominio/entidades/ruta.dart';

// --- Key Global para acceder al Theme ---
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

enum TipoCarrusel { ninguno, lugares, rutas }

class MapaVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS (se mantienen) ---
  LugaresVM? _lugaresVM;
  AutenticacionVM? _authVM;
  RutasVM? _rutasVM;

  // --- B. ESTADO DEL MAPA (¡CON POLILÍNEAS!) ---
  bool _estaCargando = false;
  Set<Marker> _markers = {};
  String? _error;
  bool _cargaInicialRealizada = false;
  Completer<GoogleMapController> _mapController = Completer();
  Set<Polyline> _polylines = {};
  MapType _currentMapType = MapType.normal;

  // --- GEOLOCATOR (se mantienen) ---
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentLocation;

  LatLng? get currentLocation => _currentLocation;

  // --- C. ESTADO DE LA UI (se mantienen) ---
  TipoCarrusel _carruselActual = TipoCarrusel.ninguno;
  List<Lugar> _lugaresFiltrados = [];
  List<Ruta> _rutasFiltradas = [];

  // --- D. GETTERS (¡CON POLILÍNEAS!) ---
  bool get estaCargando => _estaCargando;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  MapType get currentMapType => _currentMapType;
  String? get error => _error;
  TipoCarrusel get carruselActual => _carruselActual;
  List<Lugar> get lugaresFiltrados => _lugaresFiltrados;
  List<Ruta> get rutasFiltradas => _rutasFiltradas;
  // (mapController sigue eliminado)


  // --- MÉTODO PARA RECONSTRUIR EL CONTROLADOR (se mantiene) ---
  void setNewMapController(GoogleMapController controller) {
    if (_mapController.isCompleted) {
      _mapController = Completer();
    }
    _mapController.complete(controller);
  }

  // --- E. CONSTRUCTOR (se mantiene) ---
  MapaVM() {}

  // --- F. MÉTODOS DE INICIALIZACIÓN (¡CORREGIDO!) ---
  void actualizarDependencias(
      LugaresVM lugaresVM, AutenticacionVM authVM, RutasVM rutasVM) {
    if (_cargaInicialRealizada) {
      if (_authVM?.usuarioActual != authVM.usuarioActual) {
        _lugaresVM = lugaresVM;
        _authVM = authVM;
        _rutasVM = rutasVM;
        mostrarTodosLosLugares();
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
      rutasVM.addListener(_onDependenciasReady);
      return;
    }
    _iniciarCargaLogica();
  }

  // Listener temporal (¡CORREGIDO!)
  void _onDependenciasReady() {
    if (_cargaInicialRealizada) return;
    // (CORRECCIÓN DE BUCLE)
    if (!(_lugaresVM?.estaCargandoInicio ?? true) &&
        !(_authVM?.estaCargando ?? true))
    {
      _iniciarCargaLogica();
      _lugaresVM?.removeListener(_onDependenciasReady);
      _authVM?.removeListener(_onDependenciasReady);
      _rutasVM?.removeListener(_onDependenciasReady);
    }
  }

  // Lógica de carga real (se mantiene)
  void _iniciarCargaLogica() {
    _cargaInicialRealizada = true;
    _estaCargando = false;
    _lugaresVM?.addListener(_actualizarListasYMarcadores);
    _authVM?.addListener(_actualizarListasYMarcadores);
    _rutasVM?.addListener(_actualizarListasYMarcadores);
    _actualizarListasYMarcadores();
    notifyListeners();
    iniciarSeguimientoUbicacion();
  }

  // --- MÉTODO DE GEOLOCATOR (se mantiene) ---
  Future<bool> iniciarSeguimientoUbicacion() async {
    if (_positionStreamSubscription != null) return true;
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { return false; }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { return false; }
      }
      if (permission == LocationPermission.deniedForever) { return false; }
      final locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings
      ).listen((Position position) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        notifyListeners();
      });
      return true;
    } catch (e) {
      print("Error en Geolocator: $e");
      return false;
    }
  }

  void detenerSeguimientoUbicacion() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // --- G. LÓGICA DE FILTRADO (¡ACOMPLADA!) ---
  void _actualizarListasYMarcadores() {
    if (!_cargaInicialRealizada || _lugaresVM == null || _authVM == null || _rutasVM == null) {
      return;
    }
    try {
      final todosLosLugares = _lugaresVM!.lugaresTotales;
      final idsFavoritos = _authVM!.lugaresFavoritosIds;
      _lugaresFiltrados = todosLosLugares.where((l) => idsFavoritos.contains(l.id)).toList();
      _rutasFiltradas = _rutasVM!.misRutasInscritas;
      if (_carruselActual == TipoCarrusel.ninguno) {
        _markers = {};
        _polylines = {};
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Helper para crear UN marcador (se mantiene)
  Marker _crearUnMarcador(Lugar lugar) {
    return Marker(
      markerId: MarkerId(lugar.id),
      position: LatLng(lugar.latitud, lugar.longitud),
      infoWindow: InfoWindow(
        title: lugar.nombre,
        snippet: lugar.categoria,
      ),
    );
  }

  // --- H. ÓRDENES DE LA UI (¡ACOMPLADAS!) ---
  void mostrarCarruselLugares() {
    if (_carruselActual == TipoCarrusel.lugares) {
      _carruselActual = TipoCarrusel.ninguno;
      _markers = {};
      _polylines = {};
    } else {
      _carruselActual = TipoCarrusel.lugares;
      _markers = {};
      _polylines = {};
    }
    _actualizarListasYMarcadores();
  }

  void mostrarCarruselRutas() {
    if (_carruselActual == TipoCarrusel.rutas) {
      _carruselActual = TipoCarrusel.ninguno;
      _markers = {};
      _polylines = {};
    } else {
      _carruselActual = TipoCarrusel.rutas;
      _markers = {};
      _polylines = {};
    }
    _actualizarListasYMarcadores();
  }

  void mostrarTodosLosLugares() {
    if (_carruselActual == TipoCarrusel.ninguno) return;
    _carruselActual = TipoCarrusel.ninguno;
    _actualizarListasYMarcadores();
  }

  Future<void> limpiarMarcadores() async {
    _markers = {};
    _polylines = {};
    notifyListeners();
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(const LatLng(-13.517, -71.978), 12));
  }

  // --- ¡NUEVO MÉTODO PARA CAMBIAR TIPO DE MAPA! ---
  void toggleMapType() {
    _currentMapType = (_currentMapType == MapType.normal)
        ? MapType.satellite
        : MapType.normal;
    notifyListeners();
  }

  // --- MÉTODOS DE ZOOM (se mantienen) ---
  Future<void> zoomIn() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> zoomOut() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.zoomOut());
  }

  // --- MÉTODO DE CENTRADO (se mantiene) ---
  Future<void> enfocarMiUbicacion() async {
    if (!_mapController.isCompleted) {
      throw Exception('El mapa no está listo.');
    }
    if (_currentLocation != null) {
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation!,
          zoom: 16,
        ),
      ));
    } else {
      final bool exito = await iniciarSeguimientoUbicacion();
      if (!exito) {
        throw Exception('Por favor, activa el GPS y otorga permisos.');
      }
      await Future.delayed(const Duration(seconds: 1));
      if (_currentLocation != null) {
        final controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 16,
          ),
        ));
      } else {
        throw Exception('Buscando ubicación...');
      }
    }
  }


  // --- ÓRDENES DEL CARRUSEL (ANIMACIÓN CORREGIDA) ---
  Future<void> enfocarLugarEnMapa(Lugar lugar) async {
    if (lugar.latitud == 0.0 && lugar.longitud == 0.0) return;
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lugar.latitud, lugar.longitud),
          zoom: 16,
        ),
      ),
    );
    _markers.add(_crearUnMarcador(lugar));
    _polylines = {};
    notifyListeners();
  }

  // --- ¡MÉTODO DE RUTA CON LÓGICA DE ID CORREGIDA! ---
  Future<void> enfocarRutaEnMapa(Ruta ruta, List<Lugar> todosLosLugares) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;

    // --- ¡AQUÍ ESTÁ LA CORRECCIÓN DEL BUG! ---
    // Usamos 'lugaresIncluidosIds' (la lista de IDs)
    // para comparar con 'lugar.id'.
    final List<Lugar> lugaresDeLaRuta = todosLosLugares
        .where((lugar) =>
    ruta.lugaresIncluidosIds.contains(lugar.id) && // <-- CORREGIDO
        lugar.latitud != 0.0 &&
        lugar.longitud != 0.0)
        .toList();
    // --- FIN DE LA CORRECCIÓN ---

    if (lugaresDeLaRuta.isEmpty) {
      // (Fallback: te redirige a Cusco si no encuentra lugares)
      controller.animateCamera(CameraUpdate.newLatLngZoom(const LatLng(-13.517, -71.978), 12));
      return;
    }

    _markers = {};
    _polylines = {}; // Limpia polilíneas anteriores

    if (lugaresDeLaRuta.length == 1) {
      await enfocarLugarEnMapa(lugaresDeLaRuta.first);
      return;
    }

    // 1. Calcula los límites
    double minLat = lugaresDeLaRuta.first.latitud;
    double maxLat = lugaresDeLaRuta.first.latitud;
    double minLng = lugaresDeLaRuta.first.longitud;
    double maxLng = lugaresDeLaRuta.first.longitud;
    for (var lugar in lugaresDeLaRuta) {
      if (lugar.latitud < minLat) minLat = lugar.latitud;
      if (lugar.latitud > maxLat) maxLat = lugar.latitud;
      if (lugar.longitud < minLng) minLng = lugar.longitud;
      if (lugar.longitud > maxLng) maxLng = lugar.longitud;
    }
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // 2. Anima la cámara PRIMERO
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60.0),
    );

    // 3. Añade TODOS los marcadores
    for (var lugar in lugaresDeLaRuta) {
      _markers.add(_crearUnMarcador(lugar));
    }

    // 4. ¡AÑADE LA POLILÍNEA!
    _polylines.add(
        Polyline(
          polylineId: PolylineId(ruta.id),
          points: lugaresDeLaRuta.map((l) => LatLng(l.latitud, l.longitud)).toList(),
          color: Theme.of(navigatorKey.currentContext!).colorScheme.primary,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        )
    );

    // 5. Notifica a la UI (marcadores y polilínea)
    notifyListeners();
  }


  // --- I. LIMPIEZA DE LISTENERS (se mantiene) ---
  @override
  void dispose() {
    detenerSeguimientoUbicacion();
    _lugaresVM?.removeListener(_onDependenciasReady);
    _authVM?.removeListener(_onDependenciasReady);
    _rutasVM?.removeListener(_onDependenciasReady);
    _lugaresVM?.removeListener(_actualizarListasYMarcadores);
    _authVM?.removeListener(_actualizarListasYMarcadores);
    _rutasVM?.removeListener(_actualizarListasYMarcadores);
    super.dispose();
  }
}
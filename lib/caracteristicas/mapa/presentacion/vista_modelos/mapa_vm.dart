// --- CARACTERISTICAS/MAPA/PRESENTACION/VISTA_MODELOS/MAPA_VM.DART ---
// Versión: DEFINITIVA (Con corrección GPS + Limpiar Ruta + OSRM)

import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';


// VMs
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';

// Entidades
import '../../../inicio/dominio/entidades/lugar.dart';
import '../../../rutas/dominio/entidades/ruta.dart';

// 👇 AGREGA ESTO: Imports para Hakuparadas
import '../../dominio/entidades/hakuparada.dart';
import '../../dominio/servicios/hakuparada_service.dart';


// Key Global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

enum TipoCarrusel { ninguno, lugares, rutas }

class MapaVM extends ChangeNotifier {

  // 👇 AGREGA ESTO: Estado para Hakuparadas
  final HakuparadaService _hakuparadaService = HakuparadaService();
  Hakuparada? _hakuparadaCercana; // La que detectó el radar
  bool _mostrarAlertaHakuparada = false; // Para controlar el UI
  Timer? _timerRadar; // El reloj del radar

  // VISUALIZACIÓN EN MAPA
  List<Marker> _hakuparadaMarkers = [];
  bool _mostrarHakuparadasEnMapa = false; // Default: FALSE (Modo Inteligente / Smart)
  double _zoomLevel = 13.0; // Trackeo de zoom



  // --- A. DEPENDENCIAS ---
  LugaresVM? _lugaresVM;
  AutenticacionVM? _authVM;

  // --- B. ESTADO ---
  bool _estaCargando = false;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  String? _error;
  bool _cargaInicialRealizada = false;

  final MapController mapController = MapController();

  Lugar? _lugarSeleccionado;
  int _filtroActual = 0;
  TipoCarrusel _carruselActual = TipoCarrusel.ninguno;
  List<Lugar> _lugaresFiltrados = [];

  // GPS
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentLocation;

  // --- GETTERS ---
  Hakuparada? get hakuparadaCercana => _hakuparadaCercana;
  bool get mostrarAlertaHakuparada => _mostrarAlertaHakuparada;
  List<Marker> get hakuparadaMarkers => _hakuparadaMarkers;
  bool get mostrarHakuparadasEnMapa => _mostrarHakuparadasEnMapa;

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
  void updateDependencies(LugaresVM lugaresVM, AutenticacionVM authVM, RutasVM rutasVM) {
    if (_cargaInicialRealizada) {
      if (_authVM?.usuarioActual != authVM.usuarioActual) {
        _lugaresVM = lugaresVM;
        _authVM = authVM;
        _actualizarListasYMarcadores();
      }
      return;
    }
    _lugaresVM = lugaresVM;
    _authVM = authVM;

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
    
    // 1. Cargar Hakuparadas (Independiente del GPS)
    _cargarHakuparadasCercanas().then((_) {
      _actualizarMarcadoresHakuparadas(); // Refrescar mapa al terminar carga
    });

    // 2. Intentar iniciar seguimiento (Solo para Radar y Posición)
    iniciarSeguimientoUbicacion();
    
    // 👇 LISTENER DE ZOOM: Actualiza marcadores al hacer zoom
    mapController.mapEventStream.listen((event) {
      if (event is MapEventMoveEnd || event is MapEventRotateEnd) {
        _zoomLevel = mapController.camera.zoom;
        _actualizarMarcadoresHakuparadas();
      }
    });
  }

  // --- LÓGICA DE MARCADORES (LUGARES PRINCIPALES) ---
  void _actualizarListasYMarcadores() {
    if (!_cargaInicialRealizada || _lugaresVM == null || _authVM == null) return;
    if (_carruselActual == TipoCarrusel.rutas) return;

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
          rating: 5.0, provinciaId: '0', usuarioId: '', horario: '', reviewsCount: 0, videoTiktokUrl: '',
        )).toList();
      } else if (_filtroActual == 2) {
        _lugaresFiltrados = todosLosLugares.where((l) => idsFavoritos.contains(l.id)).toList();
      } else if (_filtroActual == 3) {
        _lugaresFiltrados = [];
      }

      _markers.clear();
      _polylines.clear();

      for (var lugar in _lugaresFiltrados) {
        if (lugar.latitud != 0 && lugar.longitud != 0) {
          _markers.add(_crearWidgetMarcador(lugar));
        }
      }

      // 👇 TAMBIÉN ACTUALIZAMOS HAKUPARADAS
      _actualizarMarcadoresHakuparadas();

      _estaCargando = false;
      notifyListeners();
    } catch (e) {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // --- NUEVO: MARCADORES HAKUPARADAS (Zoom > 14) ---
  void toggleHakuparadas() {
    _mostrarHakuparadasEnMapa = !_mostrarHakuparadasEnMapa;
    _actualizarMarcadoresHakuparadas();
    notifyListeners();
  }

  Future<void> _actualizarMarcadoresHakuparadas() async {
    // LÓGICA DE VISIBILIDAD (Refinada por feedback):
    // 1. Si el toggle está ENCENDIDO (_mostrarHakuparadasEnMapa = true) -> SIEMPRE MOSTRAR (Force Show).
    // 2. Si el toggle está APAGADO (_mostrarHakuparadasEnMapa = false) -> MODO INTELIGENTE (Solo Zoom > 14).
    
    bool debeMostrar = _mostrarHakuparadasEnMapa || _zoomLevel >= 14.0;

    if (!debeMostrar) {
      if (_hakuparadaMarkers.isNotEmpty) {
        _hakuparadaMarkers.clear();
        notifyListeners();
      }
      return;
    }

    // 2. Obtener datos (Usamos el cache del servicio para velocidad)
    // El servicio ya se cargó en _iniciarSeguimientoUbicacion -> _cargarHakuparadasCercanas
    // OJO: Aquí podrías añadir lógica para recargar si el usuario se mueve mucho.
    final paradasHelpers = _hakuparadaService.getParadasCache(); // Necesitaremos exponer esto en el servicio

    _hakuparadaMarkers.clear();
    for (var parada in paradasHelpers) {
      if (parada.visible) { // Doble check
        _hakuparadaMarkers.add(_crearMarcadorHakuparada(parada));
      }
    }
    notifyListeners();
  }

  Marker _crearMarcadorHakuparada(Hakuparada parada) {
    // ¿Está cerca? (Efecto Radar Visual)
    final esLaCercana = _hakuparadaCercana?.id == parada.id;
    
    return Marker(
      point: LatLng(parada.latitud, parada.longitud),
      width: esLaCercana ? 60 : 40,  // CRECE si está cerca
      height: esLaCercana ? 60 : 40,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          // Mostrar info básica (Podemos reusar _lugarSeleccionado si lo adaptamos, 
          // o simplemente mostrar un Dialog rápido por ahora)
          // Implementaremos un Dialog rápido para no romper la UI de Lugares
          mapController.move(LatLng(parada.latitud, parada.longitud), 16);
          // TODO: Mostrar Modal Info
        },
        child: _buildHakuparadaPin(parada, esLaCercana),
      ),
    );
  }

  Widget _buildHakuparadaPin(Hakuparada parada, bool esCercana) {
    IconData icono;
    switch (parada.categoria) {
      case 'Mirador': icono = Icons.visibility; break;
      case 'Descanso': icono = Icons.chair; break;
      case 'Servicios Higiénicos': icono = Icons.wc; break;
      case 'Tienda/Kiosko': icono = Icons.store; break;
      case 'Dato Curioso': icono = Icons.lightbulb; break;
      default: icono = Icons.flag;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4), // Cyan
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          if (esCercana) // Efecto Pálpito (Simulado con sombra fuerte)
             BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.6), blurRadius: 15, spreadRadius: 5),
          const BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
      child: Icon(icono, color: Colors.white, size: esCercana ? 30 : 20),
    );
  }

  Marker _crearWidgetMarcador(Lugar lugar) {
    final esRecuerdo = _filtroActual == 1;
    final esFavorito = _filtroActual == 2;

    return Marker(
      point: LatLng(lugar.latitud, lugar.longitud),
      width: esRecuerdo ? 70 : 60,
      height: esRecuerdo ? 70 : 60,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _manejarTapMarcador(lugar),
        child: esRecuerdo ? _buildPolaroidMarker(lugar) : _buildPinMarker(lugar, esFavorito),
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
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          children: [
            Expanded(child: Image.network(lugar.urlImagen, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey))),
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
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
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
    _lugarSeleccionado = lugar;
    mapController.move(LatLng(lugar.latitud, lugar.longitud), 15.0);
    notifyListeners();
  }

  void cerrarDetalle() {
    _lugarSeleccionado = null;
    notifyListeners();
  }

  void setFiltro(int nuevoFiltro) {
    _filtroActual = nuevoFiltro;
    _carruselActual = TipoCarrusel.ninguno;
    _actualizarListasYMarcadores();
    notifyListeners();
  }

  void limpiarRutaPintada() {
    _polylines.clear();
    _markers.clear();
    _lugarSeleccionado = null;
    _carruselActual = TipoCarrusel.ninguno;
    if (_filtroActual != 3) {
      _actualizarListasYMarcadores();
    } else {
      notifyListeners();
    }
  }

  void enfocarRutaEnMapa(Ruta ruta, List<Lugar> todosLosLugares) {
    _estaCargando = true;
    notifyListeners();

    _markers.clear();
    _polylines.clear();

    final lugaresRuta = todosLosLugares.where((l) => ruta.lugaresIncluidosIds.contains(l.id)).toList();
    lugaresRuta.sort((a, b) {
      final indexA = ruta.lugaresIncluidosIds.indexOf(a.id);
      final indexB = ruta.lugaresIncluidosIds.indexOf(b.id);
      return indexA.compareTo(indexB);
    });

    if (lugaresRuta.isEmpty) {
      _estaCargando = false;
      notifyListeners();
      return;
    }

    for (var lugar in lugaresRuta) {
      _markers.add(_crearWidgetMarcador(lugar));
    }

    List<LatLng> puntosParaZoom = [];
    if (ruta.polilinea.isNotEmpty) {
      _polylines.add(
        Polyline(
          points: ruta.polilinea,
          strokeWidth: 5.0,
          color: const Color(0xFF00BCD4),
          borderColor: Colors.white,
          borderStrokeWidth: 2.0,
        ),
      );
      puntosParaZoom = ruta.polilinea;
    } else {
      final points = lugaresRuta.map((l) => LatLng(l.latitud, l.longitud)).toList();
      _polylines.add(Polyline(points: points, strokeWidth: 4.0, color: Colors.grey));
      puntosParaZoom = points;
    }


    if (puntosParaZoom.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(puntosParaZoom);
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          // Aumentamos padding para "alejar" la vista (Zoom Out)
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 140),
        ),
      );
    }

    _carruselActual = TipoCarrusel.rutas;
    _estaCargando = false;
    notifyListeners();
  }

  // --- C. LÓGICA HAKUPARADAS (RADAR) ---

  // 1. Cargar las paradas de la zona (Llamar esto al iniciar o al moverse mucho)
  Future<void> _cargarHakuparadasCercanas() async {
    // 🔥 CORRECCIÓN: Cargamos TODAS las paradas verificadas por ahora.
    // A futuro, cuando sean miles, usaremos geohashing o carga por viewport.
    await _hakuparadaService.cargarParadasPorProvincia(null);
  }

  // 2. El Loop del Radar (Se conecta al GPS)
  void _verificarRadarHakuparadas(LatLng ubicacionActual) {
    // Le preguntamos al cerebro si hay algo cerca
    final paradaDetectada = _hakuparadaService.verificarCercania(ubicacionActual);

    if (paradaDetectada != null) {
      // ¡BINGO! Encontramos una.
      _hakuparadaCercana = paradaDetectada;
      _mostrarAlertaHakuparada = true;
      notifyListeners();

      // Opcional: Vibrar celular aquí si quieres
    }
  }

  // 3. Cerrar la alerta visual
  void cerrarAlertaHakuparada() {
    _mostrarAlertaHakuparada = false;
    notifyListeners();
  }





  // --- GPS MEJORADO ---

  // Devuelve un mensaje de error si falla, o null si todo sale bien.
  // Devuelve un mensaje de error si falla, o null si todo sale bien.
  Future<String?> enfocarMiUbicacion() async {
    // 1. Verificar si el GPS está prendido
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return "⚠️ Por favor, activa el GPS de tu celular.";
    }

    // 2. Verificar Permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "❌ Necesitamos permiso para mostrar tu ubicación.";
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return "❌ Los permisos de ubicación están bloqueados en ajustes.";
    }

    // 3. Estrategia Optimizada: Last Known + Current
    try {
      // A. Intento Rápido: Última ubicación conocida (Caché)
      // Esto suele ser instantáneo.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _currentLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
        mapController.move(_currentLocation!, 16.0);
        notifyListeners();
      }

      // B. Iniciar seguimiento activo (Refinar ubicación)
      // Esto actualizará la posición en cuanto el GPS tenga una lectura fresca
      iniciarSeguimientoUbicacion();
      
      // C. Forzar una lectura fresca si no había lastKnown (con timeout para no bloquear)
      if (lastKnown == null) {
         // Damos feedback visual de "buscando" si quieres, o simplemente esperamos
         Position position = await Geolocator.getCurrentPosition(
           timeLimit: const Duration(seconds: 5)
         );
         _currentLocation = LatLng(position.latitude, position.longitude);
         mapController.move(_currentLocation!, 16.0);
         notifyListeners();
      }

      return null; // Éxito
    } catch (e) {
      if (_currentLocation != null) return null; // Si ya tenemos ubicación (del lastKnown), no mostramos error
      return "No se pudo obtener la ubicación actual.";
    }
  }






  Future<void> iniciarSeguimientoUbicacion() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      // 1. Cargar datos al iniciar
      await _cargarHakuparadasCercanas();

      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {

        // 2. Definimos la nueva ubicación (ESTO FALTABA EN TU CÓDIGO)
        final nuevaUbicacion = LatLng(position.latitude, position.longitude);
        _currentLocation = nuevaUbicacion;

        // 3. Ahora sí pasamos la variable correcta al radar
        _verificarRadarHakuparadas(nuevaUbicacion);

        notifyListeners();
      });
    } catch (e) {
      // Silencioso si falla
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

class _TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final ui.Path path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) => false;
}
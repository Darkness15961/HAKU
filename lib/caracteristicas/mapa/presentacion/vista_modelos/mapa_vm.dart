// --- PIEDRA 5 (MAPA): EL "SUPER-MESERO" (EDICIÓN MEMORABLE: POLAROID) ---
//
// 1. (DISEÑO): Marcadores estilo "Polaroid" (Rectangulares, Marco Blanco, Inclinados).
// 2. (FUNCIONAL): Mantiene GPS, Polilíneas de Rutas y Filtros.
// 3. (EFICIENCIA): Usa CacheManager para no descargar la misma foto mil veces.

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math; // Para cálculos de ángulos

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';

// VMs
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';

// Entidades
import '../../../inicio/dominio/entidades/lugar.dart';
import '../../../rutas/dominio/entidades/ruta.dart';
import '../../../inicio/dominio/entidades/recuerdo.dart';

// Key Global para acceder al Theme
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

enum TipoCarrusel { ninguno, lugares, rutas }

class MapaVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  LugaresVM? _lugaresVM;
  AutenticacionVM? _authVM;
  RutasVM? _rutasVM;

  // --- B. ESTADO DEL MAPA ---
  bool _estaCargando = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String? _error;
  bool _cargaInicialRealizada = false;
  Completer<GoogleMapController> _mapController = Completer();
  MapType _currentMapType = MapType.normal;
  CameraPosition? _lastCameraPosition;

  // Selección y Filtros
  Lugar? _lugarSeleccionado;
  int _filtroActual = 0; // 0: Todos, 1: Recuerdos, 2: Favoritos
  TipoCarrusel _carruselActual = TipoCarrusel.ninguno;

  // Listas filtradas
  List<Lugar> _lugaresFiltrados = [];
  List<Ruta> _rutasFiltradas = [];

  // --- GEOLOCATOR ---
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentLocation;

  // --- GETTERS ---
  bool get estaCargando => _estaCargando;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  MapType get currentMapType => _currentMapType;
  String? get error => _error;
  Lugar? get lugarSeleccionado => _lugarSeleccionado;
  int get filtroActual => _filtroActual;
  LatLng? get currentLocation => _currentLocation;

  // (Getters legacy para compatibilidad)
  TipoCarrusel get carruselActual => _carruselActual;
  List<Lugar> get lugaresFiltrados => _lugaresFiltrados;
  List<Ruta> get rutasFiltradas => _rutasFiltradas;

  // --- CONSTRUCTOR ---
  MapaVM();

  // --- 1. INICIALIZACIÓN Y DEPENDENCIAS ---
  void actualizarDependencias(
    LugaresVM lugaresVM,
    AutenticacionVM authVM,
    RutasVM rutasVM,
  ) {
    if (_cargaInicialRealizada) {
      if (_authVM?.usuarioActual != authVM.usuarioActual) {
        _lugaresVM = lugaresVM;
        _authVM = authVM;
        _rutasVM = rutasVM;
        _actualizarListasYMarcadores(); // Recargar si cambia usuario
      }
      return;
    }

    _lugaresVM = lugaresVM;
    _authVM = authVM;
    _rutasVM = rutasVM;

    // Esperar a que los otros VMs carguen
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
    if (!(_lugaresVM?.estaCargandoInicio ?? true) &&
        !(_authVM?.estaCargando ?? true)) {
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
    _actualizarListasYMarcadores(); // Primera carga de marcadores
    iniciarSeguimientoUbicacion();
  }

  // --- 2. LÓGICA PRINCIPAL: GESTIÓN DE MARCADORES ---

  Future<void> _actualizarListasYMarcadores() async {
    if (!_cargaInicialRealizada || _lugaresVM == null || _authVM == null)
      return;

    try {
      _estaCargando = true;
      notifyListeners();

      final todosLosLugares = _lugaresVM!.lugaresTotales;
      final idsFavoritos = _authVM!.lugaresFavoritosIds;

      // A. Filtrar Lugares
      if (_filtroActual == 0) {
        // Todos
        _lugaresFiltrados = todosLosLugares;
      } else if (_filtroActual == 1) {
        // Mis Recuerdos (Filtro 1)
        // Pedimos los recuerdos al VM de Lugares (que ya los cargó)
        final recuerdos = _lugaresVM!.misRecuerdos;

        // No asignamos a _lugaresFiltrados directamente porque son Recuerdos, no Lugares.
        // Pero para el mapa, generaremos marcadores especiales.
        _lugaresFiltrados = [];
      } else if (_filtroActual == 2) {
        // Por Visitar
        _lugaresFiltrados = todosLosLugares
            .where((l) => idsFavoritos.contains(l.id))
            .toList();
      }

      // B. Generar Marcadores (Solo si no estamos viendo una ruta específica)
      if (_carruselActual != TipoCarrusel.rutas) {
        _markers = {};
        _polylines = {}; // Limpiar rutas si estamos explorando lugares

        // CASO ESPECIAL: RECUERDOS
        if (_filtroActual == 1) {
          final recuerdos = _lugaresVM!.misRecuerdos;
          for (var recuerdo in recuerdos) {
            // Adaptamos el Recuerdo a un Lugar temporal para poder usar tu lógica de Polaroid existente
            final lugarAdaptado = Lugar(
              id: 'recuerdo_${recuerdo.id}',
              nombre: recuerdo.nombreRuta,
              descripcion: recuerdo.comentario ?? 'Un momento inolvidable.',
              urlImagen: recuerdo.fotoUrl, // ¡La foto que subió el usuario!
              latitud: recuerdo.latitud,
              longitud: recuerdo.longitud,
              rating: 5.0,
              provinciaId: '0',
              usuarioId: '',
              horario: 'Recuerdo ${recuerdo.fecha.day}/${recuerdo.fecha.month}',
              reviewsCount: 0,
              videoTiktokUrl: '',
            );

            // Creamos la Polaroid
            final marker = await _crearMarcadorPolaroid(lugarAdaptado);
            _markers.add(marker);
          }
        } else {
          // CASO NORMAL (Todos o Favoritos)
          for (var lugar in _lugaresFiltrados) {
            if (lugar.latitud != 0 && lugar.longitud != 0) {
              // Crear marcador según el filtro actual
              final marker = await _crearMarcador(lugar);
              _markers.add(marker);
            }
          }
        }
      }

      _estaCargando = false;
      notifyListeners();
    } catch (e) {
      print("Error generando mapa: $e");
      _estaCargando = false;
      notifyListeners();
    }
  }

  // --- 3. DIBUJADO DE MARCADORES (CANVAS) ---

  // Método que decide qué tipo de marcador crear según el filtro
  Future<Marker> _crearMarcador(Lugar lugar) async {
    if (_filtroActual == 0) {
      // "Explorar Todo": Marcador circular con borde celeste
      return await _crearMarcadorCircular(lugar);
    } else if (_filtroActual == 1) {
      // "Mis Recuerdos": Marcador Polaroid
      return await _crearMarcadorPolaroid(lugar);
    } else {
      // "Por Visitar" (filtro 2): Pin rojo por defecto de Google Maps
      return Marker(
        markerId: MarkerId(lugar.id),
        position: LatLng(lugar.latitud, lugar.longitud),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        zIndex: -lugar.latitud,
        onTap: () {
          _lugarSeleccionado = lugar;
          notifyListeners();
        },
      );
    }
  }

  // Marcador CIRCULAR con borde CELESTE para "Explorar Todo"
  Future<Marker> _crearMarcadorCircular(Lugar lugar) async {
    BitmapDescriptor icon;
    try {
      icon = await _crearIconoCircular(lugar.urlImagen);
    } catch (e) {
      // Fallback si la imagen falla
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    }

    return Marker(
      markerId: MarkerId(lugar.id),
      position: LatLng(lugar.latitud, lugar.longitud),
      icon: icon,
      zIndex: -lugar.latitud,
      onTap: () {
        final context = navigatorKey.currentContext;
        if (context != null) {
          context.push('/inicio/detalle-lugar', extra: lugar);
        }
      },
    );
  }

  // Marcador POLAROID para "Mis Recuerdos"

  Future<Marker> _crearMarcadorPolaroid(Lugar lugar) async {
    BitmapDescriptor icon;
    try {
      icon = await _crearIconoBitmap(lugar.urlImagen);
    } catch (e) {
      // Fallback si la imagen falla
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }

    return Marker(
      markerId: MarkerId(lugar.id),
      position: LatLng(lugar.latitud, lugar.longitud),
      icon: icon,
      zIndex: -lugar.latitud,
      onTap: () {
        // Si estamos en "Explorar Todo" (filtro 0), navegar directamente
        if (_filtroActual == 0) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            // Usar go_router para navegar
            context.push('/inicio/detalle-lugar', extra: lugar);
          }
        } else {
          // En "Mis Recuerdos" o "Por Visitar", mostrar Polaroid
          _lugarSeleccionado = lugar;
          notifyListeners();
        }
      },
    );
  }

  Future<BitmapDescriptor> _crearIconoBitmap(String url) async {
    // 1. Descargar y Decodificar
    final File markerImageFile = await DefaultCacheManager().getSingleFile(url);
    final Uint8List imageBytes = await markerImageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: 140,
      targetHeight: 140,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    // 2. Configurar Lienzo
    const double canvasSize = 220.0;
    const double frameWidth = 170.0;
    const double frameHeight = 190.0; // Más alto abajo (estilo polaroid)
    const double photoSize = 140.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      pictureRecorder,
      Rect.fromLTWH(0, 0, canvasSize, canvasSize),
    );

    final Paint paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // 3. Rotación "Casual"
    canvas.translate(canvasSize / 2, canvasSize / 2); // Mover al centro
    // Usamos el hash de la URL para que la inclinación sea fija por lugar (no baile)
    final double angle = (url.hashCode % 30 - 15) / 100.0; // +/- 0.15 radianes
    canvas.rotate(angle);
    canvas.translate(
      -frameWidth / 2,
      -frameHeight / 2,
    ); // Volver origen relativo

    // 4. Sombra
    final Path shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, frameWidth, frameHeight),
          const Radius.circular(4),
        ),
      );
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.5), 8.0, true);

    // 5. Marco Blanco
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, frameWidth, frameHeight),
        const Radius.circular(4),
      ),
      paint,
    );

    // 6. Foto
    // Calcular márgenes para centrar horizontalmente
    const double horizontalMargin = (frameWidth - photoSize) / 2;
    const double topMargin = 15.0;

    paint.style = PaintingStyle.fill;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(horizontalMargin, topMargin, photoSize, photoSize),
      paint,
    );

    // Opcional: Borde fino a la foto
    paint.color = Colors.grey.shade300;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(horizontalMargin, topMargin, photoSize, photoSize),
      paint,
    );

    // 7. Convertir a Bitmap
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  // Crear icono CIRCULAR con borde CELESTE
  Future<BitmapDescriptor> _crearIconoCircular(String url) async {
    // 1. Descargar y Decodificar
    final File markerImageFile = await DefaultCacheManager().getSingleFile(url);
    final Uint8List imageBytes = await markerImageFile.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: 120,
      targetHeight: 120,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    // 2. Configurar Lienzo
    const double canvasSize = 160.0;
    const double photoSize = 120.0;
    const double borderWidth = 6.0;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      pictureRecorder,
      Rect.fromLTWH(0, 0, canvasSize, canvasSize),
    );

    final Paint paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    // Centro del canvas
    final double center = canvasSize / 2;
    final double radius = photoSize / 2;

    // 3. Sombra
    paint.color = Colors.black.withValues(alpha: 0.3);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      Offset(center + 2, center + 2),
      radius + borderWidth,
      paint,
    );
    paint.maskFilter = null;

    // 4. Borde CELESTE
    paint.color = const Color(0xFF00BCD4); // Color celeste del tema
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), radius + borderWidth, paint);

    // 5. Círculo blanco interno (para separar la foto del borde)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(center, center), radius + 2, paint);

    // 6. Clip circular para la foto
    final Path clipPath = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(center, center), radius: radius),
      );
    canvas.clipPath(clipPath);

    // 7. Dibujar la foto
    paint.style = PaintingStyle.fill;
    final double imageOffset = (canvasSize - photoSize) / 2;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(imageOffset, imageOffset, photoSize, photoSize),
      paint,
    );

    // 8. Convertir a Bitmap
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  // --- 4. ACCIONES Y NAVEGACIÓN EN EL MAPA ---

  void cerrarDetalle() {
    _lugarSeleccionado = null;
    notifyListeners();
  }

  void cambiarFiltro(int nuevoFiltro) {
    _filtroActual = nuevoFiltro;
    _carruselActual =
        TipoCarrusel.ninguno; // Salir de modo ruta si estaba activo
    _actualizarListasYMarcadores();
  }

  void toggleMapType() {
    _currentMapType = (_currentMapType == MapType.normal)
        ? MapType.satellite
        : MapType.normal;
    notifyListeners();
  }

  // Enfocar un Lugar (zoom y selección)
  Future<void> enfocarLugarEnMapa(Lugar lugar) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lugar.latitud, lugar.longitud), 15),
    );

    // Limpiamos y mostramos solo este marcador
    _markers = {};
    _markers.add(await _crearMarcadorPolaroid(lugar));
    _polylines = {};
    _lugarSeleccionado = lugar;

    notifyListeners();
  }

  // Enfocar una Ruta (con Polilínea y Límites)
  Future<void> enfocarRutaEnMapa(Ruta ruta, List<Lugar> todosLosLugares) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;

    // Filtramos los lugares de la ruta
    final lugaresRuta = todosLosLugares
        .where((l) => ruta.lugaresIncluidosIds.contains(l.id))
        .toList();
    if (lugaresRuta.isEmpty) return;

    _markers = {};
    _polylines = {};

    // Marcadores Polaroid para cada parada
    for (var lugar in lugaresRuta) {
      _markers.add(await _crearMarcadorPolaroid(lugar));
    }

    // Polilínea
    _polylines.add(
      Polyline(
        polylineId: PolylineId(ruta.id),
        points: lugaresRuta.map((l) => LatLng(l.latitud, l.longitud)).toList(),
        color: const Color(0xFF00BCD4),
        width: 5,
      ),
    );

    // Zoom Ajustado (Bounds)
    double minLat = lugaresRuta.first.latitud, maxLat = minLat;
    double minLng = lugaresRuta.first.longitud, maxLng = minLng;

    for (var l in lugaresRuta) {
      if (l.latitud < minLat) minLat = l.latitud;
      if (l.latitud > maxLat) maxLat = l.latitud;
      if (l.longitud < minLng) minLng = l.longitud;
      if (l.longitud > maxLng) maxLng = l.longitud;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80.0, // Padding
      ),
    );

    // Indicamos que estamos en modo ruta para que la UI lo sepa si es necesario
    _carruselActual = TipoCarrusel.rutas;
    notifyListeners();
  }

  // --- 5. UTILIDADES (GPS, CÁMARA) ---

  void setNewMapController(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
    _restaurarPosicionCamara();
  }

  Future<void> enfocarMiUbicacion() async {
    if (!_mapController.isCompleted) return;

    if (_currentLocation != null) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 16),
        ),
      );
    } else {
      await iniciarSeguimientoUbicacion();
    }
  }

  Future<bool> iniciarSeguimientoUbicacion() async {
    // (Tu lógica de Geolocator intacta)
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
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((Position position) {
            _currentLocation = LatLng(position.latitude, position.longitude);
            notifyListeners();
          });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Persistencia de cámara
  Future<void> onCameraMove(CameraPosition position) async {
    _lastCameraPosition = position;
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('lat', position.target.latitude);
    prefs.setDouble('lng', position.target.longitude);
    prefs.setDouble('zoom', position.zoom);
  }

  Future<void> _restaurarPosicionCamara() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('lat');
    final lng = prefs.getDouble('lng');
    if (lat != null && lng != null && _mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          prefs.getDouble('zoom') ?? 12,
        ),
      );
    }
  }

  // --- 6. LIMPIEZA ---

  Future<void> limpiarMarcadores() async {
    // Restablecer a vista general
    _filtroActual = 0;
    _carruselActual = TipoCarrusel.ninguno;
    await _actualizarListasYMarcadores();
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(const LatLng(-13.517, -71.978), 12),
      );
    }
  }

  Future<void> zoomIn() async {
    if (_mapController.isCompleted)
      (await _mapController.future).animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> zoomOut() async {
    if (_mapController.isCompleted)
      (await _mapController.future).animateCamera(CameraUpdate.zoomOut());
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

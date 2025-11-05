// --- PIEDRA 1 (BLOQUE 5): EL "MESERO DE MAPA" (¡ARREGLADO!) ---
//
// Esta es la versión 100% CORREGIDA.
//
// 1. ¡YA NO SE CARGA SOLO! (Quitamos la carga del constructor)
// 2. Ahora espera a que el "Menú" (UI) le dé la "orden"
//    de "cargarDatosIniciales".

import 'package:flutter/material.dart';
// 1. Importamos la herramienta de Google Maps
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 2. Importamos los "Meseros" que escuchará
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';

// 3. Importamos la "Receta" que necesita
import '../../../inicio/dominio/entidades/lugar.dart';

// 4. "extends ChangeNotifier" (para poder "avisar" a la UI)
class MapaVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  final LugaresVM? _lugaresVM;
  final AutenticacionVM? _authVM;

  // --- B. ESTADO DE LA UI ---
  bool _estaCargando = true; // Empieza cargando
  Set<Marker> _marcadores = {};
  List<Lugar> _lugaresFavoritos = [];
  static const CameraPosition _posicionInicialCusco = CameraPosition(
    target: LatLng(-13.5319, -71.9675),
    zoom: 12,
  );

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  Set<Marker> get marcadores => _marcadores;
  List<Lugar> get lugaresFavoritos => _lugaresFavoritos;
  CameraPosition get posicionInicialCusco => _posicionInicialCusco;
  bool get mostrarCarrusel =>
      (_authVM?.estaLogueado ?? false) && _lugaresFavoritos.isNotEmpty;

  // --- D. CONSTRUCTOR ---
  // ¡ARREGLADO!
  // El "Mesero" ahora es "perezoso" (lazy).
  // Solo se prepara, no "cocina" nada todavía.
  MapaVM(this._lugaresVM, this._authVM) {
    // "Escuchamos" a los otros "Meseros".
    _lugaresVM?.addListener(_actualizarDatosDelMapa);
    _authVM?.addListener(_actualizarDatosDelMapa);

    // --- ¡ERROR ARREGLADO! ---
    // Quitamos la llamada a "_actualizarDatosDelMapa()"
    // de aquí. Ya no se carga solo.
    // _actualizarDatosDelMapa(); // <-- ESTO CAUSABA EL BUCLE
  }

  // --- E. MÉTODOS (Las "Órdenes") ---

  // ¡NUEVO MÉTODO DE CARGA INICIAL!
  // Esta es la "orden" que el "Menú" (UI) llamará
  // UNA SOLA VEZ (en el initState).
  void cargarDatosIniciales() {
    // Solo cargamos si los "Meseros" ya están listos
    if (_lugaresVM != null && _authVM != null) {
      _actualizarDatosDelMapa();
    }
  }

  // Esta es la función principal que "cocina" los datos del mapa
  void _actualizarDatosDelMapa() {
    _estaCargando = true;
    Future.microtask(() => notifyListeners()); // Avisamos (de forma segura)

    // Revisamos de nuevo (por si acaso)
    if (_lugaresVM == null || _authVM == null) {
      _estaCargando = false;
      Future.microtask(() => notifyListeners());
      return;
    }

    // --- Lógica de Marcadores (Pines) ---
    final Set<Marker> nuevosMarcadores = {};
    // (Usamos lugaresPopulares como fuente de pines,
    // puedes cambiarlo a una lista completa si la tuvieras)
    final todosLosLugares = _lugaresVM!.lugaresPopulares;

    for (final lugar in todosLosLugares) {
      nuevosMarcadores.add(
        Marker(
          markerId: MarkerId(lugar.id),
          position: LatLng(lugar.latitud, lugar.longitud),
          infoWindow: InfoWindow(
            title: lugar.nombre,
            snippet: lugar.categoria,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // --- Lógica de Carrusel de Favoritos ---
    // (Simulación basada en tu maqueta)
    if (_authVM!.estaLogueado) {
      _lugaresFavoritos = todosLosLugares.take(2).toList(); // Simulación
    } else {
      _lugaresFavoritos = [];
    }

    _marcadores = nuevosMarcadores;
    _estaCargando = false;
    notifyListeners(); // "Avisamos" que el mapa está listo
  }

  // --- Limpieza ---
  @override
  void dispose() {
    _lugaresVM?.removeListener(_actualizarDatosDelMapa);
    _authVM?.removeListener(_actualizarDatosDelMapa);
    super.dispose();
  }
}
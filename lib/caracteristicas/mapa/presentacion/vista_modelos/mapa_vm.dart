// --- PIEDRA 5 (MAPA): EL "MESERO DE MAPA" (CORREGIDO) ---
//
// Sigue la misma lógica que el RutasVM.
// Se crea "tonto" y la MapaPagina lo "despierta"
// pasándole las dependencias.
//
// --- CAMBIOS ---
// - Se corrigió 'estaCargando' por 'estaCargandoInicio'
// - Se corrigió 'lugares' por 'lugaresPopulares'
// - Se corrigió la lógica de 'favoritos' (ya que 'Lugar' no tiene 'esFavorita')
// - ¡SE CORRIGIÓ EL TYPO EN EL IMPORT DE AUTENTICACION!

import 'package:flutter/material.dart';
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
// --- ¡CORREGIDO! ---
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS (Inicialmente nulas) ---
  LugaresVM? _lugaresVM;
  AutenticacionVM? _authVM;

  // --- B. ESTADO DE LA UI ---
  bool _estaCargando = false;
  Set<Marker> _markers = {};
  String? _error;
  bool _cargaInicialRealizada = false;
  List<Lugar> _favoritos = []; // Estado para el carrusel

  // --- C. GETTERS ---
  bool get estaCargando => _estaCargando;
  Set<Marker> get markers => _markers;
  String? get error => _error;
  List<Lugar> get favoritos => _favoritos;

  // --- D. CONSTRUCTOR (¡SÚPER LIMPIO!) ---
  MapaVM() {
    // Constructor 100% limpio.
    // Coincide con el create: (context) => MapaVM() de main.dart
  }

  // --- E. MÉTODO DE CARGA INICIAL (RECIBE DEPENDENCIAS) ---
  // La página (mapa_pagina.dart) llamará a este método
  void cargarDatosIniciales(LugaresVM lugaresVM, AutenticacionVM authVM) {
    if (_cargaInicialRealizada) return;

    // 1. Guardamos las referencias
    _lugaresVM = lugaresVM;
    _authVM = authVM;

    // 2. Verificamos si los VMs de los que dependemos están listos
    // --- ¡CORREGIDO! ---
    if ((_lugaresVM?.estaCargandoInicio ?? false) || (_authVM?.estaCargando ?? false)) {
      _estaCargando = true;
      notifyListeners();
      // Agregamos listeners temporales a AMBOS
      _lugaresVM?.addListener(_onDependenciasReady);
      _authVM?.addListener(_onDependenciasReady);
      return;
    }

    // 3. Si ambos están listos (Anónimo y lugares cargados), iniciamos.
    _iniciarCargaLogica();
  }

  // Listener temporal
  void _onDependenciasReady() {
    // Se llamará dos veces, pero la lógica interna lo maneja
    // --- ¡CORREGIDO! ---
    if (!(_lugaresVM?.estaCargandoInicio ?? false) && !(_authVM?.estaCargando ?? false)) {
      // Cuando AMBOS estén listos
      _iniciarCargaLogica();
      // Quitamos los listeners
      _lugaresVM?.removeListener(_onDependenciasReady);
      _authVM?.removeListener(_onDependenciasReady);
    }
  }

  // Lógica de carga real
  void _iniciarCargaLogica() {
    // Nos suscribimos a listeners permanentes
    _lugaresVM?.addListener(_actualizarMarcadoresYFavoritos);
    _authVM?.addListener(_actualizarMarcadoresYFavoritos);

    // Ejecutamos la carga por primera vez
    _actualizarMarcadoresYFavoritos();
  }

  // Método que actualiza todo
  void _actualizarMarcadoresYFavoritos() {
    if (_lugaresVM == null || _authVM == null) return; // Seguridad

    _estaCargando = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      // 1. Lógica de Marcadores (de LugaresVM)
      // --- ¡CORREGIDO! ---
      final lugares = _lugaresVM!.lugaresPopulares;
      _markers = lugares.map((lugar) {
        return Marker(
          markerId: MarkerId(lugar.id),
          position: LatLng(lugar.latitud, lugar.longitud),
          infoWindow: InfoWindow(title: lugar.nombre),
          // TODO: Añadir onTap para navegar
        );
      }).toSet();

      // 2. Lógica de Favoritos (de AuthVM y LugaresVM)
      if (_authVM!.estaLogueado) {
        // --- ¡CORREGIDO! ---
        // Tu entidad 'Lugar' no tiene la propiedad 'esFavorita'.
        // Esta lógica debe conectarse al estado de favoritos del AuthVM
        // o un repositorio de favoritos dedicado.
        // Por ahora, lo dejamos vacío para que no crashee.
        _favoritos = [];
        // _favoritos = _lugaresVM!.lugaresPopulares.where((l) => l.esFavorita).toList();
      } else {
        _favoritos = []; // Anónimo no tiene favoritos
      }

      _estaCargando = false;
      _cargaInicialRealizada = true;
      notifyListeners();

    } catch (e) {
      _estaCargando = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // --- F. LIMPIEZA DE LISTENERS ---
  @override
  void dispose() {
    _lugaresVM?.removeListener(_onDependenciasReady);
    _authVM?.removeListener(_onDependenciasReady);
    _lugaresVM?.removeListener(_actualizarMarcadoresYFavoritos);
    _authVM?.removeListener(_actualizarMarcadoresYFavoritos);
    super.dispose();
  }
}
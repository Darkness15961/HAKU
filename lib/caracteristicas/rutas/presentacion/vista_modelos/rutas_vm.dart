// --- CARACTERISTICAS/RUTAS/PRESENTACION/VISTA_MODELOS/RUTAS_VM.DART ---
// Versión: CON CEREBRO OSRM (Calcula la ruta antes de guardar)

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // <--- NUEVO IMPORT (Para manejar coordenadas)
import '../../dominio/repositorios/rutas_repositorio.dart';
import '../../datos/repositorios/rutas_repositorio_supabase.dart';
import '../../dominio/entidades/ruta.dart';
import '../../dominio/entidades/participante_ruta.dart';
import '../../../../locator.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../datos/servicios/osrm_service.dart'; // <--- NUEVO IMPORT (Tu servicio calculadora)


class RutasVM extends ChangeNotifier {
  // --- A. DEPENDENCIAS ---
  late final RutasRepositorio _repositorio;
  final OsrmService _osrmService = OsrmService(); // <--- Instancia del servicio
  AutenticacionVM? _authVM;

  // --- B. ESTADO DE LA UI (MULTILISTA) ---
  bool _estaCargandoAccion = false; // Para crear/editar/eliminar
  final Map<String, bool> _cargandoPestanas = {
    'Recomendadas': false,
    'Mis Inscripciones': false,
    'Creadas por mí': false,
    'Guardadas': false,
  };
  
  // Cache por pestaña para evitar "Sangrado de Datos"
  final Map<String, List<Ruta>> _listasRutas = {
    'Recomendadas': [],
    'Mis Inscripciones': [],
    'Creadas por mí': [],
    'Guardadas': [], // Si se usa
  };

  // Estado de Paginación por Pestaña
  final Map<String, int> _pages = {
    'Recomendadas': 0, 'Mis Inscripciones': 0, 'Creadas por mí': 0, 'Guardadas': 0
  };
  final Map<String, bool> _hasMoreMap = {
    'Recomendadas': true, 'Mis Inscripciones': true, 'Creadas por mí': true, 'Guardadas': true
  };

  String _pestanaActual = 'Recomendadas';
  String _categoriaActual = 'Todos';
  String? _error;
  bool _cargaInicialRealizada = false; // Indica si 'Recomendadas' ya cargó al menos una vez

  bool _isLoadingMore = false;
  final int _pageSize = 6; // Re-added constant
  
  // --- MÓDULO PARTICIPANTES ---
  bool _cargandoParticipantes = false;
  List<ParticipanteRuta> _participantes = [];

  // --- MÓDULO HISTORIAL ---
  bool _cargandoHistorial = false;
  List<Ruta> _historialRutas = [];
  
  // Categorías
  List<Map<String, dynamic>> _categoriasDisponibles = [];




  // --- C. GETTERS ---
  bool get estaCargando => _estaCargandoAccion || (_cargandoPestanas[_pestanaActual] ?? false);
  String get pestanaActual => _pestanaActual;
  String get categoriaActual => _categoriaActual;
  String? get error => _error;
  bool get cargaInicialRealizada => _cargaInicialRealizada;
  
  bool get hasMore => _hasMoreMap[_pestanaActual] ?? false;
  bool get isLoadingMore => _isLoadingMore;
  List<ParticipanteRuta> get participantes => _participantes;
  bool get cargandoParticipantes => _cargandoParticipantes;
  
  List<Ruta> get historialRutas => _historialRutas;
  bool get cargandoHistorial => _cargandoHistorial;
  
  List<Map<String, dynamic>> get categoriasDisponibles => _categoriasDisponibles;

  


  // Getter principal para la UI (Lista Filtrada)
  List<Ruta> get rutasFiltradas {
    final rutasDePestana = _listasRutas[_pestanaActual] ?? [];
    
    // Filtro local por categoría (si aplica)
    if (_categoriaActual == 'Todos') {
      return rutasDePestana;
    } else {
      return rutasDePestana.where((ruta) {
        return ruta.categoria.toLowerCase() == _categoriaActual.toLowerCase();
      }).toList();
    }
  }

  // Getter específico para el MAPA (siempre retorna las inscritas, cargadas o no)
  // NOTA: Si están vacías, quizás el Mapa deba pedir cargarlas.
  List<Ruta> get misRutasInscritas {
    // Retornamos la lista dedicada, sin depender de la pestaña actual
    return _listasRutas['Mis Inscripciones'] ?? [];
  }

  // Getter específico para el MAPA para rutas creadas
  List<Ruta> get misRutasCreadas {
    return _listasRutas['Creadas por mí'] ?? [];
  }
 
  // --- D. CONSTRUCTOR ---
  RutasVM() {
    _repositorio = getIt<RutasRepositorio>();
  }

  // --- E. MÉTODOS DE CARGA ---
  void cargarDatosIniciales(AutenticacionVM authVM) {
    if (_cargaInicialRealizada) return;
    _authVM = authVM;
    if (_authVM?.estaCargando ?? false) {
      _authVM?.addListener(_onAuthReadyParaRutas);
      return;
    }
    _iniciarCargaLogica();
  }

  void _onAuthReadyParaRutas() {
    _iniciarCargaLogica();
    _authVM?.removeListener(_onAuthReadyParaRutas);
  }

  void _iniciarCargaLogica() {
    _authVM?.addListener(_actualizarPestanaPorRol);
    _actualizarPestanaPorRol();
    
    // ESTRATEGIA: Cargar también 'Mis Inscripciones' en background si está logueado
    // para que el Mapa las tenga listas.
    if (_authVM?.estaLogueado ?? false) {
      _cargarListaEspecifica('Mis Inscripciones');
      
      final rol = _authVM?.usuarioActual?.rol;
      if (rol == 'guia' || rol == 'guia_aprobado' || rol == 'guia_local' || rol == 'admin') {
         _cargarListaEspecifica('Creadas por mí');
      }
    }
  }

  void _actualizarPestanaPorRol() {
    final rol = _authVM?.usuarioActual?.rol;


    if (_pestanaActual == 'Creadas por mí' &&
        rol != 'guia_aprobado' &&
        rol != 'guia' &&
        rol != 'guia_local' &&
        rol != 'admin') {
      _pestanaActual = 'Recomendadas';
    }
    
    // Si la lista actual está vacía y no estamos cargando, cargarla.
    if ((_listasRutas[_pestanaActual]?.isEmpty ?? true) && !estaCargando) {
      cargarRutas();
    }
  }

  // Método público para "Cargar Más"
  Future<void> cargarMasRutas() async {
    if (_isLoadingMore || !hasMore) return;
    await cargarRutas(refresh: false);
  }

  // Carga la pestaña ACTUAL
  Future<void> cargarRutas({bool refresh = true}) async {
    await _cargarListaEspecifica(_pestanaActual, refresh: refresh);
  }

  // Método interno y versátil que carga CUALQUIER lista
  Future<void> _cargarListaEspecifica(String pestanaObjetivo, {bool refresh = true}) async {
    // Evitamos pisar estados si estamos cargando la pestaña activa
    bool esPestanaActiva = (pestanaObjetivo == _pestanaActual);

    if (refresh) {
      _cargandoPestanas[pestanaObjetivo] = true; // 🔥 FIXED: Per-tab loading
      _error = null;
      if (esPestanaActiva) {
        if (pestanaObjetivo == 'Recomendadas') _cargaInicialRealizada = false; 
        notifyListeners();
      }
    } else if (esPestanaActiva) {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      // 1. Determinar Filtro
      String tipoFiltro = 'recomendadas';
      if (pestanaObjetivo == 'Mis Inscripciones') {
        tipoFiltro = 'inscritas';
      } else if (pestanaObjetivo == 'Creadas por mí') {
        tipoFiltro = 'creadas_por_mi';
      }

      // 2. Determinar Paginación
      int page = refresh ? 0 : (_pages[pestanaObjetivo] ?? 0);
      
      // 3. Llamada al Repo
      print('🔄 [VM] Cargando para "$pestanaObjetivo" ($tipoFiltro). Page: $page');
      
      final nuevasRutas = await _repositorio.obtenerRutas(
        tipoFiltro,
        page: page,
        pageSize: _pageSize,
      );

      // 4. Actualizar Estado (Lista Específica)
      if (refresh) {
        _listasRutas[pestanaObjetivo] = nuevasRutas;
        _pages[pestanaObjetivo] = 1; // Próxima página
        _hasMoreMap[pestanaObjetivo] = nuevasRutas.length >= _pageSize;
      } else {
        _listasRutas[pestanaObjetivo]?.addAll(nuevasRutas);
        if (nuevasRutas.length < _pageSize) {
          _hasMoreMap[pestanaObjetivo] = false;
        } else {
           _pages[pestanaObjetivo] = (_pages[pestanaObjetivo] ?? 0) + 1;
        }
      }

    } catch (e) {
      if (pestanaObjetivo == _pestanaActual) _error = e.toString();
      debugPrint('Error cargando $pestanaObjetivo: $e');
    } finally {
      // Clean up local loading state
      _cargandoPestanas[pestanaObjetivo] = false; // 🔥 FIXED

      if (pestanaObjetivo == _pestanaActual) {
        _isLoadingMore = false;
        if (refresh && pestanaObjetivo == 'Recomendadas') _cargaInicialRealizada = true;
        notifyListeners();
      } else {
        // Si cargamos una lista en background (ej: Mis Inscripciones para el mapa)
        // Notificamos para que el mapa se entere si está escuchando
        notifyListeners(); 
      }
    }
  }

  @override
  void dispose() {
    _authVM?.removeListener(_actualizarPestanaPorRol);
    _authVM?.removeListener(_onAuthReadyParaRutas);
    super.dispose();
  }

  // --- G. MÉTODOS DE ACCIÓN ---

  void cambiarPestana(String nuevaPestana) {
    if (nuevaPestana == _pestanaActual) return;
    _pestanaActual = nuevaPestana;
    _categoriaActual = 'Todos';
    
    // OPTIMIZACIÓN CACHE INTELIGENTE:
    // 1. Verificamos si ya tenemos datos en la "caja" de destino.
    final listaObjetivo = _listasRutas[nuevaPestana];
    
    if (listaObjetivo != null && listaObjetivo.isNotEmpty) {
      // CASO A: ¡Ya tenemos datos! 
      // Mostramos lo que hay en memoria INSTANTÁNEAMENTE.
      // (Si el usuario quiere ver si hay algo nuevo, usará el "deslizar para actualizar" de la lista).
      notifyListeners();
    } else {
      // CASO B: La caja está vacía (primera vez que entra).
      // Cargamos de internet.
      cargarRutas(refresh: true); 
    }
  }

  void cambiarCategoria(String nuevaCategoria) {
    if (nuevaCategoria == _categoriaActual) return;
    _categoriaActual = nuevaCategoria;
    notifyListeners();
  }

  Future<void> inscribirseEnRuta(String rutaId) async {
    await _repositorio.inscribirseEnRuta(rutaId);
    await _authVM?.toggleRutaInscrita(rutaId);
    // Actualizar cache de inscripciones para el Mapa
    _cargarListaEspecifica('Mis Inscripciones');
    // Actualizar vista actual (cupos)
    cargarRutas(refresh: true);
  }

  Future<void> unirseARutaPorCodigo(String codigo) async {
    _estaCargandoAccion = true;
    _error = null;
    notifyListeners();
    try {
      if (_repositorio is RutasRepositorioSupabase) {
        await _repositorio.unirseARutaPorCodigo(codigo);
      } else {
        await _repositorio.unirseARutaPorCodigo(codigo);
      }
      _estaCargandoAccion = false;
      notifyListeners();
      
      // Actualizar cache crítica para el Mapa
      await _cargarListaEspecifica('Mis Inscripciones');
      
      // Si estamos en otra pestaña, refrescarla también
      if (_pestanaActual != 'Mis Inscripciones') {
        cargarRutas(refresh: true);
      }
    } catch (e) {
      _estaCargandoAccion = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> salirDeRuta(String rutaId) async {
    await _repositorio.salirDeRuta(rutaId);
    await _authVM?.toggleRutaInscrita(rutaId);
    _cargarListaEspecifica('Mis Inscripciones');
    cargarRutas(refresh: true);
  }

  Future<void> toggleFavoritoRuta(String rutaId) async {
    await _authVM?.toggleRutaFavorita(rutaId);
  }

  // --- ¡AQUÍ ESTÁ LA MAGIA OSRM! (Método Modificado) ---
  Future<void> crearRuta(Map<String, dynamic> datosRuta) async {
    _estaCargandoAccion = true;
    _error = null;
    notifyListeners();

    try {
      // 1. CALCULAR GEOMETRÍA (Si Aplica)
      await _calcularGeometriaOSRM(datosRuta);

      // 2. GUARDAR EN BASE DE DATOS (Lo de siempre)
      await _repositorio.crearRuta(datosRuta);

      _estaCargandoAccion = false;
      notifyListeners();
      
      // Actualizar ambas listas afectadas
      await _cargarListaEspecifica('Creadas por mí');
      await _cargarListaEspecifica('Recomendadas');


    } catch (e) {
      _estaCargandoAccion = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  // --- HELPER PRIVADO OSRM ---
  Future<void> _calcularGeometriaOSRM(Map<String, dynamic> datosRuta) async {
      List<LatLng> puntosParaCalculo = [];
      if (datosRuta['puntos_coordenadas'] != null) {
        puntosParaCalculo = datosRuta['puntos_coordenadas'] as List<LatLng>;
      }

      // Si tenemos al menos 2 puntos, llamamos al cerebro
      if (puntosParaCalculo.length >= 2) {
        print('🧠 [RutasVM] Calculando ruta con OSRM...');
        try {
          final resultadoOsrm = await _osrmService.getRutaCompleta(puntosParaCalculo);

          // AGREGAR RESULTADOS AL MAPA PARA SUPABASE
          final List<LatLng> geometria = resultadoOsrm['points'];
          final List<List<double>> geometriaJson = geometria.map((p) => [p.latitude, p.longitude]).toList();

          datosRuta['geometria_json'] = geometriaJson;
          datosRuta['distancia_metros'] = resultadoOsrm['distance'];
          datosRuta['duracion_segundos'] = resultadoOsrm['duration'];

          print('✅ [RutasVM] OSRM terminó. Distancia: ${resultadoOsrm['distance']}m');
        } catch (e) {
          print('⚠️ [RutasVM] Falló OSRM, guardando sin ruta: $e');
          // No relanzamos, permitimos guardar la ruta aunque falle el cálculo geométrico
        }
      } else {
        print('⚠️ [RutasVM] No hay suficientes puntos para calcular ruta.');
      }
  }

  // --- (Resto de métodos CRUD iguales) ---

  Future<void> actualizarRuta(
      String rutaId,
      Map<String, dynamic> datosRuta,
      ) async {
    _estaCargandoAccion = true;
    _error = null;
    notifyListeners();
    try {
      // 1. RECALCULAR GEOMETRÍA OSRM SI HAY CAMBIOS DE PUNTOS
      // (Misma lógica que al crear, para que el mapa se actualice)
      await _calcularGeometriaOSRM(datosRuta);

      await _repositorio.actualizarRuta(rutaId, datosRuta);
      _estaCargandoAccion = false;
      notifyListeners();
      
      // Actualizar todo por si acaso
      await _cargarListaEspecifica('Creadas por mí');
      await _cargarListaEspecifica('Recomendadas');
      if (_pestanaActual == 'Mis Inscripciones') await _cargarListaEspecifica('Mis Inscripciones');

    } catch (e) {
      _estaCargandoAccion = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }


  Future<void> eliminarRuta(String rutaId) async {
    _estaCargandoAccion = true;
    _error = null;
    notifyListeners();
    try {
      await _repositorio.eliminarRuta(rutaId);
      _estaCargandoAccion = false;
      notifyListeners();
      
      // Limpiar de las listas
      await _cargarListaEspecifica('Creadas por mí');
      await _cargarListaEspecifica('Recomendadas');

    } catch (e) {
      _estaCargandoAccion = false;
      _error = e.toString();
      notifyListeners();
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  Future<void> marcarAsistencia(String rutaId) async {
    _estaCargandoAccion = true;
    notifyListeners();
    try {
      await _repositorio.marcarAsistencia(rutaId);
      await cargarRutas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _estaCargandoAccion = false;
      notifyListeners();
    }
  }

  Future<void> cambiarEstadoRuta(String rutaId, String nuevoEstado) async {
    _estaCargandoAccion = true;
    notifyListeners();
    try {
      await _repositorio.cambiarEstadoRuta(rutaId, nuevoEstado);
      await cargarRutas();
    } catch (e) {
      _error = e.toString();
    } finally {
      _estaCargandoAccion = false;
      notifyListeners();
    }
  }

  // --- MÓDULO PARTICIPANTES ---
  Future<void> cargarParticipantes(String rutaId) async {
    _cargandoParticipantes = true;
    notifyListeners();
    try {
      _participantes = await _repositorio.obtenerParticipantes(rutaId);
    } catch (e) {
      debugPrint('Error cargando participantes: $e');
    } finally {
      _cargandoParticipantes = false;
      notifyListeners();
    }
  }

  Future<void> togglePrivacidad(String rutaId, bool mostrarNombreReal) async {
    try {
      final index = _participantes.indexWhere((p) => p.soyYo);
      if (index != -1) {
        final p = _participantes[index];
        // Optimista: Actualizamos localmente
        _participantes[index] = ParticipanteRuta(
            usuarioId: p.usuarioId,
            seudonimo: p.seudonimo,
            nombres: p.nombres,
            apellidoPaterno: p.apellidoPaterno,
            apellidoMaterno: p.apellidoMaterno,
            dni: p.dni,
            urlFotoPerfil: p.urlFotoPerfil,
            mostrarNombreReal: mostrarNombreReal, 
            asistio: p.asistio,
            soyYo: true
        );
        notifyListeners();
      }
      await _repositorio.cambiarPrivacidad(rutaId, mostrarNombreReal);
    } catch (e) {
      debugPrint('Error toggle privacidad: $e');
      await cargarParticipantes(rutaId);
    }
  }

  // --- MÓDULO HISTORIAL ---
  Future<void> cargarHistorial() async {
    final userId = _authVM?.usuarioActual?.id;
    if (userId == null) return;
    
    _cargandoHistorial = true;
    notifyListeners();
    
    try {
      _historialRutas = await _repositorio.obtenerHistorial(userId);
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      _cargandoHistorial = false;
      notifyListeners();
      notifyListeners();
    }
  }

  // --- MÓDULO CATEGORÍAS ---
  Future<void> cargarCategorias() async {
    if (_categoriasDisponibles.isNotEmpty) return;
    try {
      _categoriasDisponibles = await _repositorio.obtenerCategorias();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories in VM: $e');
    }
  }
}

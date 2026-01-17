import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xplore_cusco/core/servicios/imagen_servicio.dart';

// Entidades
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/provincia.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';

class CrearHakuparadaVM extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagenServicio _imagenServicio = ImagenServicio();

  // --- ESTADO DEL FORMULARIO ---
  bool _estaCargando = false;
  String? _error;
  
  // Ubicación
  LatLng? _ubicacionSeleccionada;
  String _direccionDetectada = "Toca el mapa para ubicar";
  
  // Listas para los Dropdowns
  List<Provincia> _provincias = [];
  List<Lugar> _lugaresFiltrados = [];
  
  // Selecciones del Usuario
  Provincia? _provinciaSeleccionada;
  Lugar? _lugarSeleccionado; // Puede ser null ("Ninguno")
  String _categoriaSeleccionada = 'Mirador'; // Valor por defecto
  
  // Textos
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  
  // Foto
  File? _fotoSeleccionada;

  // --- GETTERS ---
  bool get estaCargando => _estaCargando;
  String? get error => _error;
  LatLng? get ubicacionSeleccionada => _ubicacionSeleccionada;
  String get direccionDetectada => _direccionDetectada;
  
  List<Provincia> get provincias => _provincias;
  List<Lugar> get lugaresFiltrados => _lugaresFiltrados;
  
  Provincia? get provinciaSeleccionada => _provinciaSeleccionada;
  Lugar? get lugarSeleccionado => _lugarSeleccionado;
  String get categoriaSeleccionada => _categoriaSeleccionada;
  
  File? get fotoSeleccionada => _fotoSeleccionada;

  // Constructor
  CrearHakuparadaVM() {
    _cargarProvincias();
  }

  // --- 1. CARGA INICIAL ---
  Future<void> _cargarProvincias() async {
    try {
      final response = await _supabase
          .from('provincias')
          .select()
          .order('nombre', ascending: true);
          
      final data = response as List<dynamic>;
      
      // MAPEO MANUAL (Porque Provincia no tiene fromJson)
      // Ajuste: DB id es Int, Entity id es String.
      _provincias = data.map((json) {
        return Provincia(
          id: json['id'].toString(), // Int -> String
          nombre: json['nombre'] ?? 'Sin nombre',
          urlImagen: json['url_imagen'] ?? '',
          // Valores Mock/Default porque la query simple no trae esto
          placesCount: 0, 
          categories: const <String>[],
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _error = "Error cargando provincias: $e";
      notifyListeners();
    }
  }

  // --- 2. LÓGICA DE UBICACIÓN Y GEOCODING ---
  Future<void> seleccionarUbicacion(LatLng punto) async {
    _ubicacionSeleccionada = punto;
    _direccionDetectada = "Buscando dirección...";
    notifyListeners();

    try {
      // Geocoding Inverso: LatLng -> "Urubamba, Cusco"
      List<Placemark> placemarks = await placemarkFromCoordinates(
        punto.latitude, 
        punto.longitude
      );

      if (placemarks.isNotEmpty) {
        final lugar = placemarks.first;
        // Intentamos armar una dirección legible
        _direccionDetectada = "${lugar.locality ?? ''}, ${lugar.subAdministrativeArea ?? ''}";
        
        // ¡LA MAGIA! Intentar adivinar la provincia
        _intentarAutoSeleccionarProvincia(lugar.subAdministrativeArea, lugar.locality);
      } else {
        _direccionDetectada = "Ubicación desconocida";
      }
    } catch (e) {
      _direccionDetectada = "Sin conexión para detectar nombre";
      // No mostramos error bloqueante, dejamos que el usuario seleccione provincia manual
    }
    
    notifyListeners();
  }

  void _intentarAutoSeleccionarProvincia(String? area, String? localidad) {
    if (area == null && localidad == null) return;
    
    final textoBusqueda = (area ?? "") + (localidad ?? "");
    final textoNormalizado = textoBusqueda.toLowerCase();

    try {
      // Buscamos si alguna provincia nuestra está en el texto del GPS
      final coincidencia = _provincias.firstWhere(
        (p) => textoNormalizado.contains(p.nombre.toLowerCase()),
      );
      
      // Si encontramos coincidencia, la seleccionamos automáticamente
      seleccionarProvincia(coincidencia);
      
    } catch (e) {
      // No hubo coincidencia, no pasa nada, el usuario lo hará manual
    }
  }

  Future<void> usarMiUbicacion() async {
    _estaCargando = true;
    notifyListeners();
    
    try {
      final position = await Geolocator.getCurrentPosition();
      await seleccionarUbicacion(LatLng(position.latitude, position.longitude));
    } catch (e) {
      _error = "No pudimos obtener tu ubicación GPS";
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  // --- BUSQUEDA POR COORDENADAS ---
  Future<void> buscarPorCoordenadas(String input) async {
    // Input esperado: "-13.5, -71.9"
    final partes = input.split(',');
    if (partes.length != 2) {
      _error = "Formato inválido. Usa: Latitud, Longitud";
      notifyListeners();
      return;
    }

    try {
      final lat = double.parse(partes[0].trim());
      final lng = double.parse(partes[1].trim());
      
      // Validar rangos básicos de lat/lng
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        _error = "Coordenadas fuera de rango";
        notifyListeners();
        return;
      }

      await seleccionarUbicacion(LatLng(lat, lng));
      
    } catch (e) {
      _error = "No pudimos leer las coordenadas. Asegúrate que sean números.";
      notifyListeners();
    }
  }

  // --- 3. LÓGICA DE CASCADA (Provincia -> Lugares) ---
  void seleccionarProvincia(Provincia? provincia) {
    _provinciaSeleccionada = provincia;
    _lugarSeleccionado = null; // Reiniciar hijo
    _lugaresFiltrados = [];
    
    if (provincia != null) {
      _cargarLugaresDeProvincia(provincia);
    }
    
    notifyListeners();
  }
  
  Future<void> _cargarLugaresDeProvincia(Provincia provincia) async {
    _estaCargando = true;
    notifyListeners();
    
    try {
      // Convertir String ID -> Int ID para la BD
      final provinciaIdInt = int.tryParse(provincia.id) ?? 0;

      final response = await _supabase
          .from('lugares')
          .select()
          .eq('provincia_id', provinciaIdInt);
          
      final data = response as List<dynamic>;
      
      // MAPEO MANUAL (Porque Lugar no tiene fromJson)
      _lugaresFiltrados = data.map((json) {
        return Lugar(
          id: json['id'].toString(), // Int -> String
          nombre: json['nombre'] ?? 'Sin nombre',
          descripcion: json['descripcion'] ?? '',
          urlImagen: json['url_imagen'] ?? '',
          rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
          provinciaId: json['provincia_id']?.toString() ?? '0',
          usuarioId: json['registrado_por'] ?? '',
          // Valores opcionales
          reviewsCount: json['reviews_count'] ?? 0,
          horario: json['horario'] ?? 'No disponible',
          latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
          longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
          videoTiktokUrl: json['video_tiktok_url'],
          // Default mandatory
          puntosInteres: const <String>[],
        );
      }).toList();
      
    } catch (e) {
      debugPrint("Error cargando lugares cascada: $e");
    } finally {
      _estaCargando = false;
      notifyListeners();
    }
  }

  void seleccionarLugar(Lugar? lugar) {
    _lugarSeleccionado = lugar;
    notifyListeners();
  }

  void seleccionarCategoria(String categoria) {
    _categoriaSeleccionada = categoria;
    notifyListeners();
  }

  // --- 4. FOTO ---
  void setFoto(File foto) {
    _fotoSeleccionada = foto;
    notifyListeners();
  }

  void limpiarFoto() {
    _fotoSeleccionada = null;
    notifyListeners();
  }

  // --- 5. GUARDADO FINAL ---
  Future<bool> guardarHakuparada() async {
    // Validaciones
    if (_ubicacionSeleccionada == null) {
      _error = "Por favor selecciona una ubicación en el mapa";
      notifyListeners();
      return false;
    }
    if (_provinciaSeleccionada == null) {
      _error = "La provincia es obligatoria";
      notifyListeners();
      return false;
    }
    if (nombreController.text.isEmpty) {
      _error = "Dale un nombre a tu parada";
      notifyListeners();
      return false;
    }
    if (descripcionController.text.isEmpty) {
      _error = "Añade una descripción para ayudar a otros viajeros";
      notifyListeners();
      return false;
    }
    if (_fotoSeleccionada == null) {
      _error = "La foto es obligatoria";
      notifyListeners();
      return false;
    }

    _estaCargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Subir Foto (VÍA N8N -> S3)
      final fotoComprimida = await _imagenServicio.comprimirImagen(_fotoSeleccionada!);
      
      // Especificamos la carpeta 'hakuparadas'
      final fotoUrl = await _imagenServicio.subirImagen(fotoComprimida, 'hakuparadas');

      if (fotoUrl == null) {
        throw Exception("No se pudo subir la imagen al servidor");
      }

      // 2. Insertar en BD
      final usuarioId = _supabase.auth.currentUser?.id;
      
      // Parsear IDs inversamente (String -> Int)
      final provIdInt = int.tryParse(_provinciaSeleccionada!.id) ?? 0;
      final lugarIdInt = _lugarSeleccionado != null ? int.tryParse(_lugarSeleccionado!.id) : null;

      await _supabase.from('hakuparadas').insert({
        'nombre': nombreController.text,
        'descripcion': descripcionController.text,
        'foto_referencia': fotoUrl,
        'latitud': _ubicacionSeleccionada!.latitude,
        'longitud': _ubicacionSeleccionada!.longitude,
        'categoria': _categoriaSeleccionada,
        'provincia_id': provIdInt,
        'lugar_id': lugarIdInt,
        'publicado_por': usuarioId,
        'verificado': false, // Seguridad
        'visible': true,     // Visible pero no verificado
      });

      _estaCargando = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = "Error al guardar: $e";
      _estaCargando = false;
      notifyListeners();
      return false;
    }
  }
}

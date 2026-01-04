// --- CARACTERISTICAS/RUTAS/DATOS/SERVICIOS/OSRM_SERVICE.DART ---
// Este es el "Calculadora de Rutas".
// Conecta tu App con la API pública de OSRM.

import 'dart:convert';
import 'package:http/http.dart' as http; // Necesitas el paquete 'http'
import 'package:latlong2/latlong.dart';

class OsrmService {
  // Usamos el servidor público de OSRM (Gratis)
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Recibe una lista de puntos (Inicio -> Parada 1 -> Parada 2 -> Fin)
  /// Devuelve un Mapa con 3 cosas:
  /// 1. 'points': La lista de puntos para dibujar la línea (List<LatLng>)
  /// 2. 'distance': La distancia total en metros (double)
  /// 3. 'duration': El tiempo total en segundos (double)
  Future<Map<String, dynamic>> getRutaCompleta(List<LatLng> lugares) async {
    if (lugares.length < 2) {
      // Si hay menos de 2 lugares, no hay ruta posible.
      return {
        'points': <LatLng>[],
        'distance': 0.0,
        'duration': 0.0,
      };
    }

    // 1. CONSTRUIR LA URL
    // OSRM pide las coordenadas así: "longitud,latitud" separadas por ";"
    // Ejemplo: -71.97,-13.51;-71.98,-13.52
    final coordenadasString = lugares.map((p) => '${p.longitude},${p.latitude}').join(';');

    // overview=full: Queremos la línea detallada con todas las curvas
    // geometries=geojson: Formato estándar fácil de leer
    final String url = '$_baseUrl/$coordenadasString?overview=full&geometries=geojson';

    print('🔍 [OSRM] Consultando ruta: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // OSRM devuelve varias rutas alternativas, tomamos la primera (la mejor)
        final List<dynamic> routes = data['routes'];
        if (routes.isEmpty) return {};

        final route = routes[0];

        // 2. EXTRAER DATOS TÉCNICOS
        final double distancia = (route['distance'] as num).toDouble();
        final double duracion = (route['duration'] as num).toDouble();

        // 3. EXTRAER LA GEOMETRÍA (EL DIBUJO)
        final geometry = route['geometry'];
        final List<dynamic> rawCoordinates = geometry['coordinates'];

        // Convertimos los datos crudos [long, lat] a LatLng(lat, long) para Flutter
        final List<LatLng> puntosMapa = rawCoordinates.map((coord) {
          return LatLng(
            (coord[1] as num).toDouble(), // Latitud va primero en Flutter
            (coord[0] as num).toDouble(), // Longitud va segundo
          );
        }).toList();

        print('✅ [OSRM] Ruta calculada: ${distancia.toStringAsFixed(1)}m, ${puntosMapa.length} puntos');

        return {
          'points': puntosMapa,
          'distance': distancia,
          'duration': duracion,
        };
      } else {
        print('❌ [OSRM] Error HTTP: ${response.statusCode}');
        throw Exception('Error al conectar con OSRM');
      }
    } catch (e) {
      print('❌ [OSRM] Error interno: $e');
      // En caso de error, devolvemos datos vacíos para no romper la app
      return {
        'points': <LatLng>[],
        'distance': 0.0,
        'duration': 0.0,
      };
    }
  }
}
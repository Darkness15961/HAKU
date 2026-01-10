import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../mapa/presentacion/widgets/cached_tile_provider.dart';

class MapaRutaPreview extends StatelessWidget {
  final List<LatLng> polilinea;
  final List<LatLng> waypoints; // <--- NUEVO: Puntos de parada
  final double distanciaMetros;
  final double duracionSegundos;

  const MapaRutaPreview({
    super.key,
    required this.polilinea,
    this.waypoints = const [], // <--- Opcional pero recomendado
    required this.distanciaMetros,
    required this.duracionSegundos,
  });

  @override
  Widget build(BuildContext context) {
    if (polilinea.isEmpty) {
      return const SizedBox.shrink();
    }

    final bounds = LatLngBounds.fromPoints(polilinea);
    final centerLat = (bounds.north + bounds.south) / 2;
    final centerLng = (bounds.east + bounds.west) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
           padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text('🗺️ Mapa del Recorrido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.blue.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.directions_walk, size: 16, color: Colors.blue),
                     const SizedBox(width: 4),
                     Text(_formatDistance(distanciaMetros), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                   ],
                 ),
               ),
             ],
           ),
         ),
        Container(
          height: 300, // Un poco más alto para mejor vista
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLng),
                    initialCameraFit: CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(50), // Más padding para que quepan los marcadores
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                     TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.xplorecusco.app',
                      tileProvider: CachedTileProvider(),
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polilinea,
                          strokeWidth: 5.0,
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        Polyline(
                          points: polilinea,
                          strokeWidth: 4.0,
                          color: const Color(0xFF3F51B5),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Marcadores Intermedios (Pequeños puntos azules)
                        if (waypoints.length > 2)
                          ...waypoints.sublist(1, waypoints.length - 1).map((point) => Marker(
                            point: point,
                            width: 12,
                            height: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF3F51B5), width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                              ),
                            ),
                          )),

                        // Inicio (Verde grande)
                        if (waypoints.isNotEmpty)
                          Marker(
                            point: waypoints.first,
                            width: 30,
                            height: 30,
                            child: _buildMarker(Icons.play_circle_fill, Colors.green),
                          ),
                        
                        // Fin (Rojo grande)
                         if (waypoints.isNotEmpty)
                          Marker(
                            point: waypoints.last,
                            width: 30,
                            height: 30,
                            child: _buildMarker(Icons.flag_circle, Colors.red),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _buildMetricChip(Icons.timer_outlined, _formatDuration(duracionSegundos)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMarker(IconData icon, Color color) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildMetricChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDuration(double seconds) {
    final int totalMinutes = (seconds / 60).round();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }
}

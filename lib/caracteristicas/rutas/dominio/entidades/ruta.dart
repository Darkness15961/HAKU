// --- CARACTERISTICAS/RUTAS/DOMINIO/ENTIDADES/RUTA.DART ---
// Versión: CON SOPORTE OSRM (Geometría, Distancia, Tiempo)

import 'package:latlong2/latlong.dart'; // <--- NECESITAS ESTO


class Ruta {
  final String id;
  final String nombre;
  final String descripcion;
  final String urlImagenPrincipal;
  final double precio;
  final String categoria;
  final int cuposTotales;
  final int cuposDisponibles;
  final bool visible;
  final int dias;

  // --- NUEVOS CAMPOS OSRM (Backend) ---
  final List<LatLng> polilinea; // El dibujo de la carretera
  final double distanciaMetros; // Ej: 15400.0 (15.4 km)
  final double duracionSegundos; // Ej: 3600.0 (1 hora)

  // --- CAMPOS FASE 2/3/4 ---
  final String estado;
  final List<String> equipamiento;
  final DateTime? fechaCierre;
  final DateTime? fechaEvento;
  final String? puntoEncuentro;
  final bool esPrivada;
  final String? codigoAcceso;

  // Campos Calculados
  final String guiaId;
  final String guiaNombre;
  final String guiaFotoUrl;
  final double guiaRating;
  final double rating;
  final int reviewsCount;
  final int inscritosCount;
  final List<String> lugaresIncluidos;
  final List<String> lugaresIncluidosIds;
  final String? enlaceWhatsapp;
  final bool esFavorita;
  final bool estaInscrito;
  final bool asistio;
  final String? guiaNombreReal; // Nuevo: Nombre real concatenado (Nombres + Apellidos)
  final bool guiaDniValidado;   // Nuevo: Si tiene check azul de Reniec
  final List<LatLng> lugaresIncluidosCoords; // Nuevo: Coordenadas de los puntos de visita

  Ruta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlImagenPrincipal,
    required this.precio,
    required this.categoria,
    required this.cuposTotales,
    required this.cuposDisponibles,
    required this.visible,
    required this.dias,

    // Inicializamos OSRM
    this.polilinea = const [],
    this.distanciaMetros = 0,
    this.duracionSegundos = 0,

    this.estado = 'convocatoria',
    this.equipamiento = const [],
    this.fechaCierre,
    this.fechaEvento,
    this.puntoEncuentro,
    this.esPrivada = false,
    this.codigoAcceso,
    this.asistio = false,
    required this.guiaId,
    required this.guiaNombre,
    required this.guiaFotoUrl,
    required this.guiaRating,
    required this.rating,
    required this.reviewsCount,
    required this.lugaresIncluidos,
    required this.lugaresIncluidosIds,
    this.enlaceWhatsapp,
    required this.inscritosCount,
    required this.esFavorita,
    required this.estaInscrito,
    this.guiaNombreReal,
    this.guiaDniValidado = false,
    this.lugaresIncluidosCoords = const [],
  });
  
  Ruta copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? urlImagenPrincipal,
    double? precio,
    String? categoria,
    int? cuposTotales,
    int? cuposDisponibles,
    bool? visible,
    int? dias,
    double? distanciaMetros,
    double? duracionSegundos,
    String? estado,
    List<String>? equipamiento,
    DateTime? fechaCierre,
    DateTime? fechaEvento,
    String? puntoEncuentro,
    bool? esPrivada,
    String? codigoAcceso,
    bool? asistio,
    String? guiaId,
    String? guiaNombre,
    String? guiaFotoUrl,
    double? guiaRating,
    double? rating,
    int? reviewsCount,
    List<String>? lugaresIncluidos,
    List<String>? lugaresIncluidosIds,
    List<LatLng>? polilinea,
    String? enlaceWhatsapp,
    int? inscritosCount,
    bool? esFavorita,
    bool? estaInscrito,
    String? guiaNombreReal,
    bool? guiaDniValidado,
    List<LatLng>? lugaresIncluidosCoords,
  }) {
    return Ruta(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      urlImagenPrincipal: urlImagenPrincipal ?? this.urlImagenPrincipal,
      precio: precio ?? this.precio,
      categoria: categoria ?? this.categoria,
      cuposTotales: cuposTotales ?? this.cuposTotales,
      cuposDisponibles: cuposDisponibles ?? this.cuposDisponibles,
      visible: visible ?? this.visible,
      dias: dias ?? this.dias,
      distanciaMetros: distanciaMetros ?? this.distanciaMetros,
      duracionSegundos: duracionSegundos ?? this.duracionSegundos,
      estado: estado ?? this.estado,
      equipamiento: equipamiento ?? this.equipamiento,
      fechaCierre: fechaCierre ?? this.fechaCierre,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      puntoEncuentro: puntoEncuentro ?? this.puntoEncuentro,
      esPrivada: esPrivada ?? this.esPrivada,
      codigoAcceso: codigoAcceso ?? this.codigoAcceso,
      asistio: asistio ?? this.asistio,
      guiaId: guiaId ?? this.guiaId,
      guiaNombre: guiaNombre ?? this.guiaNombre,
      guiaFotoUrl: guiaFotoUrl ?? this.guiaFotoUrl,
      guiaRating: guiaRating ?? this.guiaRating,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      lugaresIncluidos: lugaresIncluidos ?? this.lugaresIncluidos,
      lugaresIncluidosIds: lugaresIncluidosIds ?? this.lugaresIncluidosIds,
      polilinea: polilinea ?? this.polilinea,
      enlaceWhatsapp: enlaceWhatsapp ?? this.enlaceWhatsapp,
      inscritosCount: inscritosCount ?? this.inscritosCount,
      esFavorita: esFavorita ?? this.esFavorita,
      estaInscrito: estaInscrito ?? this.estaInscrito,
      guiaNombreReal: guiaNombreReal ?? this.guiaNombreReal,
      guiaDniValidado: guiaDniValidado ?? this.guiaDniValidado,
      lugaresIncluidosCoords: lugaresIncluidosCoords ?? this.lugaresIncluidosCoords,
    );
  }
}
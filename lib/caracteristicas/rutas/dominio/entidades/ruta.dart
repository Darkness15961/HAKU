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
  });
}
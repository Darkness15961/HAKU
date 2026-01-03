import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // Usamos el generador de URLs nativo de flutter_map
    final url = getTileUrl(coordinates, options);

    // Y devolvemos la imagen usando el sistema de caché
    return CachedNetworkImageProvider(url);
  }
}
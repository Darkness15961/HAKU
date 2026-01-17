import 'package:flutter/material.dart';
import '../../dominio/entidades/ruta.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RutaCardElegante extends StatelessWidget {
  final Ruta ruta;
  final VoidCallback onTap;

  const RutaCardElegante({
    super.key,
    required this.ruta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // 1. Imagen de Fondo (Hero image)
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: CachedNetworkImage(
                    imageUrl: ruta.urlImagenPrincipal,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Gradiente para mejorar legibilidad de texto superpuesto (si lo hubiera)
                // y para darle profundidad
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Badges Superiores
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildStatusBadge(ruta),
                ),

                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildCategoryBadge(ruta),
                ),
                
                // 3. PRECIO (Nuevo elemento crítico)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      ruta.precio == 0 ? 'GRATIS' : 'S/ ${ruta.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 4. Contenido de Texto (Layout tipo Screenshot)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO
                  Text(
                    ruta.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold, // Negrita fuerte como en la imagen
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // USUARIO (Avatar + Nombre + Rating)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: (ruta.guiaFotoUrl.isNotEmpty)
                            ? NetworkImage(ruta.guiaFotoUrl)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: (ruta.guiaFotoUrl.isEmpty)
                            ? Text(
                                ruta.guiaNombre.isNotEmpty ? ruta.guiaNombre[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ruta.guiaNombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87, // Texto oscuro y legible
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Rating a la derecha
                      Icon(Icons.star_rounded, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        ruta.guiaRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // FECHA (Color Teal, como en imagen)
                  if (ruta.fechaEvento != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF009688)), // Teal
                          const SizedBox(width: 8),
                          Text(
                            '${_formatFecha(ruta.fechaEvento!)} • ${_formatHora(ruta.fechaEvento!)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF00796B), // Teal oscuro
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // LUGAR (Color Naranja/Amarillo, como en imagen)
                  if (ruta.puntoEncuentro != null)
                     Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Color(0xFFFFA000)), // Amber
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ruta.puntoEncuentro!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // FOOTER: Cupos y Destinos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Row(
                        children: [
                          Icon(Icons.group_outlined, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '${ruta.cuposTotales - ruta.inscritosCount} cupos disp.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            '${ruta.lugaresIncluidos.length} Destinos',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildStatusBadge(Ruta ruta) {
    if (!ruta.esPrivada && ruta.visible) return const SizedBox.shrink();

    final color = ruta.esPrivada ? const Color(0xFF673AB7) : Colors.amber[800];
    final text = ruta.esPrivada ? 'PRIVADA' : 'BORRADOR';
    
    // Badge Gris Oscuro con texto blanco (estilo captura superior derecha)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(Ruta ruta) {
    final color = _getColorCategoria(ruta.categoria);

    // Diseño EXACTO imagen: Fondo oscuro, Borde color, Icono gráfico, Texto
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8), // Bordes menos redondeados (como la imagen)
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, color: color, size: 16), // Icono gráfico barras
          const SizedBox(width: 8),
          Text(
            ruta.categoria.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'familiar': return const Color(0xFF4CAF50); // Verde
      case 'cultural': return const Color(0xFF3F51B5); // Indigo
      case 'aventura': return const Color(0xFFFF9800); // Naranja
      case 'naturaleza': return const Color(0xFF2E7D32); // Verde
      case 'extrema': return const Color(0xFFD32F2F); // Rojo
      default: return Colors.blueGrey;
    }
  }

  String _formatFecha(DateTime fecha) {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${fecha.day} ${meses[fecha.month - 1]}, ${fecha.year}';
  }

  String _formatHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../inicio/dominio/entidades/lugar.dart';

class TarjetaPolaroid extends StatelessWidget {
  final Lugar lugar;
  final VoidCallback onCerrar;

  const TarjetaPolaroid({
    super.key,
    required this.lugar,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -0.02,
        child: SizedBox(
          width: 280, // Limitamos el ancho para que parezca una foto real
          child: Stack(
            clipBehavior: Clip.none, // Para que el botón X pueda salir del borde
            children: [
              // --- EL CUERPO DE LA POLAROID ---
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                constraints: const BoxConstraints(maxHeight: 400), // Constraint de seguridad máximo
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2), // Bordes casi rectos como papel
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: SingleChildScrollView(
                  // Scroll si no cabe en vertical (Landscape)
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. FOTO (Con Animación Hero)
                      // Usamos AspectRatio 4/3 o 1/1 para efecto Polaroid real
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Hero(
                          tag: lugar.id, // ¡Magia! Conecta esta foto con la del detalle
                          child: Container(
                            color: Colors.grey[100],
                            child: Image.network(
                              lugar.urlImagen,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
  
                      // 2. TEXTO MANUSCRITO
                      Text(
                        lugar.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cursive', // Intenta usar fuente manual del sistema
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
  
                      const SizedBox(height: 8),
  
                      // 3. RATING Y CATEGORÍA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(" ${lugar.rating} ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800])),
                          Text("• ${lugar.reviewsCount} opiniones",
                              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
  
                      const SizedBox(height: 16),
  
                      // 4. BOTÓN VER DETALLES (Estilo Minimalista)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            context.push('/inicio/detalle-lugar', extra: lugar);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("VER DETALLES",
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // --- BOTÓN CERRAR (Más elegante) ---
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: onCerrar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.black, // Negro es más elegante que rojo para cerrar
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 5
                          )
                        ],
                        border: Border.all(color: Colors.white, width: 2)
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
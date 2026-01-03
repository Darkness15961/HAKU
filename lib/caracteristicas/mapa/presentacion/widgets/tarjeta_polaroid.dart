import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../inicio/dominio/entidades/lugar.dart';

class TarjetaPolaroid extends StatelessWidget {
  final Lugar lugar;
  final VoidCallback onCerrar; // Recibimos la acción de cerrar desde el padre

  const TarjetaPolaroid({
    super.key,
    required this.lugar,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -0.02, // Misma inclinación que tenías
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. FOTO
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.grey[200],
                      child: Image.network(
                        lugar.urlImagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. TEXTO
                  Text(
                    lugar.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontStyle: FontStyle.italic,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("★ ${lugar.rating}",
                      style: TextStyle(color: Colors.grey[600])),

                  const SizedBox(height: 12),

                  // 3. BOTÓN VER DETALLES
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/inicio/detalle-lugar', extra: lugar);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Ver Detalles"),
                    ),
                  )
                ],
              ),
            ),

            // Botón X para cerrar
            Positioned(
              top: -10,
              right: -10,
              child: GestureDetector(
                onTap: onCerrar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
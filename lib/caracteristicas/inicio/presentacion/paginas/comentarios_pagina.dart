// --- PIEDRA 7.2: EL "MENÚ" DE LISTA DE COMENTARIOS ---
//
// Esta es la pantalla que se abre cuando el usuario
// presiona "Ver todas las X reseñas".
//
// Su único trabajo es "escuchar" al "Mesero" (LugaresVM)
// y mostrar la LISTA COMPLETA de comentarios.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- MVVM: IMPORTACIONES ---
// 1. Importamos el "Mesero" (ViewModel)
import '../vista_modelos/lugares_vm.dart';
// 2. Importamos la "Receta" (Entidad)
import '../../dominio/entidades/comentario.dart';

// 1. El "Edificio" (La Pantalla)
//    (Es un StatelessWidget porque no "recuerda" nada.
//    Toda la lógica y los datos están en el "Mesero" VM).
class ComentariosPagina extends StatelessWidget {
  const ComentariosPagina({super.key});

  @override
  Widget build(BuildContext context) {
    // --- MVVM: Conexión principal con el "Mesero" ---
    //
    // "Escuchamos" (watch) al "Mesero" de Lugares (LugaresVM).
    // Esta pantalla NO necesita cargar nada, porque los
    // comentarios YA se cargaron en la pantalla de detalle.
    // ¡Simplemente leemos la lista que el "Mesero" ya tiene!
    final vm = context.watch<LugaresVM>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Todas las Reseñas (${vm.comentarios.length})'),
      ),
      // Usamos un ListView.builder para mostrar la lista
      // completa de comentarios que "leemos" del "Mesero"
      body: ListView.builder(
        // Usamos el conteo de la lista del "Mesero"
        itemCount: vm.comentarios.length,
        itemBuilder: (context, index) {
          // Obtenemos la "Receta" Comentario del "Mesero"
          final comentario = vm.comentarios[index];
          // Reutilizamos el mismo widget de "tarjeta de comentario"
          // que ya diseñamos en "detalle_lugar_pagina.dart".
          return _buildComentarioCard(comentario);
        },
      ),
    );
  }

  // --- Widget de Tarjeta de Comentario (Copiado de detalle_lugar_pagina.dart) ---
  //
  // (Idealmente, para no repetir código, moveríamos este
  // widget a su propio archivo en:
  // "lib/caracteristicas/inicio/presentacion/widgets/tarjeta_comentario.dart"
  // ...pero por ahora, copiarlo aquí funciona perfecto
  // para arreglar el error).
  //
  Widget _buildComentarioCard(Comentario comentario) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Foto (de la "Receta")
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(comentario.usuarioFotoUrl),
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 12),
                  // Nombre y Fecha (de la "Receta")
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comentario.usuarioNombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(comentario.fecha,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Rating (de la "Receta")
                  Row(
                    children: [
                      Icon(Icons.star,
                          color: Colors.amber.shade600, size: 16),
                      const SizedBox(width: 4),
                      Text(comentario.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Texto (de la "Receta")
              Text(
                comentario.texto,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


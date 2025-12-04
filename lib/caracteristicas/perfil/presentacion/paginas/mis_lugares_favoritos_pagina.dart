// --- PIEDRA 8 (PERFIL): LA "NUEVA VENTANA" DE MIS FAVORITOS ---
//
// 1. (BUG NAVEGACIÓN CORREGIDO): Se corrigió la ruta 'onTap'
//    para que apunte a la ruta completa '/inicio/detalle-lugar'.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../../../inicio/presentacion/vista_modelos/lugares_vm.dart';
import '../../../inicio/dominio/entidades/lugar.dart';

class MisLugaresFavoritosPagina extends StatelessWidget {
  const MisLugaresFavoritosPagina({super.key});

  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final List<Lugar> misFavoritos = vmLugares.misLugaresFavoritos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Lugares Favoritos'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: misFavoritos.isEmpty
          ? Center(
        // ... (código del mensaje 'No tienes favoritos' intacto) ...
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'No tienes favoritos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toca el corazón (❤️) en un lugar del Menú 1 (Inicio) para guardarlo aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: misFavoritos.length,
        itemBuilder: (context, index) {
          final lugar = misFavoritos[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),

              // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                // Verificamos si la URL no está vacía Y si es una URL web
                child: (lugar.urlImagen.isNotEmpty && lugar.urlImagen.startsWith('http'))
                // CASO 1: SÍ HAY IMAGEN
                    ? Image.network(
                  lugar.urlImagen,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  // Fallback 1: Si la URL es válida pero falla (404, sin internet)
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
                // CASO 2: NO HAY IMAGEN (URL vacía o nula)
                    : _buildPlaceholderImage(),
              ),
              // --- FIN DE LA CORRECCIÓN ---

              title: Text(lugar.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(lugar.categoria, style: TextStyle(color: Colors.grey[600])),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // --- ¡CORREGIDO! ---
                // Esta ruta es hija de '/inicio'
                context.push('/inicio/detalle-lugar', extra: lugar);
                // --- FIN DE LA CORRECCIÓN ---
              },
            ),
          );
        },
      ),
    );
  }

  // --- Widget Auxiliar para la imagen por defecto ---
  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[200],
      child: Icon(Icons.place_outlined, color: Colors.grey[400], size: 30),
    );
  }
}
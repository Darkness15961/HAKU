// --- PIEDRA 8 (PERFIL): LA "NUEVA VENTANA" DE MIS RUTAS ---
//
// Esta es la página del Paso 3. Es una página simple
// de "solo lectura" que muestra la lista de rutas inscritas.
//
// --- ¡CORREGIDO! ---
// Ahora comprueba si 'ruta.urlImagenPrincipal' está vacía
// y muestra un 'placeholder' (imagen por defecto) si lo está.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM: IMPORTACIONES ---
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';
import '../../../rutas/dominio/entidades/ruta.dart';

class MisRutasInscritasPagina extends StatelessWidget {
  const MisRutasInscritasPagina({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. "Escuchamos" (watch) al "Mesero de Rutas"
    final vmRutas = context.watch<RutasVM>();

    // 2. Leemos el getter que "acoplamos" en el Paso 2
    final List<Ruta> misInscritas = vmRutas.misRutasInscritas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutas Inscritas'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: misInscritas.isEmpty
      // 3. Si la lista está vacía, mostramos un mensaje
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'No tienes rutas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ve al Menú 2 (Rutas), entra al detalle de un tour y presiona "Registrarse" para añadirlo aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      )
      // 4. Si la lista SÍ tiene items, la mostramos
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: misInscritas.length,
        itemBuilder: (context, index) {
          final ruta = misInscritas[index];

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
                child: (ruta.urlImagenPrincipal.isNotEmpty && ruta.urlImagenPrincipal.startsWith('http'))
                // CASO 1: SÍ HAY IMAGEN
                    ? Image.network(
                  ruta.urlImagenPrincipal,
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

              title: Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Guía: ${ruta.guiaNombre}', style: TextStyle(color: Colors.grey[600])),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/detalle-ruta', extra: ruta);
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
      child: Icon(Icons.map_outlined, color: Colors.grey[400], size: 30),
    );
  }
}
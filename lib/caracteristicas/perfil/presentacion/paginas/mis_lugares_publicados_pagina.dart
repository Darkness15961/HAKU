import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xplore_cusco/caracteristicas/inicio/presentacion/vista_modelos/lugares_vm.dart';
import 'package:xplore_cusco/caracteristicas/autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import 'package:xplore_cusco/caracteristicas/inicio/dominio/entidades/lugar.dart';

class MisLugaresPublicadosPagina extends StatefulWidget {
  const MisLugaresPublicadosPagina({super.key});

  @override
  State<MisLugaresPublicadosPagina> createState() =>
      _MisLugaresPublicadosPaginaState();
}

class _MisLugaresPublicadosPaginaState
    extends State<MisLugaresPublicadosPagina> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final usuarioId = context.read<AutenticacionVM>().usuarioActual?.id;
      if (usuarioId != null) {
        context.read<LugaresVM>().cargarLugaresPorUsuario();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Lugares Publicados'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Reutilizamos la página de creación existente
          context.push('/admin/crear-lugar');
        },
        label: const Text('Publicar Nuevo'),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: vmLugares.estaCargandoGestion
          ? const Center(child: CircularProgressIndicator())
          : vmLugares.misLugaresPublicados.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no has publicado ningún lugar.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¡Comparte tus descubrimientos con el mundo!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vmLugares.misLugaresPublicados.length,
              itemBuilder: (context, index) {
                final lugar = vmLugares.misLugaresPublicados[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Al tocar, vamos al detalle (o podríamos ir a editar)
                      context.push('/inicio/detalle-lugar', extra: lugar);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            lugar.urlImagen,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lugar.nombre,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.comment,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Ver Reseñas',
                                onPressed: () {
                                  context.push(
                                    '/inicio/comentarios',
                                    extra: lugar,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.grey,
                                ),
                                tooltip: 'Editar Lugar',
                                onPressed: () {
                                  context.push(
                                    '/admin/crear-lugar',
                                    extra: lugar,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

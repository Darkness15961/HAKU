import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// --- MVVM: IMPORTACIONES ---
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../../rutas/presentacion/vista_modelos/rutas_vm.dart';
import '../../../rutas/dominio/entidades/ruta.dart';

class HistorialRutasPagina extends StatefulWidget {
  const HistorialRutasPagina({super.key});

  @override
  State<HistorialRutasPagina> createState() => _HistorialRutasPaginaState();
}

class _HistorialRutasPaginaState extends State<HistorialRutasPagina> {
  
  @override
  void initState() {
    super.initState();
    // Cargamos el historial al entrar
    Future.microtask(() => 
      context.read<RutasVM>().cargarHistorial()
    );
  }

  @override
  Widget build(BuildContext context) {
    final vmRutas = context.watch<RutasVM>();
    final vmAuth = context.watch<AutenticacionVM>();
    final myId = vmAuth.usuarioActual?.id;

    // Clasificamos las rutas localmente
    final todas = vmRutas.historialRutas;
    final guiadas = todas.where((r) => r.guiaId == myId).toList();
    final participadas = todas.where((r) => r.guiaId != myId).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Rutas'),
          backgroundColor: Colors.brown, // Color temático
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Como Guía'),
              Tab(text: 'Como Turista'),
            ],
          ),
        ),
        body: vmRutas.cargandoHistorial
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                   _buildLista(guiadas, myId, esGuiaTab: true),
                   _buildLista(participadas, myId, esGuiaTab: false),
                ],
              ),
      ),
    );
  }

  Widget _buildLista(List<Ruta> rutas, String? myId, {required bool esGuiaTab}) {
    if (rutas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
               esGuiaTab ? Icons.flag_outlined : Icons.emoji_people_outlined, 
               size: 80, 
               color: Colors.grey.withValues(alpha: 0.3)
             ),
             const SizedBox(height: 16),
             Text(
               esGuiaTab 
                 ? 'No has guiado ninguna ruta aún.' 
                 : 'No has participado en ninguna ruta aún.', 
               style: const TextStyle(color: Colors.grey, fontSize: 16)
             ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rutas.length,
      itemBuilder: (context, index) {
        final ruta = rutas[index];
        // En historial, no necesitamos checkear "fuiGuia" por tarjeta porque ya estamos separados,
        // pero mantenemos el boolean por si acaso.
        final bool fuiGuia = (ruta.guiaId == myId);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
               // Navegar al detalle (aunque esté finalizada, se puede ver)
               context.push('/rutas/detalle-ruta', extra: ruta);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      ruta.urlImagenPrincipal,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(color: const Color(0xFF1E1E1E)), // Dark placeholder
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ruta.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              fuiGuia ? Icons.flag : Icons.check_circle, 
                              size: 14, 
                              color: fuiGuia ? Colors.amber[800] : Colors.green
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fuiGuia ? 'Guía' : 'Participante',
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                                color: fuiGuia ? Colors.amber[800] : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                         Text(
                          ruta.fechaEvento != null 
                             ? DateFormat('dd MMM yyyy').format(ruta.fechaEvento!)
                             : 'Fecha desconocida',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

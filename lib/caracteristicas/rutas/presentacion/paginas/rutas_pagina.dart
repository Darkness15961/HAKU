// --- CARACTERISTICAS/RUTAS/PRESENTACION/PAGINAS/RUTAS_PAGINA.DART ---
//
// 1. (BUG CORREGIDO): Se cambió 'ruta.cupos' por 'ruta.cuposTotales'
//    en _buildRouteCard para "acoplarlo" a la nueva "Receta" (ruta.dart).
// 2. (DISEÑO): Se mantiene tu diseño de AppBar nativa.
// 3. (BUG NAVEGACIÓN CORREGIDO): Se corrigió la ruta del botón 'Crear Ruta'
//    de '/crear-ruta' a '/rutas/crear-ruta'.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/ruta.dart';

class RutasPagina extends StatefulWidget {
  const RutasPagina({super.key});

  @override
  State<RutasPagina> createState() => _RutasPaginaState();
}

class _RutasPaginaState extends State<RutasPagina> {
  // Las pestañas disponibles
  final List<String> _pestanasBase = ['Recomendadas', 'Guardadas', 'Creadas por mí'];

  @override
  void initState() {
    super.initState();
    // LÓGICA DE CARGA MÁS SEGURA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vmAuth = context.read<AutenticacionVM>();
        context.read<RutasVM>().cargarDatosIniciales(vmAuth);
      }
    });
  }

  // --- Lógica de Navegación y Recarga ---
  void _irAlDetalleRuta(Ruta ruta) {
    // --- CORRECCIÓN POSIBLE (Revisando tu otra ruta) ---
    // Si esta también falla, debe ser '/rutas/detalle-ruta'
    // Pero 'context.push' con 'extra' suele ser para rutas superiores
    // Lo dejamos como estaba, pero si falla, avísame.
    // **ACTUALIZACIÓN**: Viendo tu app_rutas.dart, esta ruta es '/rutas/detalle-ruta'
    context.push('/rutas/detalle-ruta', extra: ruta);
  }

  Future<void> _handleRefresh() async {
    await context.read<RutasVM>().cargarRutas();
  }


  @override
  Widget build(BuildContext context) {
    final vmRutas = context.watch<RutasVM>();
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // Lógica para determinar qué pestañas mostrar dinámicamente
    final rol = vmAuth.usuarioActual?.rol;
    List<String> pestanasVisibles = ['Recomendadas'];
    if (vmAuth.estaLogueado) {
      pestanasVisibles.add('Guardadas');
      if (rol == 'guia_aprobado' || rol == 'admin') {
        pestanasVisibles.add('Creadas por mí');
      }
    }

    // Manejar estado de carga inicial
    if (vmRutas.estaCargando && !vmRutas.cargaInicialRealizada) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si la pestaña actual ya no es visible (ej. cierra sesión como guía)
    if (!pestanasVisibles.contains(vmRutas.pestanaActual)) {
      // Usamos microtask para evitar error de 'setState' durante el 'build'
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vmRutas.cambiarPestana('Recomendadas');
      });
    }

    // Encontramos el índice de la pestaña actual para el DefaultTabController
    final int initialIndex = pestanasVisibles.indexOf(vmRutas.pestanaActual);


    return DefaultTabController(
      length: pestanasVisibles.length,
      initialIndex: initialIndex < 0 ? 0 : initialIndex, // Seguridad por si el índice es -1
      child: Scaffold(
        // --- AppBar NATIVA ---
        appBar: AppBar(
          backgroundColor: colorPrimario,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Rutas y Tours',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            _buildCrearRutaButton(context, vmAuth, colorPrimario)
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: (index) {
              if (index < pestanasVisibles.length) {
                context.read<RutasVM>().cambiarPestana(pestanasVisibles[index]);
              }
            },
            tabs: pestanasVisibles.map((label) => Tab(text: label)).toList(),
          ),
        ),

        // --- Body Fijo ---
        body: Column(
          children: [
            _buildDifficultyChips(context, vmRutas),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: TabBarView(
                  // Evitamos que el usuario deslice entre pestañas,
                  // forzando el control por el 'onTap' del TabBar
                  physics: const NeverScrollableScrollPhysics(),
                  children: pestanasVisibles.map((pestana) =>
                      _buildContenidoPestana(vmRutas, context)
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE DISEÑO RESTAURADO ---

  Widget _buildCrearRutaButton(
      BuildContext context, AutenticacionVM vmAuth, Color colorPrimario) {
    final bool puedeCrearRutas = vmAuth.estaLogueado &&
        (vmAuth.usuarioActual?.rol == 'guia_aprobado' ||
            vmAuth.usuarioActual?.rol == 'admin');

    if (!puedeCrearRutas) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // --- ¡CORREGIDO! ---
          // La ruta debe ser la ruta completa definida en app_rutas.dart
          context.push('/rutas/crear-ruta');
          // --- FIN DE LA CORRECCIÓN ---
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text('Crear Ruta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12)),
      ),
    );
  }

  Widget _buildDifficultyChips(BuildContext context, RutasVM vmRutas) {
    final difficulties = ['Todos', 'Facil', 'Medio', 'Dificil'];

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
            children: difficulties.map((label) {
              final bool isSelected = vmRutas.dificultadActual == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    context.read<RutasVM>().cambiarDificultad(label);
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                      fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                      width: 1.0,
                    ),
                  ),
                ),
              );
            }).toList()),
      ),
    );
  }

  // --- WIDGET DE CONTENIDO (que usa el filtro de chips) ---
  Widget _buildContenidoPestana(RutasVM vmRutas, BuildContext context) {
    final rutas = vmRutas.rutasFiltradas;

    if (vmRutas.estaCargando && rutas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rutas.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              vmRutas.error ?? 'No hay rutas disponibles para "${vmRutas.pestanaActual}" con dificultad "${vmRutas.dificultadActual}".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: rutas.length,
        itemBuilder: (context, index) {
          final ruta = rutas[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 300),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildRouteCard(context, ruta),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS RESTANTES (Tarjetas) ---
  Widget _buildRouteCard(BuildContext context, Ruta ruta) {
    Color difficultyColor = ruta.dificultad == 'facil'
        ? Colors.green
        : ruta.dificultad == 'dificil'
        ? Colors.red
        : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _irAlDetalleRuta(ruta),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  ruta.urlImagenPrincipal,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                        child: Icon(Icons.terrain,
                            size: 40, color: Colors.grey[400])),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ruta.visible
                          ? Colors.black.withOpacity(0.6)
                          : Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ruta.visible ? 'PÚBLICA' : 'BORRADOR',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ruta.nombre,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(ruta.guiaFotoUrl),
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(ruta.guiaNombre,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(ruta.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                    ],
                  ),
                  const Divider(height: 24),

                  // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- ¡CORREGIDO! ---
                      // Calcula los cupos disponibles y los muestra en formato X / Y
                      Builder(
                          builder: (context) {
                            final int cuposDisponibles = ruta.cuposTotales - ruta.inscritosCount;
                            return _buildInfoIcon(
                                Icons.schedule,
                                '$cuposDisponibles / ${ruta.cuposTotales} Cupos',
                                Colors.grey
                            );
                          }
                      ),
                      // --- FIN DE LA CORRECCIÓN ---
                      _buildInfoIcon(Icons.place,
                          '${ruta.lugaresIncluidos.length} Lugares', Colors.grey),
                      Chip(
                        label: Text(
                          ruta.dificultad.toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: difficultyColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                            color: difficultyColor,
                            fontWeight: FontWeight.bold),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  // --- FIN DE LA CORRECCIÓN ---

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }
}
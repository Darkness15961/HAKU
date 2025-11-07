// --- PIEDRA 7 (RUTAS): EL "MENÚ" DE RUTAS (SOLUCIÓN MEDIADORA) ---
//
// La Vista (Página) ahora es la "mediadora".
// En initState, toma el AuthVM y se lo pasa al RutasVM.

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

  @override
  void initState() {
    super.initState();
    // --- LÓGICA DE CARGA MEDIADORA ---
    Future.microtask(() {
      // 1. Obtenemos los dos VMs (sin escuchar)
      final vmAuth = context.read<AutenticacionVM>();
      final vmRutas = context.read<RutasVM>();

      // 2. Le pasamos el AuthVM al RutasVM para que se "despierte"
      vmRutas.cargarDatosIniciales(vmAuth);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos a los dos ViewModels
    final vmRutas = context.watch<RutasVM>();
    final vmAuth = context.watch<AutenticacionVM>(); // Aún lo necesitamos para los botones
    final colorPrimario = Theme.of(context).colorScheme.primary;

    // --- LÓGICA DE BUILD SIMPLE ---
    // La página solo confía en el estado de RutasVM.
    // RutasVM es responsable de manejar la espera de AuthVM.

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Column(
        children: [
          _buildHeader(context, vmAuth, colorPrimario),
          _buildTabs(context, vmRutas, vmAuth),
          _buildDifficultyChips(context, vmRutas),
          Expanded(
            // Simplemente reaccionamos al estado de RutasVM.
            child: vmRutas.estaCargando
                ? const Center(child: CircularProgressIndicator())
                : vmRutas.error != null
                ? Center(child: Text('Error: ${vmRutas.error}'))
                : vmRutas.rutasFiltradas.isEmpty
                ? const Center(
              child: Text(
                'No se encontraron rutas\ncon esos filtros.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : AnimationLimiter(
              // (El resto del ListView.builder queda igual)
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                itemCount: vmRutas.rutasFiltradas.length,
                itemBuilder: (context, index) {
                  final ruta = vmRutas.rutasFiltradas[index];
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
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Sin cambios) ---
  // (Pega aquí tus _buildHeader, _buildTabs,
  // _buildDifficultyChips, _buildRouteCard, _buildInfoIcon)

  Widget _buildHeader(
      BuildContext context, AutenticacionVM vmAuth, Color colorPrimario) {
    // (Lógica de roles corregida)
    final bool puedeCrearRutas = vmAuth.estaLogueado &&
        (vmAuth.usuarioActual?.rol == 'guia_aprobado' ||
            vmAuth.usuarioActual?.rol == 'admin');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Rutas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (puedeCrearRutas)
            ElevatedButton.icon(
              onPressed: () {
                context.push('/crear-ruta');
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear Nueva Ruta',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs(
      BuildContext context, RutasVM vmRutas, AutenticacionVM vmAuth) {
    // (Lógica de roles corregida)
    final List<String> tabs = ['Recomendadas'];
    final rol = vmAuth.usuarioActual?.rol;
    if (vmAuth.estaLogueado) {
      tabs.add('Guardadas');
      if (rol == 'guia_aprobado' || rol == 'admin') {
        tabs.add('Creadas por mí');
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0))),
        child: Row(
          children: tabs.map((label) {
            // (Usa "pestanaActual" sin ñ)
            final bool isActive = vmRutas.pestanaActual == label;
            return Expanded(
              child: TextButton(
                onPressed: () {
                  // (Usa "cambiarPestana" sin ñ)
                  context.read<RutasVM>().cambiarPestana(label);
                },
                child: Text(label,
                    style: TextStyle(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[600],
                        fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDifficultyChips(BuildContext context, RutasVM vmRutas) {
    // (Sin ñ)
    final difficulties = ['Todos', 'Facil', 'Medio', 'Dificil'];

    return SingleChildScrollView(
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
    );
  }

  Widget _buildRouteCard(BuildContext context, Ruta ruta) {
    // (Sin ñ)
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
        onTap: () {
          context.push('/detalle-ruta', extra: ruta);
        },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoIcon(Icons.schedule,
                          '${ruta.cupos} Cupos', Colors.grey),
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
// --- PIEDRA 5: EL "MENÚ" DE LUGARES POR PROVINCIA ---
//
// Esta es la versión FINAL.
// 1. Conectada al "Mesero" (MVVM).
// 2. Con el diseño de "Chips" (botones) arreglado.
// 3. Con la navegación a "Detalle" ENCENDIDA.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- MVVM: IMPORTACIONES ---
// 1. Importamos el "Mesero" (ViewModel)
import '../vista_modelos/lugares_vm.dart';
// 2. Importamos las "Recetas" (Entidades) que usará esta pantalla
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';

// 1. El "Edificio" (La Pantalla)
//    Recibe el objeto "Provincia" completo
class ProvinciaLugaresPagina extends StatefulWidget {
  final Provincia provincia;

  const ProvinciaLugaresPagina({
    super.key,
    required this.provincia,
  });

  @override
  State<ProvinciaLugaresPagina> createState() => _ProvinciaLugaresPaginaState();
}

class _ProvinciaLugaresPaginaState extends State<ProvinciaLugaresPagina> {
  final TextEditingController _searchCtrl = TextEditingController();

  // --- Lógica de Navegación ---
  void _irAlDetalle(BuildContext context, Lugar lugar) {
    // --- ¡ARREGLO DEFINITIVO! ---
    //
    // 1. "Encendemos" (descomentamos) la navegación real
    //    Ahora que el "GPS" (app_rutas.dart) y el "Edificio"
    //    (detalle_lugar_pagina.dart) existen,
    //    este comando SÍ funcionará.
    context.push('/detalle-lugar', extra: lugar);

    // 2. "Apagamos" (borramos) el aviso temporal
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Navegando a: ${lugar.nombre}')),
    // );
    // --- FIN DEL ARREGLO ---
  }

  // --- Lógica de Carga Inicial ---
  @override
  void initState() {
    super.initState();
    // Le damos la "ORDEN 4" (ver el VM) al "Mesero"
    Future.microtask(() {
      context
          .read<LugaresVM>()
          .cargarLugaresPorProvincia(widget.provincia.id);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    // "Escuchamos" al "Mesero"
    final vm = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provincia.nombre),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.provincia.urlImagen),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
            ),
          ),
        ),
      ),
      // Usamos el "interruptor" de carga del "Mesero"
      body: vm.estaCargandoLugaresDeProvincia
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        // El "Refresh" le da la "ORDEN 4" al "Mesero"
        onRefresh: () => vm.cargarLugaresPorProvincia(widget.provincia.id),
        color: colorPrimario,
        //
        // --- ¡TU DISEÑO DE SLIVERS COMIENZA AQUÍ! ---
        //
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- Barra de Búsqueda y Filtros ---
            SliverToBoxAdapter(
              child: _buildSearchAndFilters(
                context: context,
                vm: vm, // Pasamos el "Mesero"
              ),
            ),

            // --- Cuadrícula de Lugares ---
            SliverPadding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              // Leemos la lista de lugares YA FILTRADA del "Mesero"
              sliver: vm.lugaresFiltradosDeProvincia.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmpty())
                  : SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final lugar = vm.lugaresFiltradosDeProvincia[index];
                    return _buildLugarCard(
                      lugar: lugar,
                      // ¡Este es el botón que "encendemos"!
                      onTap: () => _irAlDetalle(context, lugar),
                    );
                  },
                  childCount: vm.lugaresFiltradosDeProvincia.length,
                ),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78, // Tu ratio de aspecto
                ),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 18)),
          ],
        ),
      ),
    );
  }

  // --- Widget de Búsqueda y Filtros (Conectado al "Mesero") ---
  Widget _buildSearchAndFilters({
    required BuildContext context,
    required LugaresVM vm, // Recibe al "Mesero"
  }) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchCtrl,
            // --- MVVM: ORDEN AL "MESERO" ---
            onChanged: (termino) {
              // Le damos la "ORDEN 5" (ver el VM)
              context.read<LugaresVM>().buscarEnProvincia(termino);
            },
            decoration: InputDecoration(
              hintText: 'Buscar en ${widget.provincia.nombre}...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Chips de categoría (Diseño Corregido)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  // Leemos la lista de categorías del "Mesero"
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vm.categorias.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = vm.categorias[index];
                      // Comparamos con el ID seleccionado en el "Mesero"
                      final selected =
                          cat.id == vm.categoriaSeleccionadaIdProvincia;

                      return ChoiceChip(
                        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                        label: Text(cat.nombre,
                            style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600)),
                        selected: selected,
                        // --- MVVM: ORDEN AL "MESERO" ---
                        onSelected: (_) {
                          // Le damos la "ORDEN 6"
                          context
                              .read<LugaresVM>()
                              .seleccionarCategoriaEnProvincia(cat.id);
                        },
                        // --- ESTILO MEJORADO (Tu Petición) ---
                        backgroundColor: Colors.white,
                        selectedColor: colorPrimario,
                        labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black.withOpacity(0.7)),
                        // La "Circunferencia" (borde)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected
                                ? colorPrimario
                                : Colors.grey[300]!,
                            width: 1.0,
                          ),
                        ),
                        elevation: 0,
                        pressElevation: 0,
                        // --- FIN DE LA MEJORA ---
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget de Tarjeta (Tu diseño, usando la "Receta" Lugar) ---
  Widget _buildLugarCard({
    required Lugar lugar, // Recibe la "Receta" Lugar
    required VoidCallback onTap,
  }) {
    final isFav = false; // TODO: Conectar a AuthVM

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // Llama a _irAlDetalle
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: 'lugar_imagen_${lugar.id}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FadeInImage(
                        placeholder: const NetworkImage(
                            'https://placehold.co/20x20/eeeeee/cccccc'),
                        image: NetworkImage(lugar.urlImagen),
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        imageErrorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.28)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            // --- MVVM: Lógica de Favorito (Pendiente) ---
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${lugar.nombre}" (Pronto)'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: Colors.white24, shape: BoxShape.circle),
                            child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lugar.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lugar.categoria,
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.green, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                lugar.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget de Estado Vacío (Tu diseño) ---
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.location_off, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'No hay lugares para mostrar\ncon esos filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}


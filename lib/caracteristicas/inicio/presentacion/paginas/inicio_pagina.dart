// --- PIEDRA 5: EL "MENÚ" PRINCIPAL (INICIO) ---
//
// Esta es la versión ACTUALIZADA.
// 1. Hemos quitado el botón de "Favorito"
//    de la tarjeta de Provincia (¡Gracias a tu análisis!)
// 2. La navegación a "Detalle" está "encendida".
// 3. ¡CORREGIDO EL IMPORT DE DART:ASYNC!

// --- ¡ARREGLO! ---
//
// El error que encontraste estaba aquí.
// Estaba escrito como 'dart.async' (con punto)
// Lo he corregido a 'dart:async' (con dos puntos)
//
import 'dart:async';
// --- FIN DEL ARREGLO ---

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/lugares_vm.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';

class InicioPagina extends StatefulWidget {
  const InicioPagina({super.key});

  @override
  State<InicioPagina> createState() => _InicioPaginaState();
}

class _InicioPaginaState extends State<InicioPagina> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  // --- Lógica de Navegación ---

  void _irALugaresPorProvincia(Provincia provincia) {
    context.push('/provincia', extra: provincia);
  }

  void _irAlDetalle(Lugar lugar) {
    // Esta navegación SÍ está "encendida" y funciona
    context.push('/detalle-lugar', extra: lugar);
  }

  // --- Lógica de Carga Inicial ---
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84, initialPage: 0);

    Future.microtask(() {
      context.read<LugaresVM>().cargarDatosIniciales();
    });

    _startAutoScroll();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- Lógica de UI (Tu código) ---
  void _startAutoScroll() {
    // Ahora 'Timer' será reconocido
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final populares = context.read<LugaresVM>().lugaresPopulares;

      if (_pageController.hasClients && populares.isNotEmpty) {
        final vm = context.read<LugaresVM>();
        final next = (vm.carouselIndex + 1) % populares.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSearchChanged() {
    context.read<LugaresVM>().buscarEnInicio(_searchCtrl.text);
  }

  Future<void> _handleRefresh() async {
    await context.read<LugaresVM>().cargarDatosIniciales();
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LugaresVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Xplora Cusco'),
          backgroundColor: colorPrimario,
          elevation: 0),
      body: vm.estaCargandoInicio
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SEARCH
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar provincias...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),

              // CARRUSEL
              const Padding(
                padding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('Lugares Populares',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 300, // Tu altura
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: vm.lugaresPopulares.length,
                        onPageChanged: (idx) {
                          vm.setCarouselIndex(idx);
                        },
                        itemBuilder: (context, index) {
                          final item = vm.lugaresPopulares[index];
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 1.0;
                              if (_pageController.hasClients) {
                                final page = _pageController.page ??
                                    _pageController.initialPage
                                        .toDouble();
                                value = (1 -
                                    ((page - index).abs() * 0.12))
                                    .clamp(0.86, 1.0);
                              }
                              return Transform.scale(
                                  scale: value, child: child);
                            },
                            child: _buildCarouselCard(item),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildIndicators(
                      count: vm.lugaresPopulares.length,
                      currentIndex: vm.carouselIndex,
                      context: context,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // CHIPS DE FILTRO
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Provincias',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold))),
                    if (vm.categoriaSeleccionadaIdInicio != '1')
                      TextButton(
                        onPressed: () {
                          vm.seleccionarCategoriaEnInicio('1');
                        },
                        child: const Text('Borrar filtro'),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: vm.categorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final c = vm.categorias[i];
                    final selected =
                        c.id == vm.categoriaSeleccionadaIdInicio;

                    Widget? avatar;
                    if (c.id == '1') {
                      avatar = Icon(
                        Icons.apps,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : Colors.black.withOpacity(0.6),
                      );
                    } else if (c.urlImagen.isNotEmpty) {
                      avatar = CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.transparent,
                        backgroundImage: NetworkImage(c.urlImagen),
                      );
                    }

                    return ChoiceChip(
                      avatar: avatar,
                      labelPadding: avatar == null
                          ? const EdgeInsets.symmetric(horizontal: 12)
                          : const EdgeInsets.only(
                          right: 12, left: 6),
                      label: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(c.nombre)),
                      selected: selected,
                      onSelected: (_) {
                        vm.seleccionarCategoriaEnInicio(c.id);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: colorPrimario,
                      labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.black.withOpacity(0.7),
                          fontWeight: FontWeight.w600),
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
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // GRID DE PROVINCIAS
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8),
                child: vm.provinciasFiltradas.isEmpty
                    ? Center(
                    child: Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                            'No hay provincias que coincidan con tus filtros.')))
                    : AnimationLimiter(
                  child: GridView.builder(
                    physics:
                    const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: vm.provinciasFiltradas.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final p = vm.provinciasFiltradas[index];
                      return AnimationConfiguration
                          .staggeredGrid(
                        position: index,
                        duration:
                        const Duration(milliseconds: 300),
                        columnCount: 2,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: GestureDetector(
                              onTap: () =>
                                  _irALugaresPorProvincia(p),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        14)),
                                clipBehavior: Clip.antiAlias,
                                child: _buildProvinceCard(p),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24), // espacio final
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets de Tarjetas (Tu diseño) ---

  Widget _buildCarouselCard(Lugar item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () => _irAlDetalle(item),
        child: Card(
          elevation: 10,
          clipBehavior: Clip.antiAlias,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                  tag: 'lugar_imagen_${item.id}',
                  child: Image.network(item.urlImagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey[300]))),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter))),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.nombre,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star,
                              color: Colors.amber.shade400, size: 16),
                          const SizedBox(width: 8),
                          Text(item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Text(item.descripcion,
                                  style: const TextStyle(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _irAlDetalle(item),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: const Text('Ver',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProvinceCard(Provincia p) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(p.urlImagen,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.58)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: p.categories.take(2).map((cat) {
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(cat,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
              const Spacer(),
              Text(p.nombre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.place, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text('${p.placesCount} lugares',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  // --- ¡ARREGLO! ---
                  //
                  // Aquí es donde estaba el botón de "favorito"
                  // que no tenía sentido. Lo he borrado.
                  //
                  // --- FIN DEL ARREGLO ---
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicators({
    required int count,
    required int currentIndex,
    required BuildContext context,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(8)),
        );
      }),
    );
  }
}


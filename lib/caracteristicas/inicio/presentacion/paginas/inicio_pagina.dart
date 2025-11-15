// --- PIEDRA 6 (INICIO): EL "MENÚ" DE INICIO (VERSIÓN FUSIONADA Y RESTAURADA) ---
//
// 1. (RESTAURADO): 'Image.network' ahora usa 'item.urlImagen' y 'p.urlImagen'
//    para jalar las imágenes (ahora de Picsum) desde el Mock.
// 2. (ESTABLE): Mantiene toda la lógica de AuthVM, Favoritos y Navegación.
// 3. (¡CORREGIDO!): El Header ahora solo muestra la Campana (si está logueado).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --- MVVM: IMPORTACIONES ---
import '../vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
import '../../dominio/entidades/categoria.dart';

// --- ¡AÑADIDO! ---
// Importamos el VM de Notificaciones para la campana
import '../../../notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';
// --- FIN DE LO AÑADIDO ---

class InicioPagina extends StatefulWidget {
  const InicioPagina({super.key});

  @override
  State<InicioPagina> createState() => _InicioPaginaState();
}

class _InicioPaginaState extends State<InicioPagina> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  // --- Lógica de Navegación (se mantiene) ---
  void _irALugaresPorProvincia(Provincia provincia) {
    context.push('/inicio/provincia', extra: provincia); // (Ruta anidada corregida)
  }

  void _irAlDetalle(Lugar lugar) {
    context.push('/inicio/detalle-lugar', extra: lugar); // (Ruta anidada corregida)
  }

  // --- Lógica de Carga Inicial (se mantiene) ---
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84, initialPage: 0);

    Future.microtask(() {
      final vmAuth = context.read<AutenticacionVM>();
      final vmLugares = context.read<LugaresVM>();
      vmLugares.cargarDatosIniciales(vmAuth);
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

  // --- Lógica de UI (se mantiene) ---
  void _startAutoScroll() {
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

  // --- Refresh (se mantiene) ---
  Future<void> _handleRefresh() async {
    final vmAuth = context.read<AutenticacionVM>();
    await context.read<LugaresVM>().cargarDatosIniciales(vmAuth);
  }

  // --- Construcción del "Menú" (UI) ---
  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final vmAuth = context.watch<AutenticacionVM>(); // <-- vmAuth ya está aquí
    final colorPrimario = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: colorPrimario
      ),
      body: vmLugares.estaCargandoInicio
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, vmAuth), // <-- Le pasamos el vmAuth
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
                height: 300,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: vmLugares.lugaresPopulares.length,
                        onPageChanged: (idx) {
                          vmLugares.setCarouselIndex(idx);
                        },
                        itemBuilder: (context, index) {
                          final item = vmLugares.lugaresPopulares[index];
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
                            child: _buildCarouselCard(item, vmLugares, vmAuth),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildIndicators(
                      count: vmLugares.lugaresPopulares.length,
                      currentIndex: vmLugares.carouselIndex,
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                    if (vmLugares.categoriaSeleccionadaIdInicio != '1')
                      TextButton(
                        onPressed: () {
                          vmLugares.seleccionarCategoriaEnInicio('1');
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
                  // (Tu código de Categorías intacto...)
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: vmLugares.categorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    if (i >= vmLugares.categorias.length) return const SizedBox.shrink();

                    final c = vmLugares.categorias[i];
                    final selected =
                        c.id == vmLugares.categoriaSeleccionadaIdInicio;

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
                        vmLugares.seleccionarCategoriaEnInicio(c.id);
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
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8),
                child: vmLugares.provinciasFiltradas.isEmpty
                    ? Center(
                    child: Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                            'No hay provincias que coincidan con tus filtros.')))
                    : AnimationLimiter(
                  child: GridView.builder(
                    // (Tu código de Provincias intacto...)
                    physics:
                    const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: vmLugares.provinciasFiltradas.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final p = vmLugares.provinciasFiltradas[index];
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets de Tarjetas (Tu diseño) ---

  // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
  Widget _buildHeader(BuildContext context, AutenticacionVM vmAuth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 8.0, 16.0),
      color: Theme.of(context).colorScheme.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Columna de Bienvenida (intacta)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido:',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Text(
                vmAuth.estaLogueado ? vmAuth.usuarioActual!.nombre : 'Visitante',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Fila para los iconos de la derecha
          Row(
            children: [
              // 1. Campana de Notificaciones (SÓLO si está logueado)
              if (vmAuth.estaLogueado) // <-- REGLA DE LOGIN
                Consumer<NotificacionesVM>(
                  builder: (context, vmNotificaciones, child) {
                    final int unreadCount = vmNotificaciones.unreadCount;

                    return IconButton(
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(unreadCount.toString()),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white),
                      ),
                      onPressed: () {
                        context.push('/notificaciones');
                      },
                    );
                  },
                ),

              // 2. Botón de Ajustes (Tornillo ⚙️)
              // (Eliminado según tus instrucciones)

              // 3. Avatar del Perfil (Tu código original)
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: (vmAuth.estaLogueado && vmAuth.usuarioActual!.urlFotoPerfil != null && vmAuth.usuarioActual!.urlFotoPerfil!.isNotEmpty)
                    ? NetworkImage(vmAuth.usuarioActual!.urlFotoPerfil!)
                    : null,
                child: (vmAuth.estaLogueado && (vmAuth.usuarioActual!.urlFotoPerfil == null || vmAuth.usuarioActual!.urlFotoPerfil!.isEmpty))
                    ? Text(
                  vmAuth.usuarioActual!.nombre.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                )
                    : (!vmAuth.estaLogueado ? const Icon(Icons.person_outline, size: 28, color: Colors.white) : null),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
  // --- FIN DE LA CORRECCIÓN ---


  // --- ¡TARJETA DEL CARRUSEL RESTAURADA! ---
  Widget _buildCarouselCard(Lugar item, LugaresVM vmLugares, AutenticacionVM vmAuth) {
    // (Tu código intacto aquí...)
    final bool esFavorito = vmLugares.esLugarFavorito(item.id);

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
              Positioned(
                top: 8.0,
                right: 8.0,
                child: IconButton(
                  icon: Icon(
                    esFavorito ? Icons.favorite : Icons.favorite_border,
                    color: esFavorito ? Colors.red : Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    _onToggleFavorito(context, item.id, vmAuth, vmLugares);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProvinceCard(Provincia p) {
    // (Tu código intacto aquí...)
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
    // (Tu código intacto aquí...)
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

  // --- ¡NUEVOS MÉTODOS DE LÓGICA DE FAVORITOS! ---
  void _onToggleFavorito(BuildContext context, String lugarId, AutenticacionVM vmAuth, LugaresVM vmLugares) {
    if (!_checkAndRedirect(context, 'guardar este lugar')) {
      return;
    }
    vmLugares.toggleLugarFavorito(lugarId);
  }

  bool _checkAndRedirect(BuildContext context, String action) {
    // (Tu código intacto aquí...)
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false; // BLOQUEADO
    }
    return true; // PERMITIDO
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    // (Tu código intacto aquí...)
    final colorPrimario = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Acción Requerida 🔒'),
          content:
          Text('Necesitas iniciar sesión o crear una cuenta para $action.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir Explorando',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimario),
              child: const Text('Iniciar Sesión',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
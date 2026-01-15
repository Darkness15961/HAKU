// --- PIEDRA 6 (INICIO): VERSIÓN TURÍSTICA Y ELEGANTE ---
//
// (...)
// 6. Tipografía más elegante y jerárquica
// 7. (¡DISEÑO ELEGANTE!): Se añadió un fondo de textura de mapa
//    para dar una sensación de "app de turismo" más inmersiva.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../vista_modelos/lugares_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/lugar.dart';
import '../../dominio/entidades/provincia.dart';
// import '../../dominio/entidades/categoria.dart';
import '../../../notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';
import '../widgets/buscador_lugares.dart';

class InicioPagina extends StatefulWidget {
  const InicioPagina({super.key});

  @override
  State<InicioPagina> createState() => _InicioPaginaState();
}

class _InicioPaginaState extends State<InicioPagina> {
  // (Tu código de controladores, initState, dispose, etc. va aquí intacto)
  // ...
  final TextEditingController _searchCtrl = TextEditingController();
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  void _irALugaresPorProvincia(Provincia provincia) {
    context.push('/inicio/provincia', extra: provincia);
  }

  void _irAlDetalle(Lugar lugar) {
    context.push('/inicio/detalle-lugar', extra: lugar);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84, initialPage: 0);

    Future.microtask(() {
      if (!mounted) return;
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

  Future<void> _handleRefresh() async {
    final vmAuth = context.read<AutenticacionVM>();
    await context.read<LugaresVM>().cargarDatosIniciales(vmAuth);
  }
  // ...

  @override
  Widget build(BuildContext context) {
    final vmLugares = context.watch<LugaresVM>();
    final vmAuth = context.watch<AutenticacionVM>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,

      // --- ¡DISEÑO ELEGANTE! ---
      // 1. Envolvemos el 'body' en un Container para el fondo
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Si quieres un color de fondo que no sea blanco:
          // color: Color(0xFFF4F6F8),

          // Tu idea del mapa elegante:
          image: DecorationImage(
            // ¡Asegúrate de que esta ruta sea correcta!
            image: const AssetImage('assets/imagenes/mapa_textura.png'),
            fit: BoxFit.cover,
            // ¡La clave es la opacidad! La hacemos muy sutil
            opacity: 0.04,
          ),
        ),
        // 2. El contenido de la página va como 'child'
        child: vmLugares.estaCargandoInicio
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, vmAuth),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Lugares populares'),
                      const SizedBox(height: 16),
                      _buildCarousel(vmLugares, vmAuth),
                      const SizedBox(height: 40),
                      _buildProvincesSection(vmLugares),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
      // --- FIN DE LA MEJORA ---
    );
  }

  // --- (Todos tus otros widgets _buildHeader, _buildSearchBar, etc.
  // ---  quedan exactamente iguales que en tu archivo original) ---

  // 🎨 HEADER CON GRADIENTE DEL TEMA OFICIAL
  Widget _buildHeader(BuildContext context, AutenticacionVM vmAuth) {
    // (Tu código de _buildHeader intacto)
    // ...
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/header.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 16.0, 28.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido a Cusco',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vmAuth.estaLogueado
                            ? vmAuth.usuarioActual!.seudonimo
                            : 'Explorador',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (vmAuth.estaLogueado)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Consumer<NotificacionesVM>(
                          builder: (context, vmNotificaciones, child) {
                            final int unreadCount =
                                vmNotificaciones.unreadCount;
                            return IconButton(
                              icon: Badge(
                                isLabelVisible: unreadCount > 0,
                                label: Text(unreadCount.toString()),
                                backgroundColor: const Color(0xFFD4AF37),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              onPressed: () {
                                context.push('/notificaciones');
                              },
                            );
                          },
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage:
                            (vmAuth.estaLogueado &&
                                vmAuth.usuarioActual!.urlFotoPerfil != null &&
                                vmAuth.usuarioActual!.urlFotoPerfil!.isNotEmpty)
                            ? NetworkImage(vmAuth.usuarioActual!.urlFotoPerfil!)
                            : null,
                        child:
                            (vmAuth.estaLogueado &&
                                (vmAuth.usuarioActual!.urlFotoPerfil == null ||
                                    vmAuth
                                        .usuarioActual!
                                        .urlFotoPerfil!
                                        .isEmpty))
                            ? Text(
                                vmAuth.usuarioActual!.seudonimo.isNotEmpty
                                    ? vmAuth.usuarioActual!.seudonimo
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : (!vmAuth.estaLogueado
                                  ? const Icon(
                                      Icons.person_outline,
                                      size: 28,
                                      color: Colors.white,
                                    )
                                  : null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔍 SEARCH BAR CON EFECTO GLASSMORPHISM
  Widget _buildSearchBar() {
    // (Tu código de _buildSearchBar intacto)
    // ...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GestureDetector(
        onTap: () {
          showSearch(
            context: context,
            delegate: BuscadorLugares(vmLugares: context.read<LugaresVM>()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AbsorbPointer(
            // Importante para que el GestureDetector maneje el tap
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 16),
              readOnly: true, // Importante
              decoration: InputDecoration(
                hintText: 'Buscar destinos en Cusco...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[600],
                  size: 24,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF00BCD4), // Azul del tema
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📝 TÍTULOS DE SECCIÓN MÁS ELEGANTES
  Widget _buildSectionTitle(String title) {
    // (Tu código de _buildSectionTitle intacto)
    // ...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFD4AF37), // Dorado
                  Color(0xFFB8941F), // Dorado oscuro
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BCD4), // Azul del tema
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 🎠 CARRUSEL DE LUGARES POPULARES
  Widget _buildCarousel(LugaresVM vmLugares, AutenticacionVM vmAuth) {
    // (Tu código de _buildCarousel intacto)
    // ...
    return SizedBox(
      height: 340,
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
                      final page =
                          _pageController.page ??
                          _pageController.initialPage.toDouble();
                      value = (1 - ((page - index).abs() * 0.12)).clamp(
                        0.86,
                        1.0,
                      );
                    }
                    return Transform.scale(scale: value, child: child);
                  },
                  child: _buildCarouselCard(item, vmLugares, vmAuth),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildIndicators(
            count: vmLugares.lugaresPopulares.length,
            currentIndex: vmLugares.carouselIndex,
            context: context,
          ),
        ],
      ),
    );
  }

  // 🎴 CARD DEL CARRUSEL CON DISEÑO PREMIUM
  Widget _buildCarouselCard(
    Lugar item,
    LugaresVM vmLugares,
    AutenticacionVM vmAuth,
  ) {
    // (Tu código de _buildCarouselCard intacto)
    // ...
    final bool esFavorito = vmLugares.esLugarFavorito(item.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      child: GestureDetector(
        onTap: () => _irAlDetalle(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'lugar_imagen_${item.id}',
                  child: Image.network(
                    item.urlImagen,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        esFavorito ? Icons.favorite : Icons.favorite_border,
                        color: esFavorito
                            ? const Color(0xFFFF6B6B)
                            : Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        _onToggleFavorito(context, item.id, vmAuth, vmLugares);
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.descripcion,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _irAlDetalle(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(
                                0xFF00BCD4,
                              ), // Azul del tema
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Explorar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
      ),
    );
  }

  // 🏔️ SECCIÓN DE PROVINCIAS
  Widget _buildProvincesSection(LugaresVM vmLugares) {
    // (Tu código de _buildProvincesSection intacto)
    // ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Provincias',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BCD4),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: vmLugares.todasLasProvincias.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay provincias disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : AnimationLimiter(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: vmLugares.todasLasProvincias.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    itemBuilder: (context, index) {
                      final p = vmLugares.todasLasProvincias[index];
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        columnCount: 2,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: GestureDetector(
                              onTap: () => _irALugaresPorProvincia(p),
                              child: _buildProvinceCard(p),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // 🗺️ CARD DE PROVINCIA CON BADGES MEJORADOS
  Widget _buildProvinceCard(Provincia p) {
    // (Tu código de _buildProvinceCard intacto)
    // ...
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              p.urlImagen,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.3, 0.65, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: p.categories.take(2).map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${p.placesCount} lugares',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📍 INDICADORES DEL CARRUSEL
  Widget _buildIndicators({
    required int count,
    required int currentIndex,
    required BuildContext context,
  }) {
    // (Tu código de _buildIndicators intacto)
    // ...
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: selected ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                  )
                : null,
            color: selected ? null : Colors.grey[350],
            borderRadius: BorderRadius.circular(4),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }

  // 🔒 LÓGICA DE FAVORITOS (INTACTA)
  void _onToggleFavorito(
    BuildContext context,
    String lugarId,
    AutenticacionVM vmAuth,
    LugaresVM vmLugares,
  ) {
    // (Tu código de _onToggleFavorito intacto)
    // ...
    if (!_checkAndRedirect(context, 'guardar este lugar')) {
      return;
    }
    vmLugares.toggleLugarFavorito(lugarId);
  }

  bool _checkAndRedirect(BuildContext context, String action) {
    // (Tu código de _checkAndRedirect intacto)
    // ...
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false;
    }
    return true;
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    // (Tu código de _showLoginRequiredModal intacto)
    // ...
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF00BCD4,
                  ).withValues(alpha: 0.1), // Azul del tema
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF00BCD4), // Azul del tema
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Acción Requerida',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BCD4), // Azul del tema
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Necesitas iniciar sesión o crear una cuenta para $action.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Seguir Explorando',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4), // Azul del tema
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );
  }
}

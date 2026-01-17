import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/ruta.dart';
import '../../../notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';

import '../widgets/ruta_card_elegante.dart';

class RutasPagina extends StatefulWidget {
  const RutasPagina({super.key});

  @override
  State<RutasPagina> createState() => _RutasPaginaState();
}

class _RutasPaginaState extends State<RutasPagina> {
  // Las pestañas disponibles
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vmAuth = context.read<AutenticacionVM>();
        context.read<RutasVM>().cargarDatosIniciales(vmAuth);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (mounted) {
         context.read<RutasVM>().cargarMasRutas();
      }
    }
  }

  void _irAlDetalleRuta(Ruta ruta) {
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

    // Lógica de pestañas dinámicas
    List<String> pestanasVisibles = ['Recomendadas'];
    if (vmAuth.estaLogueado) {
      pestanasVisibles.add('Mis Inscripciones');
      // Mostrar "Creadas por mí" para todos los usuarios logueados
      pestanasVisibles.add('Creadas por mí');
    }

    if (vmRutas.estaCargando && !vmRutas.cargaInicialRealizada) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Corrección de pestaña fantasma
    if (!pestanasVisibles.contains(vmRutas.pestanaActual)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vmRutas.cambiarPestana('Recomendadas');
      });
    }

    final int initialIndex = pestanasVisibles.indexOf(vmRutas.pestanaActual);

    return DefaultTabController(
      length: pestanasVisibles.length,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/header.png'),
                fit: BoxFit.cover,
              ),
            ),
            // Capa de gradiente para mejorar legibilidad
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Rutas y Tours',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            if (vmAuth.estaLogueado)
              Consumer<NotificacionesVM>(
                builder: (context, vmNotificaciones, child) {
                  final int unreadCount = vmNotificaciones.unreadCount;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(unreadCount.toString()),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () => context.push('/notificaciones'),
                  );
                },
              ),
            _buildCrearRutaButton(context, vmAuth, colorPrimario),
          ],
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            onTap: (index) {
              if (index < pestanasVisibles.length) {
                context.read<RutasVM>().cambiarPestana(pestanasVisibles[index]);
              }
            },
            tabs: pestanasVisibles.map((label) => Tab(text: label)).toList(),
          ),
        ),
        body: Column(
          children: [
            // Botón para ingresar código (Solo si está logueado)
            if (vmAuth.estaLogueado) _buildBotonIngresarCodigo(context),

            // Puedes agregar _buildDifficultyChips(context, vmRutas) aquí si lo deseas
            // _buildDifficultyChips(context, vmRutas),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: TabBarView(
                  key: ValueKey(vmRutas.pestanaActual),
                  physics: const NeverScrollableScrollPhysics(),
                  children: pestanasVisibles
                      .map(
                        (pestana) => _buildContenidoPestana(vmRutas, context),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrearRutaButton(
    BuildContext context,
    AutenticacionVM vmAuth,
    Color colorPrimario,
  ) {
    // Si no está logueado, no mostrar nada
    if (!vmAuth.estaLogueado) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // Lógica Diferenciada por Rol
          if (vmAuth.usuarioActual?.rol == 'guia_local' ||
              vmAuth.usuarioActual?.rol == 'admin') {
            // GUÍA: Va directo a crear su oferta de ruta
            context.push('/rutas/crear-ruta');
          } else {
            // TURISTA: Muestra el diálogo para elegir (Con guía vs Sin guía)
            _mostrarDialogoCrearRuta(context, vmAuth);
          }
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: const Text(
          'Crear Ruta',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildBotonIngresarCodigo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: TextButton.icon(
        onPressed: () => _mostrarDialogoIngresarCodigo(context),
        icon: const Icon(Icons.vpn_key),
        label: const Text('Ingresar Código de Ruta Privada'),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoIngresarCodigo(BuildContext context) {
    final controller = TextEditingController();
    bool uniendo = false;
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Unirse a Ruta Privada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa el código que te compartió el organizador:'),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'CÓDIGO',
                  border: const OutlineInputBorder(),
                  errorText: error,
                  filled: true,
                ),
                onChanged: (_) {
                  if (error != null) setState(() => error = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: uniendo
                  ? null
                  : () async {
                      if (controller.text.isEmpty) return;
                      setState(() {
                        uniendo = true;
                        error = null;
                      });

                      try {
                        final vmRutas = context.read<RutasVM>();
                        await vmRutas.unirseARutaPorCodigo(
                          controller.text.trim().toUpperCase(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context); // Cerrar diálogo
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ ¡Te uniste a la ruta!'),
                            ),
                          );
                          // Cambiar a pestaña "Mis Inscripciones"
                          vmRutas.cambiarPestana('Mis Inscripciones');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() {
                            uniendo = false;
                            error = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      }
                    },
              child: uniendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unirse'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCrearRuta(BuildContext context, AutenticacionVM vmAuth) {
    final colorPrimario = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_road, color: colorPrimario, size: 28),
            const SizedBox(width: 10),
            const Text('Crear Ruta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Quieres un guía local para tu ruta?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOpcionDialogo(
              context: context,
              icon: Icons.person,
              color: Colors.blue,
              titulo: 'Sí, quiero un guía',
              descripcion: 'Solicita guías y recibe propuestas',
              onTap: () {
                Navigator.pop(context);
                context.push('/perfil/mis-solicitudes');
              },
            ),
            const SizedBox(height: 15),
            _buildOpcionDialogo(
              context: context,
              icon: Icons.explore,
              color: Colors.green,
              titulo: 'No, crear yo mismo',
              descripcion: 'Crea tu ruta personalizada',
              onTap: () {
                Navigator.pop(context);
                context.push('/rutas/crear-sin-guia');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionDialogo({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildContenidoPestana(RutasVM vmRutas, BuildContext context) {
    final rutas = vmRutas.rutasFiltradas;

    if (vmRutas.estaCargando && rutas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rutas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                vmRutas.error ??
                    'No hay rutas diponibles en "${vmRutas.pestanaActual}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // Importante para RefreshIndicator
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        itemCount: rutas.length + (vmRutas.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == rutas.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final ruta = rutas[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 400),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: RutaCardElegante(
                  ruta: ruta,
                  onTap: () => _irAlDetalleRuta(ruta),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/ruta.dart';
import '../../../notificaciones/presentacion/vista_modelos/notificaciones_vm.dart';

class RutasPagina extends StatefulWidget {
  const RutasPagina({super.key});

  @override
  State<RutasPagina> createState() => _RutasPaginaState();
}

class _RutasPaginaState extends State<RutasPagina> {
  // Las pestañas disponibles (se calculan dinámicamente en build, pero esto es referencia)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vmAuth = context.read<AutenticacionVM>();
        context.read<RutasVM>().cargarDatosIniciales(vmAuth);
      }
    });
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
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Rutas y Tours',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
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
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
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
          child: Text(
            vmRutas.error ??
                'No hay rutas disponibles para "${vmRutas.pestanaActual}".',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
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
              child: FadeInAnimation(child: _buildRouteCard(context, ruta)),
            ),
          );
        },
      ),
    );
  }

  // --- NUEVO DISEÑO DE TARJETA ---
  Widget _buildRouteCard(BuildContext context, Ruta ruta) {
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
                // 1. Imagen de Fondo
                Image.network(
                  ruta.urlImagenPrincipal,
                  height: 180, // Un poco más alto para mejor impacto visual
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),

                // 2. Badge de Estado (Pública/Borrador)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ruta.esPrivada
                          ? Colors.purple
                          : (ruta.visible
                                ? Colors.black.withOpacity(0.6)
                                : Colors.amber.shade700),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ruta.esPrivada
                          ? 'PRIVADA'
                          : (ruta.visible ? 'PÚBLICA' : 'BORRADOR'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // 3. NUEVO CHIP DE CATEGORIA ELEGANTE
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getColorCategoria(ruta.categoria),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: _getColorCategoria(ruta.categoria),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ruta.categoria.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 4. Contenido de Texto
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ruta.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: (ruta.guiaFotoUrl.isNotEmpty)
                            ? NetworkImage(ruta.guiaFotoUrl)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: (ruta.guiaFotoUrl.isEmpty)
                            ? Text(ruta.guiaNombre.substring(0, 1))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ruta.guiaNombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            ruta.guiaRating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Fecha del evento y punto de encuentro
                  if (ruta.fechaEvento != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_formatFecha(ruta.fechaEvento!)} • ${_formatHora(ruta.fechaEvento!)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (ruta.puntoEncuentro != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ruta.puntoEncuentro!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) {
                          final int cuposDisponibles =
                              ruta.cuposTotales - ruta.inscritosCount;
                          return _buildInfoIcon(
                            Icons.people_outline,
                            '$cuposDisponibles cupos disp.',
                            cuposDisponibles > 0
                                ? Colors.grey[700]!
                                : Colors.red,
                          );
                        },
                      ),
                      _buildInfoIcon(
                        Icons.place_outlined,
                        '${ruta.lugaresIncluidos.length} Destinos',
                        Colors.grey[700]!,
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

  String _formatFecha(DateTime fecha) {
    final meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}, ${fecha.year}';
  }

  String _formatHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
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

  // Helper para colores modernos
  Color _getColorCategoria(String categoria) {
    // Normalizamos a minúsculas para comparar seguro
    switch (categoria.toLowerCase()) {
      case 'familiar':
        return const Color(0xFF4CAF50); // Verde (Seguro)
      case 'cultural':
        return const Color(0xFF3F51B5); // Indigo (Serio/Historia)
      case 'aventura':
        return const Color(0xFFFF9800); // Naranja (Energía)
      case '+18':
        return const Color(0xFF212121); // Negro/Gris oscuro (Exclusivo/Noche)
      case 'naturaleza':
        return const Color(0xFF9C27B0); // Morado (Relax/Místico)
      case 'extrema':
        return const Color(0xFFD32F2F); // Rojo Fuerte (Peligro/Acción)
      default:
        // Fallback para datos antiguos ('facil', 'medio', etc.)
        return Colors.grey;
    }
  }
}

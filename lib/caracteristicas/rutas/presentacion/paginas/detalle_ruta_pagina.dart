import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// --- MVVM ---
import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/ruta.dart';

class DetalleRutaPagina extends StatelessWidget {
  final Ruta ruta;

  const DetalleRutaPagina({super.key, required this.ruta});

  // --- Lógica de Seguridad ---
  bool _checkAndRedirect(BuildContext context, String action) {
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      _showLoginRequiredModal(context, action);
      return false;
    }
    return true;
  }

  // --- LÓGICA DE INSCRIPCIÓN ---
  Future<void> _handleRegistration(BuildContext context) async {
    if (!_checkAndRedirect(context, 'inscribirte en esta ruta')) return;

    final vmAuth = context.read<AutenticacionVM>();
    final vmRutas = context.read<RutasVM>();

    if (!vmAuth.tieneNombreCompleto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Debes validar tu nombre completo en Ajustes de Cuenta para inscribirte a rutas',
          ),
          backgroundColor: Colors.orange[900],
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ir a Ajustes',
            textColor: Colors.white,
            onPressed: () {
              context.push('/perfil/ajustes-cuenta');
            },
          ),
        ),
      );
      return;
    }

    final estaInscrito = vmAuth.rutasInscritasIds.contains(ruta.id);

    try {
      if (estaInscrito) {
        await vmRutas.salirDeRuta(ruta.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Has cancelado tu reserva correctamente.')),
          );
        }
      } else {
        await vmRutas.inscribirseEnRuta(ruta.id);
        await vmRutas.cargarRutas();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Inscripción exitosa! Ahora verás la ruta en tu Mapa.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Helper de Colores y Textos ---
  Color _getColorCategoria(String categoria) {
    final categoriaLower = categoria.toLowerCase().trim();
    if (categoriaLower.contains('familiar')) return const Color(0xFF4CAF50);
    if (categoriaLower.contains('cultural')) return const Color(0xFF3F51B5);
    if (categoriaLower.contains('aventura')) return const Color(0xFFFF9800);
    if (categoriaLower.contains('+18')) return const Color(0xFF212121);
    if (categoriaLower.contains('naturaleza')) return const Color(0xFF9C27B0);
    if (categoriaLower.contains('extrema')) return const Color(0xFFD32F2F);
    return Colors.grey;
  }

  IconData _getIconForCategory(String categoria) {
    final categoriaLower = categoria.toLowerCase().trim();
    if (categoriaLower.contains('familiar')) return Icons.family_restroom;
    if (categoriaLower.contains('cultural')) return Icons.museum;
    if (categoriaLower.contains('aventura')) return Icons.hiking;
    if (categoriaLower.contains('+18')) return Icons.local_bar;
    if (categoriaLower.contains('naturaleza')) return Icons.self_improvement;
    if (categoriaLower.contains('extrema')) return Icons.volcano;
    return Icons.info_outline;
  }

  String _getDescripcionCategoria(String categoria) {
    final categoriaLower = categoria.toLowerCase().trim();
    if (categoriaLower.contains('naturaleza')) return 'Experiencias enfocadas en paisajes naturales';
    if (categoriaLower.contains('aventura')) return 'Rutas con actividades dinámicas';
    if (categoriaLower.contains('familiar')) return 'Actividades ideales para todas las edades';
    if (categoriaLower.contains('cultural')) return 'Historia, tradiciones y patrimonio';
    if (categoriaLower.contains('extrema')) return 'Rutas de alta exigencia física';
    return 'Experiencia turística única en Cusco';
  }

  @override
  Widget build(BuildContext context) {
    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    final bool esModoPreview = ruta.id == 'preview_id';
    final bool esFavorita = esModoPreview
        ? false
        : vmAuth.rutasFavoritasIds.contains(ruta.id);
    final bool estaInscrito = esModoPreview
        ? false
        : vmAuth.rutasInscritasIds.contains(ruta.id);

    final String? usuarioIdActual = vmAuth.usuarioActual?.id;
    final bool esPropietario =
        esModoPreview || (vmAuth.estaLogueado && usuarioIdActual == ruta.guiaId);
    final bool esGuia = vmAuth.usuarioActual?.id == ruta.guiaId;

    final int cuposDisponibles = ruta.cuposTotales - ruta.inscritosCount;
    final colorTema = _getColorCategoria(ruta.categoria);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- 1. HEADER CINEMÁTICO ---
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: colorPrimario,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (esPropietario && !esModoPreview)
                IconButton(
                  onPressed: () {
                    context.push('/rutas/crear-ruta', extra: ruta);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              IconButton(
                onPressed: () {
                  if (esModoPreview) {
                    _showPreviewModeWarning(context);
                    return;
                  }
                  if (_checkAndRedirect(context, 'guardar esta ruta')) {
                    context.read<RutasVM>().toggleFavoritoRuta(ruta.id);
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: Icon(
                    esFavorita ? Icons.favorite : Icons.favorite_border,
                    color: esFavorita ? Colors.red : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ruta.urlImagenPrincipal,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colorTema, width: 1),
                              ),
                              child: Text(
                                ruta.categoria.toUpperCase(),
                                style: TextStyle(color: colorTema, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.group, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('$cuposDisponibles cupos', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ruta.nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 26.0, fontWeight: FontWeight.bold, height: 1.1),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            Text(" ${ruta.rating.toStringAsFixed(1)} ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("(${ruta.reviewsCount} reseñas)", style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. DETALLES ---
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _buildInfoCard(context, ruta, cuposDisponibles: cuposDisponibles),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorTema.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorTema.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getIconForCategory(ruta.categoria), color: colorTema, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ruta.categoria.toUpperCase(), style: TextStyle(color: colorTema, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_getDescripcionCategoria(ruta.categoria), style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (ruta.estado != 'convocatoria')
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ruta.estado == 'en_curso' ? Colors.green[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ruta.estado == 'en_curso' ? Colors.green : Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Icon(ruta.estado == 'en_curso' ? Icons.live_tv : Icons.flag, color: ruta.estado == 'en_curso' ? Colors.green : Colors.grey[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ruta.estado == 'en_curso' ? "¡Esta ruta está EN CURSO ahora mismo!" : "Esta ruta ha FINALIZADO",
                          style: TextStyle(color: ruta.estado == 'en_curso' ? Colors.green : Colors.grey[700], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              if (ruta.fechaEvento != null || ruta.puntoEncuentro != null) ...[
                const SizedBox(height: 20),
                _buildSectionTitle('📅 Información del Evento'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.teal[50]!, Colors.teal[100]!]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ruta.fechaEvento != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.teal, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Fecha y Hora', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  Text(_formatFechaCompleta(ruta.fechaEvento!), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(_formatHoraCompleta(ruta.fechaEvento!), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal[700])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (ruta.puntoEncuentro != null) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.orange, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Punto de Encuentro', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  Text(ruta.puntoEncuentro!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              _buildSectionTitle('Organizador'),
              _buildGuideProfile(context, ruta),

              if (ruta.equipamiento.isNotEmpty) ...[
                _buildSectionTitle('🎒 Equipamiento Necesario'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: ruta.equipamiento.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 8), Text(item, style: const TextStyle(fontSize: 15))]),
                    )).toList(),
                  ),
                ),
                const Divider(height: 40),
              ],

              const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
              _buildSectionTitle('Sobre la Experiencia'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(ruta.descripcion, style: const TextStyle(fontSize: 16, height: 1.5)),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Itinerario'),
              _buildTimelineItinerary(ruta.lugaresIncluidos, ruta.lugaresIncluidosIds, colorTema),
              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildSmartBottomBar(context, ruta, esGuia, estaInscrito),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildSmartBottomBar(BuildContext context, Ruta ruta, bool esGuia, bool estaInscrito) {
    final vmRutas = context.read<RutasVM>();

    if (esGuia) {
      if (ruta.estado == 'convocatoria') {
        return _buildBottomBtn("INICIAR AVENTURA", Colors.green, Icons.play_arrow, () { vmRutas.cambiarEstadoRuta(ruta.id, 'en_curso'); });
      } else if (ruta.estado == 'en_curso') {
        return _buildBottomBtn("FINALIZAR RUTA", Colors.red, Icons.stop, () { vmRutas.cambiarEstadoRuta(ruta.id, 'finalizada'); });
      } else {
        return _buildBottomBtn("RUTA FINALIZADA", Colors.grey, Icons.flag, null);
      }
    }

    if (estaInscrito) {
      if (ruta.estado == 'en_curso') {
        return _buildBottomBtn("📍 MARCAR ASISTENCIA", Colors.orange, Icons.location_on, () { vmRutas.marcarAsistencia(ruta.id); });
      } else {
        return _buildRegisterButton(
            context,
            context.read<AutenticacionVM>(),
            ruta,
            estaInscrito: true,
            cuposDisponibles: 10,
            esPropietario: false,
            esModoPreview: false
        );
      }
    }

    if (ruta.estado != 'convocatoria') {
      return _buildBottomBtn("INSCRIPCIONES CERRADAS", Colors.grey, Icons.block, null);
    }

    return _buildRegisterButton(
      context,
      context.read<AutenticacionVM>(),
      ruta,
      estaInscrito: false,
      cuposDisponibles: 10,
      esPropietario: false,
      esModoPreview: false,
    );
  }

  Widget _buildBottomBtn(String text, Color color, IconData icon, VoidCallback? onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Ruta ruta, {required int cuposDisponibles}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.monetization_on_outlined, 'S/ ${ruta.precio.toStringAsFixed(0)}', 'Por persona', Colors.green),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildInfoItem(Icons.calendar_today_outlined, '${ruta.dias} Día(s)', 'Duración', Colors.blue),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildInfoItem(_getIconForCategory(ruta.categoria), ruta.categoria, 'Categoría', _getColorCategoria(ruta.categoria)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildGuideProfile(BuildContext context, Ruta ruta) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: (ruta.guiaFotoUrl.isNotEmpty) ? NetworkImage(ruta.guiaFotoUrl) : null,
          child: (ruta.guiaFotoUrl.isEmpty) ? Text(ruta.guiaNombre.substring(0, 1)) : null,
        ),
        title: Text(ruta.guiaNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: const Text("Organizador de la ruta"),
      ),
    );
  }

  Widget _buildTimelineItinerary(List<String> lugares, List<String> ids, Color colorTema) {
    if (lugares.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text("La ruta aún no tiene paradas definidas.", style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: lugares.length,
        itemBuilder: (context, index) {
          final isLast = index == lugares.length - 1;
          final isFirst = index == 0;
          final String? lugarId = (ids.length > index) ? ids[index] : null;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      Container(width: 2, height: 20, color: isFirst ? Colors.transparent : colorTema.withOpacity(0.3)),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorTema, width: 2),
                          boxShadow: [BoxShadow(color: colorTema.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text('${index + 1}', style: TextStyle(color: colorTema, fontWeight: FontWeight.bold, fontSize: 14))),
                      ),
                      Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : colorTema.withOpacity(0.3))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: InkWell(
                      // --- ¡AQUÍ ESTÁ LA CORRECCIÓN! ---
                      // Ya descomentamos el código y usamos 'lugarId' para navegar
                      onTap: () {
                        if (lugarId != null) {
                          context.push('/lugares/detalle-lugar', extra: lugarId);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(lugares[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          subtitle: Text(isFirst ? '📍 Punto de Partida' : (isLast ? '🏁 Destino Final' : '✨ Parada de visita'), style: TextStyle(color: isFirst || isLast ? colorTema : Colors.grey[500], fontWeight: isFirst || isLast ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRegisterButton(BuildContext context, AutenticacionVM vmAuth, Ruta ruta, {required bool estaInscrito, required int cuposDisponibles, required bool esPropietario, required bool esModoPreview}) {
    final bool isRouteFull = cuposDisponibles <= 0;
    final bool isUserLoggedIn = vmAuth.estaLogueado;

    String buttonText;
    Color buttonColor;
    Color textColor = Colors.white;
    VoidCallback? onPressed;

    if (esPropietario && esModoPreview) {
      buttonText = 'VOLVER A EDITAR';
      buttonColor = Colors.black87;
      onPressed = () => context.pop();
    } else if (esPropietario && !esModoPreview) {
      buttonText = 'GESTIONAR MI RUTA';
      buttonColor = Colors.black87;
      onPressed = () => context.push('/rutas/crear-ruta', extra: ruta);
    } else if (estaInscrito) {
      buttonText = 'CANCELAR RESERVA';
      buttonColor = Colors.white;
      textColor = Colors.red;
      onPressed = () => _handleRegistration(context);
    } else if (isRouteFull) {
      buttonText = 'AGOTADO';
      buttonColor = Colors.grey;
      onPressed = null;
    } else if (!isUserLoggedIn) {
      buttonText = 'INICIA SESIÓN PARA RESERVAR';
      buttonColor = Theme.of(context).colorScheme.primary;
      onPressed = () => _handleRegistration(context);
    } else {
      buttonText = 'RESERVAR AHORA';
      buttonColor = Theme.of(context).colorScheme.primary;
      onPressed = () => _handleRegistration(context);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          side: estaInscrito ? const BorderSide(color: Colors.red) : BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: estaInscrito ? 0 : 4,
        ),
        child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Únete a Haku'),
        content: Text('Necesitas iniciar sesión para $action.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () { Navigator.pop(context); context.push('/login'); }, child: const Text('Iniciar Sesión')),
        ],
      );
    });
  }

  void _showPreviewModeWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estás en modo vista previa.')));
  }

  String _formatFechaCompleta(DateTime fecha) {
    final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${dias[fecha.weekday % 7]}, ${fecha.day} de ${meses[fecha.month - 1]} ${fecha.year}';
  }

  String _formatHoraCompleta(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto hrs';
  }
}
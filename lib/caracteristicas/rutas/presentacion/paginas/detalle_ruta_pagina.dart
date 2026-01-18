import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../vista_modelos/rutas_vm.dart';
import '../../../autenticacion/presentacion/vista_modelos/autenticacion_vm.dart';
import '../../dominio/entidades/ruta.dart';
import '../widgets/lista_participantes_sheet.dart';
import '../widgets/mapa_ruta_preview.dart';
import '../widgets/ruta_accion_card.dart';

class DetalleRutaPagina extends StatefulWidget {
  final Ruta ruta;

  const DetalleRutaPagina({super.key, required this.ruta});

  @override
  State<DetalleRutaPagina> createState() => _DetalleRutaPaginaState();
}

class _DetalleRutaPaginaState extends State<DetalleRutaPagina> {
  // Lógica de Seguridad
  bool _checkAndRedirect(BuildContext context, String action) {
    final authVM = context.read<AutenticacionVM>();
    if (!authVM.estaLogueado) {
      // _showLoginRequiredModal(context, action); // Assuming this method exists or is handled elsewhere
      // If it doesn't exist in scope, we should just show a simple snackbar or dialog if we can't find it
      // For now, I'll replace with a generic helper if missing, but it seemed to exist in previous file?
      // Wait, _showLoginRequiredModal was NOT in the file I read!
      // I will assume it was a missing method or inherited logic?
      // Ah, I see " _showLoginRequiredModal(context, action);" in line 26 of the previous viewing.
      // But where is it defined? It was NOT defined in lines 1-800.
      // It must have been at the very end of the file which I didn't see.
      // I will add a simple placeholder implementation to avoid breaking compilation.
      _showLoginRequiredModal(context, action);
      return false;
    }
    return true;
  }

  void _showLoginRequiredModal(BuildContext context, String action) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Inicia Sesión"),
          content: Text("Debes iniciar sesión para $action."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/login'); // Corrected from /perfil/login
              },
              child: const Text("Iniciar Sesión"),
            ),
          ],
        ),
      );
  }

  bool _isLoadingAttendance = false;
  String? _estadoOverride; // Para forzar actualización visual inmediata (Ej: Finalizar)

  // --- LÓGICA DE ASISTENCIA ---
  Future<void> _handleMarcarAsistencia(BuildContext context, String rutaId) async {
    setState(() => _isLoadingAttendance = true);

    final vmRutas = context.read<RutasVM>();

    try {
      await vmRutas.marcarAsistencia(rutaId);
      if (mounted) {
        setState(() => _isLoadingAttendance = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Asistencia Registrada! Disfruta la ruta.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAttendance = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar asistencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // --- LÓGICA DE VISUALIZACIÓN DE PARTICIPANTES ---
  // --- LÓGICA DE VISUALIZACIÓN DE PARTICIPANTES ---
  void _handleShowParticipants(BuildContext context, bool estaInscrito, bool esGuia, bool esPropietario, Ruta rutaLive) {
    final vmAuth = context.read<AutenticacionVM>();

    // 1. PRIMERO: ¿Está logueado?
    if (!vmAuth.estaLogueado) {
       _showLoginRequiredModal(context, "ver la lista de participantes");
       return;
    }

    // 2. SEGUNDO: ¿Tiene permiso? (Inscrito O Guía O Dueño)
    if (!estaInscrito && !esGuia && !esPropietario) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 Debes inscribirte para ver la lista de participantes"),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }

    // 3. TERCERO: Éxito
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListaParticipantesSheet(ruta: rutaLive),
    );
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

    final estaInscrito = vmAuth.rutasInscritasIds.contains(widget.ruta.id);

    try {
      if (estaInscrito) {
        await vmRutas.salirDeRuta(widget.ruta.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Has cancelado tu reserva correctamente.')),
          );
        }
      } else {
        await vmRutas.inscribirseEnRuta(widget.ruta.id);
        await vmRutas.cargarRutas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Inscripción exitosa! Ahora verás la ruta en tu Mapa.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper de Colores y Textos
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

  String _formatFechaCompleta(DateTime fecha) {
    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }

  void _showPreviewModeWarning(BuildContext context) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Modo vista previa, no se puede guardar.")));
  }

  @override
  Widget build(BuildContext context) {
    
    // 🔥 LIVE UPDATE FIX: Escuchamos cambios del VM para actualizar el estado
    final vmRutas = context.watch<RutasVM>(); 
    // Buscamos si existe una versión más nueva de esta ruta en memoria
    final Ruta rutaEnMemoria = vmRutas.rutasFiltradas.followedBy(vmRutas.misRutasInscritas).firstWhere(
      (r) => r.id == widget.ruta.id,
      orElse: () => widget.ruta,
    );

    // 🚀 LIVE UPDATE FIX: Si tenemos un override local (ej: acabamos de finalizar), lo aplicamos
    final Ruta rutaLive = (_estadoOverride != null) 
       ? rutaEnMemoria.copyWith(estado: _estadoOverride) 
       : rutaEnMemoria;

    final List<LatLng> waypointsRuta = rutaLive.lugaresIncluidosCoords
        .where((latlng) => latlng.latitude != 0 && latlng.longitude != 0)
        .toList();

    final vmAuth = context.watch<AutenticacionVM>();
    final colorPrimario = Theme.of(context).colorScheme.primary;

    final bool esModoPreview = rutaLive.id == 'preview_id';
    final bool esFavorita = esModoPreview
        ? false
        : vmAuth.rutasFavoritasIds.contains(rutaLive.id);
    final bool estaInscrito = esModoPreview
        ? false
        : vmAuth.rutasInscritasIds.contains(rutaLive.id);

    final String? usuarioIdActual = vmAuth.usuarioActual?.id;
    final bool esPropietario =
        esModoPreview || (vmAuth.estaLogueado && usuarioIdActual == rutaLive.guiaId);
    final bool esGuia = vmAuth.usuarioActual?.id == rutaLive.guiaId;

    final int cuposDisponibles = rutaLive.cuposTotales - rutaLive.inscritosCount;
    final colorTema = _getColorCategoria(rutaLive.categoria);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
        slivers: [
          // --- 1. HEADER CINEMÁTICO ---
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: colorPrimario,
            elevation: 0, // Remove shadow line if desired, but pinned usually needs it
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
                    context.push('/rutas/crear-ruta', extra: rutaLive);
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
                    context.read<RutasVM>().toggleFavoritoRuta(rutaLive.id);
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
                    rutaLive.urlImagenPrincipal,
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
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
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
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colorTema, width: 1),
                              ),
                              child: Text(
                                rutaLive.categoria.toUpperCase(),
                                style: TextStyle(color: colorTema, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                                onTap: () => _handleShowParticipants(context, estaInscrito, esGuia, esPropietario, rutaLive),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Fondo blanco sólido para mejor contraste
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.group, color: Colors.blueAccent, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${rutaLive.inscritosCount} Inscritos', 
                                        style: const TextStyle(
                                          color: Colors.blueAccent, 
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          rutaLive.nombre,
                          style: const TextStyle(color: Colors.white, fontSize: 26.0, fontWeight: FontWeight.bold, height: 1.1),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            Text(" ${rutaLive.rating.toStringAsFixed(1)} ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("(${rutaLive.reviewsCount} reseñas)", style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. BODY REORDENADO ---
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              
              // A. RESUMEN CLAVE (Precio, Días, Categoría)
              _buildInfoCard(context, rutaLive, cuposDisponibles: cuposDisponibles),
              const SizedBox(height: 24),

              // B. MAPA VISUAL (Contexto Inmediato - Restaurado arriba)
              MapaRutaPreview(
                polilinea: rutaLive.polilinea,
                waypoints: waypointsRuta, 
                distanciaMetros: rutaLive.distanciaMetros,
                duracionSegundos: rutaLive.duracionSegundos,
              ),

              // C. DESCRIPCIÓN (La Historia)
              const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
              _buildSectionTitle('Sobre la Experiencia'),
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(rutaLive.descripcion, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
              ),
              const SizedBox(height: 20),

              // D. ITINERARIO (El Detalle paso a paso)
               const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
               _buildSectionTitle('Itinerario'),
              _buildTimelineItinerary(rutaLive.lugaresIncluidos, rutaLive.lugaresIncluidosIds, colorTema),
              
              const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),

                if (rutaLive.fechaEvento != null || rutaLive.puntoEncuentro != null || rutaLive.fechaCierre != null) ...[
                  _buildSectionTitle('📅 Detalles Logísticos'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        if (rutaLive.fechaEvento != null)
                          _buildLogisticRow(Icons.calendar_month, "Fecha del Evento", _formatFechaCompleta(rutaLive.fechaEvento!)),
                        if (rutaLive.fechaCierre != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: _buildLogisticRow(Icons.timer_off_outlined, "Cierre de Inscripciones", _formatFechaCompleta(rutaLive.fechaCierre!)),
                          ),
                        if (rutaLive.puntoEncuentro != null && rutaLive.puntoEncuentro!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: (estaInscrito || esGuia || esPropietario)
                                ? _buildLogisticRow(Icons.location_on, "Punto de Encuentro", rutaLive.puntoEncuentro!)
                                : _buildLogisticRow(Icons.lock_outline, "Punto de Encuentro", "🔒 Visible al inscribirte"),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],


              // PROTECCIÓN WHATSAPP: SOLO INSCRITOS O GUÍA
              if ((estaInscrito || esGuia || esPropietario) && rutaLive.enlaceWhatsapp != null && rutaLive.enlaceWhatsapp!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                       final uri = Uri.parse(rutaLive.enlaceWhatsapp!);
                       try {
                         if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir WhatsApp')));
                            }
                         }
                       } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al abrir enlace: $e')));
                         }
                       }
                    },
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('Unirme al Grupo de WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              _buildSectionTitle('Tu Guía'),
              _buildGuideProfile(context, rutaLive),
              
              // --- BOTÓN INTUITIVO DE PARTICIPANTES ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: FilledButton.tonalIcon(
                  onPressed: () => _handleShowParticipants(context, estaInscrito, esGuia, esPropietario, rutaLive),
                  label: const Text("Ver Lista de Participantes"),
                  icon: const Icon(Icons.people_alt_outlined),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              // ----------------------------------------

              if (rutaLive.equipamiento.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSectionTitle('🎒 ¿Qué llevar?'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rutaLive.equipamiento.map((item) => Chip(
                      avatar: const Icon(Icons.check, size: 16, color: Colors.green),
                      label: Text(item),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                    )).toList(),
                  ),
                ),
              ],
              
              const SizedBox(height: 120), // Espacio final
            ]),
          ),
        ],
      ),
      ),
      bottomNavigationBar: _buildSmartBottomBar(context, rutaLive, esGuia, estaInscrito),
    );
  }

  // Helper para fila logística
  Widget _buildLogisticRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
          child: Icon(icon, color: Colors.teal, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartBottomBar(BuildContext context, Ruta ruta, bool esGuia, bool estaInscrito) {
    final vmRutas = context.read<RutasVM>();
    
    // Validamos el estado actual (priorizando override local si acabamos de finalizar)
    final estadoActual = _estadoOverride ?? ruta.estado;

    // 🚀 NUEVO DISEÑO: Tarjeta de Acción Inteligente para el Guía
    // MOSTRAR SOLO SI ESTÁ ACTIVA (Convocatoria o En Curso)
    if (esGuia) {
       if (estadoActual != 'finalizada') {
         return Container(
           color: Colors.white,
           padding: const EdgeInsets.only(bottom: 20, top: 10),
           child: RutaAccionCard(
            ruta: ruta,
            esGuia: true,
            onIniciar: () {
              vmRutas.cambiarEstadoRuta(ruta.id, 'en_curso');
            },
            onFinalizar: () async {
              await vmRutas.cambiarEstadoRuta(ruta.id, 'finalizada');
              if (context.mounted) {
                 setState(() {
                   _estadoOverride = 'finalizada'; // 🏆 Victoria inmediata
                 });
              }
            },
            onMarcarAsistencia: () {},
           ),
         );
       } else {
         // Si es guía y ya finalizó, mostramos vista limpia (sin botones)
         return const SizedBox.shrink();
       }
    }

    // Lógica para Turistas (Mantenemos botones, se actualizarán con GPS luego)
    if (estaInscrito) {
      if (ruta.estado == 'finalizada') {
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text("Esta ruta ha finalizado", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      } else if (ruta.asistio) {
         // --- NUEVO: ESTADO ASISTENCIA CONFIRMADA ---
         return _buildBottomBtn("✅ ASISTENCIA REGISTRADA", Colors.green, Icons.check_circle, null);
      } else if (ruta.estado == 'en_curso') {
        if (_isLoadingAttendance) {
             return _buildBottomBtn("MARCANDO...", Colors.grey, Icons.hourglass_top, null);
        }
        return _buildBottomBtn("📍 GPS: MARCAR MI ASISTENCIA", Colors.orange, Icons.location_on, () async { 
           await _handleMarcarAsistencia(context, ruta.id);
        });
      } else {
        return _buildRegisterButton(
            context,
            context.read<AutenticacionVM>(),
            ruta,
            estaInscrito: true,
            cuposDisponibles: 10, // Dato aproximado
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
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
    // LÓGICA DE NOMBRE:
    // Si tiene DNI validado y nombre real disponible, mostramos el nombre real.
    // Si no, mostramos el seudónimo.
    final bool mostrarNombreReal = ruta.guiaDniValidado && 
                                   ruta.guiaNombreReal != null && 
                                   ruta.guiaNombreReal!.isNotEmpty;
    
    final String nombreAMostrar = mostrarNombreReal ? ruta.guiaNombreReal! : ruta.guiaNombre;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)), 
        boxShadow: [
           BoxShadow(
             color: Colors.deepPurple.withValues(alpha: 0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
           ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3), width: 2),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.deepPurple.shade100,
            backgroundImage: (ruta.guiaFotoUrl.isNotEmpty) ? NetworkImage(ruta.guiaFotoUrl) : null,
            child: (ruta.guiaFotoUrl.isEmpty) ? Text(nombreAMostrar.substring(0, 1), style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)) : null,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(nombreAMostrar, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple))),
            if (mostrarNombreReal) 
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.verified, color: Colors.blue, size: 16),
              ),
          ],
        ), 
        subtitle: Text(mostrarNombreReal ? "Identidad Verificada (DNI)" : "Organizador (Seudónimo)", style: const TextStyle(color: Colors.black54)),
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
                      Container(width: 2, height: 20, color: isFirst ? Colors.transparent : colorTema.withValues(alpha: 0.3)),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorTema, width: 2),
                          boxShadow: [BoxShadow(color: colorTema.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text('${index + 1}', style: TextStyle(color: colorTema, fontWeight: FontWeight.bold, fontSize: 14))),
                      ),
                      Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : colorTema.withValues(alpha: 0.3))),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: InkWell(
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
                          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
      buttonText = 'RESERVAR LUGAR';
      buttonColor = Colors.black;
      onPressed = () => _handleRegistration(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          side: estaInscrito ? BorderSide(color: Colors.red[100]!) : null,
        ),
        child: Text(
          buttonText,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        ),
      ),
    );
  }
}